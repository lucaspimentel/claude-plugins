// WindowsNotify.cpp — Windows toast notification helper for Claude Code
// Replaces the C# implementation with a lightweight native C++ binary.

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include <windows.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <propvarutil.h>
#include <propkey.h>
#include <shellapi.h>
#include <shlwapi.h>
#include <winternl.h>
#include <wrl.h>
#include <wrl/wrappers/corewrappers.h>
#include <windows.ui.notifications.h>
#include <notificationactivationcallback.h>

#include "DesktopNotificationManagerCompat.h"

#include <string>
#include <cstring>

#pragma comment(lib, "propsys.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "ntdll.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "runtimeobject.lib")

using namespace Microsoft::WRL;
using namespace Microsoft::WRL::Wrappers;
using namespace ABI::Windows::UI::Notifications;
using namespace ABI::Windows::Data::Xml::Dom;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

static const wchar_t* AUMID   = L"ClaudeCode.WindowsNotify";
static const wchar_t* DEFAULT_TITLE   = L"\U0001f916 Claude Code";
static const wchar_t* DEFAULT_MESSAGE = L"Needs your attention";
static const DWORD    ACTIVATION_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes

// {7B3B6F5A-1D2E-4F3A-8B9C-0D1E2F3A4B5C}
static const GUID CLSID_NotificationActivator =
    { 0x7b3b6f5a, 0x1d2e, 0x4f3a, { 0x8b, 0x9c, 0x0d, 0x1e, 0x2f, 0x3a, 0x4b, 0x5c } };

// Win32 event signaled when a toast is clicked
static HANDLE g_activatedEvent = nullptr;

// Ancestor terminal window handle (found at startup, used by activator)
static HWND g_ancestorHwnd = nullptr;

// ---------------------------------------------------------------------------
// NtQueryInformationProcess typedef (ntdll)
// ---------------------------------------------------------------------------

typedef NTSTATUS (NTAPI *NtQueryInformationProcess_t)(
    HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass,
    PVOID ProcessInformation,
    ULONG ProcessInformationLength,
    PULONG ReturnLength);

static NtQueryInformationProcess_t pNtQueryInformationProcess = nullptr;

// ---------------------------------------------------------------------------
// COM Activator — INotificationActivationCallback
// ---------------------------------------------------------------------------

class DECLSPEC_UUID("7B3B6F5A-1D2E-4F3A-8B9C-0D1E2F3A4B5C")
NotificationActivator
    : public RuntimeClass<RuntimeClassFlags<ClassicCom>,
                          INotificationActivationCallback>
{
public:
    HRESULT STDMETHODCALLTYPE Activate(
        LPCWSTR /*appUserModelId*/,
        LPCWSTR /*invokedArgs*/,
        const NOTIFICATION_USER_INPUT_DATA* /*data*/,
        ULONG /*count*/) override
    {
        // Restore and focus the terminal window
        if (g_ancestorHwnd != nullptr)
        {
            if (IsIconic(g_ancestorHwnd))
            {
                ShowWindow(g_ancestorHwnd, SW_RESTORE);
            }
            SetForegroundWindow(g_ancestorHwnd);
        }

        // Signal the main thread to exit
        if (g_activatedEvent != nullptr)
        {
            SetEvent(g_activatedEvent);
        }

        return S_OK;
    }
};

CoCreatableClass(NotificationActivator);

// ---------------------------------------------------------------------------
// Process tree walker — find ancestor terminal window
// ---------------------------------------------------------------------------

static DWORD GetParentProcessId(DWORD pid)
{
    if (pNtQueryInformationProcess == nullptr)
    {
        HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
        if (ntdll == nullptr) return 0;
        pNtQueryInformationProcess = reinterpret_cast<NtQueryInformationProcess_t>(
            GetProcAddress(ntdll, "NtQueryInformationProcess"));
        if (pNtQueryInformationProcess == nullptr) return 0;
    }

    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (hProcess == nullptr) return 0;

    PROCESS_BASIC_INFORMATION pbi = {};
    ULONG returnLength = 0;
    NTSTATUS status = pNtQueryInformationProcess(
        hProcess, ProcessBasicInformation, &pbi, sizeof(pbi), &returnLength);
    CloseHandle(hProcess);

    if (status != 0) return 0;
    return static_cast<DWORD>(reinterpret_cast<ULONG_PTR>(pbi.Reserved3));
}

