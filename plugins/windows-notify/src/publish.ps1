#!/usr/bin/env pwsh
$projectDir = Join-Path $PSScriptRoot 'WindowsNotify'
$binDir = Join-Path $PSScriptRoot '..' 'bin'

dotnet publish (Join-Path $projectDir 'WindowsNotify.csproj') -c Release -r win-x64
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$artifactsDir = Join-Path $PSScriptRoot 'artifacts' 'publish' 'WindowsNotify' 'release_win-x64'

if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir | Out-Null }
Copy-Item (Join-Path $artifactsDir '*') -Destination $binDir -Recurse -Force

Write-Host "Published to $binDir"
