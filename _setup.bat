@echo off
setlocal EnableExtensions DisableDelayedExpansion
REM --- Batch + PowerShell in one file. The batch part copies the PowerShell code below the
REM --- #__POWERSHELL__ line to a temp .ps1, runs it with the dropped files, then deletes it.
set "SELF=%~f0"
set "SCRIPT_DIR=%~dp0"
set "PS1=%TEMP%\%~n0_%RANDOM%%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = [IO.File]::ReadAllText($env:SELF); $i = $s.IndexOf([char]10 + '#__POWERSHELL__'); if ($i -lt 0) { exit 1 }; [IO.File]::WriteAllText($env:PS1, $s.Substring($s.IndexOf([char]10, $i + 1) + 1), (New-Object Text.UTF8Encoding $true))"
if errorlevel 1 (
    echo [ERROR] Could not prepare the PowerShell part of this script.
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%ERRORLEVEL%"
del "%PS1%" 2>nul
echo.
pause
exit /b %RC%
#__POWERSHELL__
$ErrorActionPreference = 'Stop'

# Set by the batch part of _setup.bat; this code runs from a temp copy, so $PSScriptRoot is TEMP.
$Root = $env:SCRIPT_DIR.TrimEnd('\')
$DisabledDir = Join-Path $Root 'disabled'

# Every tool in the set (one <Name>.bat each).
$Tools = @(
    @{ Name = 'concat-audio';   Desc = 'Join audio files into one MP3';          Deps = @('ffmpeg') }
    @{ Name = 'dir-to-7z';      Desc = 'Compress folders to .7z';                Deps = @('7zip') }
    @{ Name = 'dir-to-zip';     Desc = 'Compress folders to .zip';               Deps = @() }
    @{ Name = 'file-dedup';     Desc = 'Find duplicate files';                   Deps = @() }
    @{ Name = 'flush-dns';      Desc = 'Flush the DNS cache (admin)';            Deps = @() }
    @{ Name = 'hdr-to-sdr';     Desc = 'Tone-map HDR video to SDR ProRes';       Deps = @('ffmpeg') }
    @{ Name = 'img-4k-bg';      Desc = '4K landscape with blurred background';   Deps = @('magick') }
    @{ Name = 'img-optim';      Desc = 'Resize + compress images under 200KB';   Deps = @('magick') }
    @{ Name = 'img-strip';      Desc = 'Strip metadata, randomize filename';     Deps = @('magick') }
    @{ Name = 'pdf-unlock';     Desc = 'Remove the password from PDFs';          Deps = @('qpdf') }
    @{ Name = 'remove-bg';      Desc = 'AI background removal';                  Deps = @('tbg') }
    @{ Name = 'restart-winnat'; Desc = 'Restart the WinNAT service (admin)';     Deps = @() }
    @{ Name = 'to-64x64';       Desc = 'Conform images to 64x64 pixels';         Deps = @('ffmpeg') }
    @{ Name = 'to-bw';          Desc = 'Convert images to grayscale';            Deps = @('magick') }
    @{ Name = 'to-favicon';     Desc = 'Make 64x64 .ico favicons';               Deps = @('magick') }
    @{ Name = 'to-jpg';         Desc = 'Convert images to JPG';                  Deps = @('magick') }
    @{ Name = 'to-md';          Desc = 'Convert documents to Markdown';          Deps = @('pandoc') }
    @{ Name = 'to-mp3';         Desc = 'Extract audio as MP3';                   Deps = @('ffmpeg') }
    @{ Name = 'to-mp4';         Desc = 'Convert video to MP4 (H.264)';           Deps = @('ffmpeg') }
    @{ Name = 'to-png';         Desc = 'Convert images to PNG';                  Deps = @('magick') }
    @{ Name = 'to-webp';        Desc = 'Convert images to WebP';                 Deps = @('ffmpeg') }
    @{ Name = 'to-webp-sm';     Desc = 'Small WebP, max 700px wide';             Deps = @('ffmpeg') }
    @{ Name = 'trim-png';       Desc = 'Trim empty borders from PNGs';           Deps = @('magick') }
    @{ Name = 'vid-compress';   Desc = 'Compress video to ~60MB';                Deps = @('ffmpeg') }
    @{ Name = 'vid-to-gif';     Desc = 'Convert video to GIF';                   Deps = @('ffmpeg') }
)

# Re-reads PATH from the registry so programs installed during this run are found.
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

function Test-Cmd([string]$Name) {
    [bool](Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue)
}

function Find-ProgramFile([string]$Pattern) {
    @("$env:ProgramFiles\$Pattern", "${env:ProgramFiles(x86)}\$Pattern") |
        ForEach-Object { Get-ChildItem -Path $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
}

# Returns the command (as an array) that runs a real Python 3, skipping the Microsoft Store stub.
function Get-Python {
    if (Test-Cmd 'py') { return @('py', '-3') }
    $py = Get-Command python -CommandType Application -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -notlike '*\WindowsApps\*' } | Select-Object -First 1
    if ($py) { return @($py.Source) }
    return $null
}

$Deps = [ordered]@{
    ffmpeg = @{ Label = 'FFmpeg';      Id = 'Gyan.FFmpeg';             Test = { (Test-Cmd 'ffmpeg') -and (Test-Cmd 'ffprobe') } }
    magick = @{ Label = 'ImageMagick'; Id = 'ImageMagick.ImageMagick'; Test = { Test-Cmd 'magick' } }
    pandoc = @{ Label = 'Pandoc';      Id = 'JohnMacFarlane.Pandoc';   Test = { Test-Cmd 'pandoc' } }
    '7zip' = @{ Label = '7-Zip';       Id = '7zip.7zip';               Test = { (Test-Cmd '7z') -or [bool](Find-ProgramFile '7-Zip\7z.exe') } }
    qpdf   = @{ Label = 'qpdf';        Id = 'QPDF.QPDF';               Test = { (Test-Cmd 'qpdf') -or [bool](Find-ProgramFile 'qpdf*\bin\qpdf.exe') } }
    tbg    = @{ Label = 'Python + transparent-background (big: ~2-3 GB incl. PyTorch)'; Id = $null
                Test = { (Test-Cmd 'transparent-background') -or [bool](Get-RemoveBgVenv) } }
}

# remove-bg.bat has a VENV setting: a folder whose Scripts\ holds transparent-background.exe.
function Get-RemoveBgVenv {
    $bat = Get-ToolFiles 'remove-bg' | Where-Object { $_.Extension -eq '.bat' } | Select-Object -First 1
    if (-not $bat) { return $null }
    $line = Select-String -LiteralPath $bat.FullName -Pattern '^set "VENV=(.+)"$' | Select-Object -First 1
    if (-not $line) { return $null }
    $venv = $line.Matches[0].Groups[1].Value
    if (Test-Path -LiteralPath (Join-Path $venv 'Scripts\transparent-background.exe')) { return $venv }
    return $null
}

function Get-ToolFiles([string]$Name) {
    foreach ($dir in $Root, $DisabledDir) {
        $p = Join-Path $dir ($Name + '.bat')
        if (Test-Path -LiteralPath $p -PathType Leaf) { Get-Item -LiteralPath $p }
    }
}

function Test-ToolEnabled([string]$Name) {
    Test-Path -LiteralPath (Join-Path $Root ($Name + '.bat')) -PathType Leaf
}

function Move-Tool([string]$Name, [bool]$Enable) {
    $dest = if ($Enable) { $Root } else { $DisabledDir }
    if (-not $Enable -and -not (Test-Path -LiteralPath $DisabledDir)) {
        New-Item -ItemType Directory -Path $DisabledDir | Out-Null
    }
    foreach ($file in (Get-ToolFiles $Name)) {
        if ($file.DirectoryName -ne $dest.TrimEnd('\')) {
            Move-Item -LiteralPath $file.FullName -Destination (Join-Path $dest $file.Name) -Force
        }
    }
}

function Install-WingetPackage([string]$Id, [string[]]$Extra = @()) {
    $wingetArgs = @('install', '--id', $Id, '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements') + $Extra
    & winget @wingetArgs | Out-Host
    Update-SessionPath
}

function Install-TransparentBackground {
    $python = Get-Python
    if (-not $python) {
        Write-Host '  Installing Python 3.12...'
        Install-WingetPackage 'Python.Python.3.12' @('--override', '/quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_pip=1')
        $python = Get-Python
        if (-not $python) {
            $exe = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
            if (Test-Path -LiteralPath $exe) { $python = @($exe) }
        }
        if (-not $python) { throw 'Python was not found after installing it.' }
    }
    $pyExe = $python[0]
    $pyArgs = @($python | Select-Object -Skip 1)

    Write-Host '  Installing transparent-background with pip (this downloads PyTorch, be patient)...'
    & $pyExe @pyArgs -m pip install --upgrade transparent-background | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "pip exited with code $LASTEXITCODE" }
    Update-SessionPath

    # If pip's Scripts folder isn't on PATH, point remove-bg.bat at it directly.
    if (-not (Test-Cmd 'transparent-background')) {
        $code = "import sysconfig, os; print(sysconfig.get_path('scripts')); print(sysconfig.get_path('scripts', os.name + '_user'))"
        $dirs = & $pyExe @pyArgs -c $code
        $scripts = $dirs | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'transparent-background.exe')) } | Select-Object -First 1
        if (-not $scripts) { throw 'transparent-background.exe was not found after pip install.' }
        $venv = Split-Path $scripts -Parent
        $bat = Get-ToolFiles 'remove-bg' | Where-Object { $_.Extension -eq '.bat' } | Select-Object -First 1
        if ($bat) {
            $content = [IO.File]::ReadAllText($bat.FullName)
            $content = [regex]::Replace($content, '(?m)^set "VENV=[^"\r\n]*"', ('set "VENV=' + $venv.Replace('$', '$$') + '"'))
            # cmd reads .bat files in the OEM code page, so a non-English user name must be saved in it.
            $oem = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
            [IO.File]::WriteAllText($bat.FullName, $content, $oem)
            Write-Host ("  Pointed remove-bg at {0}" -f $venv)
        }
    }
}

