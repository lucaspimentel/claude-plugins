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

if ($ancestorHwnd -ne [IntPtr]::Zero -and $ancestorHwnd -eq $fgHwnd) {
    # Terminal is already in the foreground — flash the taskbar instead
    [Win32]::Flash($fgHwnd)
    exit 0
}

if ($ancestorHwnd -ne [IntPtr]::Zero) {
    [long]$ancestorHwnd | Set-Content -Path "$env:TEMP\windows-notify-hwnd.txt"
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
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe").Show($toast)

exit 0
