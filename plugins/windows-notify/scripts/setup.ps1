$scheme = "windows-notify.lucasp-claude-plugins"
$regPath = "HKCU:\SOFTWARE\Classes\$scheme"

New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "URL:$scheme"
Set-ItemProperty -Path $regPath -Name "URL Protocol" -Value ""

New-Item -Path "$regPath\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$regPath\shell\open\command" -Name "(Default)" -Value "`"wt.exe`" -w 0 focus-tab"

Write-Host "Registered URI scheme: $scheme"