# Tells Explorer the PATH changed, so scripts double-clicked from now on see new programs.
function Send-EnvironmentChange {
    try {
        if (-not ('Win32.EnvBroadcast' -as [type])) {
            Add-Type -Namespace Win32 -Name EnvBroadcast -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
        }
        $result = [UIntPtr]::Zero
        [void][Win32.EnvBroadcast]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
    } catch { }
}

# ---------------------------------------------------------------- menu

# Only tools whose files actually exist in this copy of the set are offered.
$Tools = @($Tools | Where-Object { Get-ToolFiles $_.Name })
if ($Tools.Count -eq 0) {
    Write-Host '[ERROR] No tools found next to this setup script.' -ForegroundColor Red
    exit 1
}

# A tool is enabled when its .bat sits in the main folder, so a fresh copy starts all on
# and later runs show whatever was chosen last time.
$enabled = @{}
foreach ($t in $Tools) { $enabled[$t.Name] = Test-ToolEnabled $t.Name }

Update-SessionPath
$message = ''
while ($true) {
    Clear-Host
    Write-Host '========================================================================'
    Write-Host ' Desktop scripts setup'
    Write-Host '========================================================================'
    Write-Host ''
    for ($i = 0; $i -lt $Tools.Count; $i++) {
        $t = $Tools[$i]
        $mark = if ($enabled[$t.Name]) { '[x]' } else { '[ ]' }
        $needs = ($t.Deps | ForEach-Object { $Deps[$_].Label -replace ' \(.*$', '' }) -join ', '
        $color = if ($enabled[$t.Name]) { 'White' } else { 'DarkGray' }
        Write-Host ("  {0} {1,2}  {2,-15} {3,-39} {4}" -f $mark, ($i + 1), $t.Name, $t.Desc, $needs) -ForegroundColor $color
    }
    Write-Host ''
    Write-Host '  Type numbers to toggle (e.g. "3 7 12" or "4-9"), A = all on, N = all off,'
    Write-Host '  Enter = continue, Q = quit.'
    if ($message) { Write-Host ''; Write-Host ("  {0}" -f $message) -ForegroundColor Yellow; $message = '' }
    Write-Host ''
    $answer = (Read-Host '  Choice').Trim()

    if ($answer -eq '') { break }
    if ($answer -match '^[qQ]$') { Write-Host 'Nothing changed.'; exit 0 }
    if ($answer -match '^[aA]$') { foreach ($t in $Tools) { $enabled[$t.Name] = $true }; continue }
    if ($answer -match '^[nN]$') { foreach ($t in $Tools) { $enabled[$t.Name] = $false }; continue }

    $bad = @()
    foreach ($token in ($answer -split '[\s,]+' | Where-Object { $_ })) {
        $range = $null
        if ($token -match '^(\d+)-(\d+)$') { $range = [int]$Matches[1]..[int]$Matches[2] }
        elseif ($token -match '^\d+$') { $range = @([int]$token) }
        if (-not $range) { $bad += $token; continue }
        foreach ($n in $range) {
            if ($n -ge 1 -and $n -le $Tools.Count) {
                $name = $Tools[$n - 1].Name
                $enabled[$name] = -not $enabled[$name]
            } else { $bad += "$n" }
        }
    }
    if ($bad) { $message = 'Ignored: ' + ($bad -join ' ') }
}

