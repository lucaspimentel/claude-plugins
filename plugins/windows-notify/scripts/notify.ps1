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

# Get the WindowsTerminal process that is the ancestor of this script
function Get-WTAncestorPid {
    $pid_ = $PID
    while ($pid_ -gt 0) {
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        if (-not $proc) { break }
        if ($proc.ProcessName -eq "WindowsTerminal") { return $proc.Id }
        $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId=$pid_" -ErrorAction SilentlyContinue).ParentProcessId
        if (-not $parentId -or $parentId -eq $pid_) { break }
        $pid_ = $parentId
    }
    return $null
}

$fgHwnd = [Win32]::GetForegroundWindow()
[uint32]$fgPid = 0
[Win32]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null
$fgProc = Get-Process -Id $fgPid -ErrorAction SilentlyContinue

if ($fgProc -and $fgProc.ProcessName -eq "WindowsTerminal") {
    $wtAncestorPid = Get-WTAncestorPid
    if ($wtAncestorPid -and $wtAncestorPid -eq [int]$fgPid) {
        # Same WT window: user may be on a different tab/pane — flash the taskbar
        [Win32]::Flash($fgHwnd)
        exit 0
    }
}

$robot   = [char]::ConvertFromUtf32(0x1F916)
$title   = if ($data.title)   { "$robot $($data.title)" } else { "$robot Claude Code" }
$message = if ($data.message) { $data.message } else { "Needs your attention" }

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$xml = @"
<toast activationType="protocol" launch="windows-notify.lucasp-claude-plugins:">
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
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Microsoft.WindowsTerminal_8wekyb3d8bbwe!App").Show($toast)

exit 0