struct EnumWindowsContext
{
    DWORD targetPid;
    HWND  foundHwnd;
};

static BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam)
{
    auto* ctx = reinterpret_cast<EnumWindowsContext*>(lParam);

    DWORD windowPid = 0;
    GetWindowThreadProcessId(hwnd, &windowPid);

    if (windowPid == ctx->targetPid && IsWindowVisible(hwnd) && GetWindow(hwnd, GW_OWNER) == nullptr)
    {
        ctx->foundHwnd = hwnd;
        return FALSE; // stop enumeration
    }
    return TRUE;
}

static HWND FindWindowForProcess(DWORD pid)
{
    EnumWindowsContext ctx = { pid, nullptr };
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&ctx));
    return ctx.foundHwnd;
}

static HWND FindAncestorWindowHandle()
{
    DWORD pid = GetCurrentProcessId();

    for (int depth = 0; depth < 32; depth++)
    {
        DWORD parentPid = GetParentProcessId(pid);
        if (parentPid == 0 || parentPid == pid) break;

        HWND hwnd = FindWindowForProcess(parentPid);
        if (hwnd != nullptr) return hwnd;

        pid = parentPid;
    }

    return nullptr;
}

// ---------------------------------------------------------------------------
// Taskbar flash
// ---------------------------------------------------------------------------

static void FlashTaskbar(HWND hwnd)
{
    FLASHWINFO fwi = {};
    fwi.cbSize  = sizeof(fwi);
    fwi.hwnd    = hwnd;
    fwi.dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
    fwi.uCount  = 3;
    fwi.dwTimeout = 0;
    FlashWindowEx(&fwi);
}

// ---------------------------------------------------------------------------
// Toast notification
// ---------------------------------------------------------------------------

static HRESULT ShowToast(const wchar_t* title, const wchar_t* message)
{
    // Build toast XML
    std::wstring xml = L"<toast>"
                       L"<visual><binding template=\"ToastGeneric\">"
                       L"<text>";
    xml += title;
    xml += L"</text><text>";
    xml += message;
    xml += L"</text></binding></visual></toast>";

    ComPtr<IXmlDocument> doc;
    HRESULT hr = DesktopNotificationManagerCompat::CreateXmlDocumentFromString(xml.c_str(), &doc);
    if (FAILED(hr)) return hr;

    ComPtr<IToastNotification> toast;
    hr = DesktopNotificationManagerCompat::CreateToastNotification(doc.Get(), &toast);
    if (FAILED(hr)) return hr;

    ComPtr<IToastNotifier> notifier;
    hr = DesktopNotificationManagerCompat::CreateToastNotifier(&notifier);
    if (FAILED(hr)) return hr;

    return notifier->Show(toast.Get());
}

// ---------------------------------------------------------------------------
// Simple JSON string extraction (no dependencies)
// ---------------------------------------------------------------------------

static std::wstring ExtractJsonValue(const wchar_t* json, const wchar_t* key)
{
    // Look for "key":"value" pattern
    std::wstring search = L"\"";
    search += key;
    search += L"\"";

    const wchar_t* pos = wcsstr(json, search.c_str());
    if (pos == nullptr) return L"";

    pos += search.length();

    // Skip whitespace and colon
    while (*pos == L' ' || *pos == L'\t' || *pos == L'\r' || *pos == L'\n') pos++;
    if (*pos != L':') return L"";
    pos++;
    while (*pos == L' ' || *pos == L'\t' || *pos == L'\r' || *pos == L'\n') pos++;

    if (*pos != L'"') return L"";
    pos++; // skip opening quote

    std::wstring result;
    while (*pos != L'\0' && *pos != L'"')
    {
        if (*pos == L'\\' && *(pos + 1) != L'\0')
        {
            pos++; // skip backslash, take next char
        }
        result += *pos;
        pos++;
    }

    return result;
}

// ---------------------------------------------------------------------------
// Read stdin as wide string
// ---------------------------------------------------------------------------