# ---------------------------------------------------------------- plan

$needed = @($Tools | Where-Object { $enabled[$_.Name] } | ForEach-Object { $_.Deps } | Select-Object -Unique)
$missing = @($Deps.Keys | Where-Object { $needed -contains $_ } | Where-Object { -not (& $Deps[$_].Test) })
$present = @($Deps.Keys | Where-Object { $needed -contains $_ } | Where-Object { $missing -notcontains $_ })
$onCount = @($Tools | Where-Object { $enabled[$_.Name] }).Count

Write-Host ''
Write-Host ("  Enabled: {0} of {1} tools (disabled tools are moved to the 'disabled' folder)." -f $onCount, $Tools.Count)
if ($present) { Write-Host ('  Already installed: ' + (($present | ForEach-Object { $Deps[$_].Label -replace ' \(.*$', '' }) -join ', ')) }
if ($missing) { Write-Host ('  Will install:      ' + (($missing | ForEach-Object { $Deps[$_].Label }) -join ', ')) -ForegroundColor Cyan }
else { Write-Host '  Nothing needs installing.' }
Write-Host ''
$go = (Read-Host '  Proceed? [Y/n]').Trim()
if ($go -and $go -notmatch '^[yY]') { Write-Host 'Nothing changed.'; exit 0 }

