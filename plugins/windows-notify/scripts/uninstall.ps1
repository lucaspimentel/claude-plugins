$scheme = "windows-notify.lucasp-claude-plugins"
$regPath = "HKCU:\SOFTWARE\Classes\$scheme"

if (Test-Path $regPath) {
    Remove-Item -Path $regPath -Recurse -Force
    Write-Host "Removed URI scheme: $scheme"
} else {
    Write-Host "URI scheme not registered: $scheme"
}
