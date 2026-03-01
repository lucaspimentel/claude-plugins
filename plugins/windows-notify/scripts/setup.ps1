$scheme = "windows-notify.lucasp-claude-plugins"
$regPath = "HKCU:\SOFTWARE\Classes\$scheme"

New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "URL:$scheme"
Set-ItemProperty -Path $regPath -Name "URL Protocol" -Value ""

$focusScript = Join-Path $PSScriptRoot "focus-window.ps1"
New-Item -Path "$regPath\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$regPath\shell\open\command" -Name "(Default)" -Value "`"powershell.exe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$focusScript`""

Write-Host "Registered URI scheme: $scheme"