static std::wstring ReadStdinAsWideString()
{
    // Read raw bytes from stdin
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    if (hStdin == INVALID_HANDLE_VALUE) return L"";

    std::string utf8;
    char buf[4096];
    DWORD bytesRead;
    while (ReadFile(hStdin, buf, sizeof(buf), &bytesRead, nullptr) && bytesRead > 0)
    {
        utf8.append(buf, bytesRead);
    }

    if (utf8.empty()) return L"";

    // Convert UTF-8 to wide string
    int wideLen = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()), nullptr, 0);
    if (wideLen <= 0) return L"";

    std::wstring wide(wideLen, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()), &wide[0], wideLen);
    return wide;
}

// ---------------------------------------------------------------------------
// Check if stdin is a pipe/redirect (not console)
// ---------------------------------------------------------------------------

static bool IsInputRedirected()
{
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    if (hStdin == INVALID_HANDLE_VALUE) return false;
    DWORD mode;
    // GetConsoleMode fails if handle is not a console
    return !GetConsoleMode(hStdin, &mode);
}

// ---------------------------------------------------------------------------
// Start Menu shortcut (required for toast notifications from unpackaged apps)
// ---------------------------------------------------------------------------

// Returns S_OK if shortcut already existed, S_FALSE if freshly created.
static HRESULT CreateStartMenuShortcut()
{
    // Get the Start Menu Programs path
    wchar_t* startMenuPath = nullptr;
    HRESULT hr = SHGetKnownFolderPath(FOLDERID_Programs, 0, nullptr, &startMenuPath);
    if (FAILED(hr)) return hr;

    std::wstring shortcutPath = startMenuPath;
    CoTaskMemFree(startMenuPath);
    shortcutPath += L"\\Claude Notification Plugin.lnk";

    // Check if shortcut already exists
    if (GetFileAttributesW(shortcutPath.c_str()) != INVALID_FILE_ATTRIBUTES)
    {
        return S_OK; // already exists
    }

    // Get current exe path
    wchar_t exePath[MAX_PATH];
    if (GetModuleFileNameW(nullptr, exePath, MAX_PATH) == 0)
        return HRESULT_FROM_WIN32(GetLastError());

    // Create ShellLink
    ComPtr<IShellLinkW> shellLink;
    hr = CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                          IID_PPV_ARGS(&shellLink));
    if (FAILED(hr)) return hr;

    hr = shellLink->SetPath(exePath);
    if (FAILED(hr)) return hr;

    // Set the AUMID via property store
    ComPtr<IPropertyStore> propStore;
    hr = shellLink.As(&propStore);
    if (FAILED(hr)) return hr;

    PROPVARIANT pv;
    hr = InitPropVariantFromString(AUMID, &pv);
    if (FAILED(hr)) return hr;

    hr = propStore->SetValue(PKEY_AppUserModel_ID, pv);
    PropVariantClear(&pv);
    if (FAILED(hr)) return hr;

    // Also set the toast activator CLSID
    PROPVARIANT pvClsid;
    wchar_t clsidStr[40];
    StringFromGUID2(CLSID_NotificationActivator, clsidStr, ARRAYSIZE(clsidStr));
    hr = InitPropVariantFromString(clsidStr, &pvClsid);
    if (FAILED(hr)) return hr;

    hr = propStore->SetValue(PKEY_AppUserModel_ToastActivatorCLSID, pvClsid);
    PropVariantClear(&pvClsid);
    if (FAILED(hr)) return hr;

    hr = propStore->Commit();
    if (FAILED(hr)) return hr;

    // Save the shortcut
    ComPtr<IPersistFile> persistFile;
    hr = shellLink.As(&persistFile);
    if (FAILED(hr)) return hr;

    hr = persistFile->Save(shortcutPath.c_str(), TRUE);
    if (FAILED(hr)) return hr;

    return S_FALSE; // freshly created
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