# ---------------------------------------------------------------- apply

$problems = @()

foreach ($t in $Tools) {
    try { Move-Tool $t.Name $enabled[$t.Name] }
    catch { $problems += ("Could not move {0}: {1}" -f $t.Name, $_.Exception.Message) }
}
if ((Test-Path -LiteralPath $DisabledDir) -and -not (Get-ChildItem -LiteralPath $DisabledDir -Force)) {
    Remove-Item -LiteralPath $DisabledDir -Force
}

if ($missing) {
    if (-not (Test-Cmd 'winget')) {
        $problems += "winget is not available. Install 'App Installer' from the Microsoft Store, then run setup again."
    } else {
        foreach ($key in $missing) {
            $dep = $Deps[$key]
            Write-Host ''
            Write-Host ("Installing {0}..." -f $dep.Label) -ForegroundColor Cyan
            try {
                if ($key -eq 'tbg') { Install-TransparentBackground } else { Install-WingetPackage $dep.Id }
                # Judge success by whether the program is now usable, not by winget's exit code.
                if (& $dep.Test) { Write-Host ("  [OK] {0}" -f $dep.Label) -ForegroundColor Green }
                else { $problems += ("{0} still not found after installing." -f $dep.Label) }
            } catch {
                $problems += ("{0}: {1}" -f $dep.Label, $_.Exception.Message)
            }
        }
        Send-EnvironmentChange
    }
}

Write-Host ''
Write-Host '========================================================================'
if ($problems) {
    Write-Host ' Setup finished with problems:' -ForegroundColor Yellow
    $problems | ForEach-Object { Write-Host ("  - {0}" -f $_) -ForegroundColor Yellow }
    Write-Host ''
    Write-Host ' Run setup again to retry.'
    exit 1
}
Write-Host ' Setup complete. Drag files onto any enabled script to use it.' -ForegroundColor Green
Write-Host ' Run setup again any time to enable or disable tools.'
Write-Host ' If a tool says a program is "not found", sign out and back in once.'
exit 0
