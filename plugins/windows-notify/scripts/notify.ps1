param([switch]$Force, [switch]$Register)

$input_json = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8).ReadToEnd()
$data = $input_json | ConvertFrom-Json

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }
    // dwFlags: FLASHW_ALL = 3, FLASHW_TIMERNOFG = 12
    [DllImport("user32.dll")] public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    public static void Flash(IntPtr hwnd) {
        var fi = new FLASHWINFO();
        fi.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(fi);
        fi.hwnd = hwnd;
        fi.dwFlags = 3 | 12; // FLASHW_ALL | FLASHW_TIMERNOFG
        fi.uCount = 3;
        fi.dwTimeout = 0;
        FlashWindowEx(ref fi);
    }
}
"@

# Walk the process tree to find the nearest ancestor with a visible main window
function Get-AncestorHwnd {
    $pid_ = $PID
    while ($pid_ -gt 0) {
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        if (-not $proc) { break }
        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) { return $proc.MainWindowHandle }
        $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId=$pid_" -ErrorAction SilentlyContinue).ParentProcessId
        if (-not $parentId -or $parentId -eq $pid_) { break }
        $pid_ = $parentId
    }
    return [IntPtr]::Zero
}

$fgHwnd = [Win32]::GetForegroundWindow()
$ancestorHwnd = Get-AncestorHwnd

$isForeground = $ancestorHwnd -ne [IntPtr]::Zero -and $ancestorHwnd -eq $fgHwnd

if (-not $Force -and $isForeground) {
    # Terminal is already in the foreground — nothing to do
    exit 0
}

# Flash the taskbar if the terminal is in the background
if ($ancestorHwnd -ne [IntPtr]::Zero -and -not $isForeground) {
    [Win32]::Flash($ancestorHwnd)
}

$aumid = "ClaudeCode.Notifications"
$lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Claude Code Notification Plugin.lnk"

# -Register: create Start Menu shortcut for custom toast branding, then exit
if ($Register) {
    if (Test-Path $lnkPath) { exit 0 }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = "C:\Windows\System32\cmd.exe"
    $icoPath = Join-Path $PSScriptRoot "..\assets\claude.ico"
    $shortcut.IconLocation = (Resolve-Path $icoPath).Path
    $shortcut.Description = "Claude Code Notification Plugin"
    $shortcut.Save()

    $bytes = [System.IO.File]::ReadAllBytes($lnkPath)
    # Set HasLinkTargetIDList flag (byte 20, bit 0) — required for property store
    $bytes[20] = $bytes[20] -bor 0x01
    [System.IO.File]::WriteAllBytes($lnkPath, $bytes)

    # Add AppUserModelID via property store
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

[ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPropertyStore {
    int GetCount(out uint cProps);
    int GetAt(uint iProp, out PROPERTYKEY pkey);
    int GetValue(ref PROPERTYKEY key, out PropVariant pv);
    int SetValue(ref PROPERTYKEY key, ref PropVariant pv);
    int Commit();
}

[StructLayout(LayoutKind.Sequential, Pack = 4)]
public struct PROPERTYKEY {
    public Guid fmtid;
    public uint pid;
}

[StructLayout(LayoutKind.Explicit)]
public struct PropVariant {
    [FieldOffset(0)] public ushort vt;
    [FieldOffset(8)] public IntPtr pszVal;

    public static PropVariant FromString(string val) {
        var pv = new PropVariant();
        pv.vt = 31; // VT_LPWSTR
        pv.pszVal = Marshal.StringToCoTaskMemUni(val);
        return pv;
    }
}

public static class PropertyStoreHelper {
    [DllImport("shell32.dll", SetLastError = true)]
    public static extern int SHGetPropertyStoreFromParsingName(
        [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
        IntPtr pbc, int flags, ref Guid iid, out IPropertyStore ppv);

    public static void SetAppUserModelId(string lnkPath, string aumid) {
        Guid iid = new Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99");
        IPropertyStore store;
        int hr = SHGetPropertyStoreFromParsingName(lnkPath, IntPtr.Zero, 2 /* GPS_READWRITE */, ref iid, out store);
        if (hr != 0) throw new COMException("SHGetPropertyStoreFromParsingName failed", hr);

        var key = new PROPERTYKEY { fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), pid = 5 };
        var val = PropVariant.FromString(aumid);
        store.SetValue(ref key, ref val);
        store.Commit();
        Marshal.FreeCoTaskMem(val.pszVal);
    }
}
"@
    [PropertyStoreHelper]::SetAppUserModelId($lnkPath, $aumid)
    Write-Host "Registered toast shortcut: $lnkPath"
    exit 0
}

$robot   = [char]::ConvertFromUtf32(0x1F916)
$title   = if ($data.title)   { "$robot $($data.title)" } else { "$robot Claude Code" }
$message = if ($data.message) { $data.message } else { "Needs your attention" }

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$xml = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$([System.Security.SecurityElement]::Escape($title))</text>
      <text>$([System.Security.SecurityElement]::Escape($message))</text>
    </binding>
  </visual>
</toast>
"@

$doc = [Windows.Data.Xml.Dom.XmlDocument]::new()
$doc.LoadXml($xml)

$toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($aumid).Show($toast)

exit 0
