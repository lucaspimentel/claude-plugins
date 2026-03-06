param([string]$FilePath)

if (-not $FilePath -or $FilePath -notlike '*.ps1') { exit 0 }

if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
    Write-Output 'PSScriptAnalyzer not installed. Run: Install-Module PSScriptAnalyzer -Scope CurrentUser'
    exit 0
}

$results = Invoke-ScriptAnalyzer -Path $FilePath -ExcludeRule PSAvoidUsingWriteHost,PSUseBOMForUnicodeEncodedFile
if ($results) {
    $results | Format-Table -AutoSize | Out-String
}
