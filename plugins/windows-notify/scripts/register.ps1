$aumid = "ClaudeCode.Notifications"
$lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Claude Code Notification Plugin.lnk"

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