int WINAPI wWinMain(HINSTANCE /*hInstance*/, HINSTANCE /*hPrevInstance*/,
                    LPWSTR lpCmdLine, int /*nCmdShow*/)
{
    // Check if this process was re-launched by COM for toast activation
    if (lpCmdLine != nullptr && wcsstr(lpCmdLine, TOAST_ACTIVATED_LAUNCH_ARG) != nullptr)
    {
        return 0;
    }

    // Initialize COM (STA for toast notifications)
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hr)) return 1;

    // Parse CLI arguments
    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);

    std::wstring title;
    std::wstring message;
    bool force = false;
    bool registerOnly = false;

    if (argv != nullptr)
    {
        for (int i = 1; i < argc; i++)
        {
            if (_wcsicmp(argv[i], L"--register") == 0)
            {
                registerOnly = true;
            }
            else if (_wcsicmp(argv[i], L"--force") == 0 || _wcsicmp(argv[i], L"-f") == 0)
            {
                force = true;
            }
            else if ((_wcsicmp(argv[i], L"--title") == 0 || _wcsicmp(argv[i], L"-t") == 0) && i + 1 < argc)
            {
                title = argv[++i];
            }
            else if ((_wcsicmp(argv[i], L"--message") == 0 || _wcsicmp(argv[i], L"-m") == 0) && i + 1 < argc)
            {
                message = argv[++i];
            }
        }
        LocalFree(argv);
    }

    // --register: create Start Menu shortcut and COM server registry entry, then exit
    if (registerOnly)
    {
        CreateStartMenuShortcut();
        DesktopNotificationManagerCompat::RegisterAumidAndComServer(AUMID, CLSID_NotificationActivator);
        CoUninitialize();
        return 0;
    }

    // Register AUMID and COM server
    hr = DesktopNotificationManagerCompat::RegisterAumidAndComServer(AUMID, CLSID_NotificationActivator);
    if (FAILED(hr)) { CoUninitialize(); return 1; }

    // Register activator
    hr = DesktopNotificationManagerCompat::RegisterActivator();
    if (FAILED(hr)) { CoUninitialize(); return 1; }

    // If title/message not fully provided via CLI, try reading JSON from stdin
    if ((title.empty() || message.empty()) && IsInputRedirected())
    {
        std::wstring stdinData = ReadStdinAsWideString();
        if (!stdinData.empty())
        {
            if (title.empty())
            {
                title = ExtractJsonValue(stdinData.c_str(), L"title");
            }
            if (message.empty())
            {
                message = ExtractJsonValue(stdinData.c_str(), L"message");
            }
        }
    }

    // Apply defaults
    if (title.empty())
    {
        title = DEFAULT_TITLE;
    }
    else
    {
        title = std::wstring(L"\U0001f916 ") + title;
    }

    if (message.empty())
    {
        message = DEFAULT_MESSAGE;
    }

    // Find the terminal window handle
    g_ancestorHwnd = FindAncestorWindowHandle();
    HWND fgHwnd = GetForegroundWindow();
    bool terminalIsForeground = !force && g_ancestorHwnd != nullptr && g_ancestorHwnd == fgHwnd;

    // If terminal is in the foreground, flash the taskbar
    if (terminalIsForeground)
    {
        FlashTaskbar(g_ancestorHwnd);
    }

    // Create activation event
    g_activatedEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);

    // Show the toast
    hr = ShowToast(title.c_str(), message.c_str());
    if (FAILED(hr))
    {
        if (g_activatedEvent) CloseHandle(g_activatedEvent);
        CoUninitialize();
        return 1;
    }

    if (terminalIsForeground)
    {
        // Terminal is focused — no need to wait for activation
        if (g_activatedEvent) CloseHandle(g_activatedEvent);
        CoUninitialize();
        return 0;
    }

    // Wait for toast click or timeout
    if (g_activatedEvent != nullptr)
    {
        // Pump COM messages while waiting so the activator callback can fire
        DWORD startTick = GetTickCount();
        while (true)
        {
            DWORD elapsed = GetTickCount() - startTick;
            if (elapsed >= ACTIVATION_TIMEOUT_MS) break;

            DWORD waitResult = MsgWaitForMultipleObjectsEx(
                1, &g_activatedEvent,
                ACTIVATION_TIMEOUT_MS - elapsed,
                QS_ALLINPUT, 0);

            if (waitResult == WAIT_OBJECT_0)
            {
                // Event signaled — toast was clicked
                break;
            }
            else if (waitResult == WAIT_OBJECT_0 + 1)
            {
                // Message available — pump it
                MSG msg;
                while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE))
                {
                    TranslateMessage(&msg);
                    DispatchMessageW(&msg);
                }
            }
            else
            {
                // Timeout or error
                break;
            }
        }

        CloseHandle(g_activatedEvent);
    }

    CoUninitialize();
    return 0;
}
