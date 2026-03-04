#!/usr/bin/env pwsh
# Compiles WindowsNotify.cpp using MSVC (cl.exe) from Visual Studio.
# Output: ../bin/WindowsNotify.exe

$ErrorActionPreference = 'Stop'

$srcDir = $PSScriptRoot
$binDir = Join-Path $srcDir '..' 'bin'

# --- Locate Visual Studio via vswhere ---
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    Write-Error "vswhere.exe not found. Install Visual Studio with C++ workload."
    exit 1
}

$vsInstallPath = & $vswhere -products * -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsInstallPath) {
    Write-Error "No Visual Studio installation with C++ tools found."
    exit 1
}

# --- Find MSVC toolchain version ---
$vcToolsVersionFile = Join-Path $vsInstallPath 'VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt'
$vcToolsVersion = (Get-Content $vcToolsVersionFile -Raw).Trim()
$vcToolsDir = Join-Path $vsInstallPath "VC\Tools\MSVC\$vcToolsVersion"

$clExe = Join-Path $vcToolsDir 'bin\Hostx64\x64\cl.exe'
$linkExe = Join-Path $vcToolsDir 'bin\Hostx64\x64\link.exe'

if (-not (Test-Path $clExe)) {
    Write-Error "cl.exe not found at: $clExe"
    exit 1
}

# --- Find Windows SDK ---
$sdkRoot = "${env:ProgramFiles(x86)}\Windows Kits\10"
$sdkVersions = Get-ChildItem (Join-Path $sdkRoot 'Include') -Directory | Sort-Object Name -Descending
$sdkVersion = $sdkVersions[0].Name

$sdkIncludeUcrt  = Join-Path $sdkRoot "Include\$sdkVersion\ucrt"
$sdkIncludeUm    = Join-Path $sdkRoot "Include\$sdkVersion\um"
$sdkIncludeShared = Join-Path $sdkRoot "Include\$sdkVersion\shared"
$sdkIncludeWinrt = Join-Path $sdkRoot "Include\$sdkVersion\winrt"
$sdkIncludeCppWinrt = Join-Path $sdkRoot "Include\$sdkVersion\cppwinrt"
$sdkLibUcrt      = Join-Path $sdkRoot "Lib\$sdkVersion\ucrt\x64"
$sdkLibUm        = Join-Path $sdkRoot "Lib\$sdkVersion\um\x64"

$vcInclude = Join-Path $vcToolsDir 'include'
$vcLib     = Join-Path $vcToolsDir 'lib\x64'

# --- Build ---
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

$sourceFiles = @(
    (Join-Path $srcDir 'WindowsNotify.cpp'),
    (Join-Path $srcDir 'DesktopNotificationManagerCompat.cpp')
)

$objDir = Join-Path $srcDir 'obj'
if (-not (Test-Path $objDir)) {
    New-Item -ItemType Directory -Path $objDir | Out-Null
}

$outExe = Join-Path $binDir 'ClaudeNotify.exe'

$env:INCLUDE = "$vcInclude;$sdkIncludeUcrt;$sdkIncludeUm;$sdkIncludeShared;$sdkIncludeWinrt;$sdkIncludeCppWinrt"
$env:LIB = "$vcLib;$sdkLibUcrt;$sdkLibUm"

Write-Host "Compiling with MSVC $vcToolsVersion, SDK $sdkVersion ..."

$clArgs = @(
    '/nologo',
    '/c',
    '/O1',
    '/GL',
    '/MT',
    '/std:c++17',
    '/EHsc',
    '/DUNICODE',
    '/D_UNICODE',
    '/DWIN32_LEAN_AND_MEAN',
    '/DWINRT_NO_MAKE_DETECTED',
    "/Fo$objDir\",
    $sourceFiles[0],
    $sourceFiles[1]
)

& $clExe @clArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed."
    exit $LASTEXITCODE
}

Write-Host "Linking..."

$linkArgs = @(
    '/nologo',
    '/LTCG',
    '/OPT:REF',
    '/OPT:ICF',
    '/SUBSYSTEM:WINDOWS',
    "/OUT:$outExe",
    (Join-Path $objDir 'WindowsNotify.obj'),
    (Join-Path $objDir 'DesktopNotificationManagerCompat.obj'),
    'user32.lib',
    'ntdll.lib',
    'shell32.lib',
    'ole32.lib',
    'advapi32.lib',
    'shlwapi.lib',
    'runtimeobject.lib'
)

& $linkExe @linkArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Linking failed."
    exit $LASTEXITCODE
}

# --- Report ---
$size = (Get-Item $outExe).Length
$sizeKB = [math]::Round($size / 1024, 1)
Write-Host "Built: $outExe ($sizeKB KB)"
