$hwndFile = "$env:TEMP\windows-notify-hwnd.txt"
if (-not (Test-Path $hwndFile)) { exit 0 }

$hwndValue = Get-Content $hwndFile -Raw
Remove-Item $hwndFile -Force

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class FocusWin32 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    public const int SW_RESTORE = 9;
}
"@

$hwnd = [IntPtr][long]$hwndValue.Trim()
[FocusWin32]::ShowWindow($hwnd, [FocusWin32]::SW_RESTORE) | Out-Null
[FocusWin32]::SetForegroundWindow($hwnd) | Out-Null
