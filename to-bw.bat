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
if not "%RC%"=="0" (
    echo.
    pause
)
exit /b %RC%
#__POWERSHELL__
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Files)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Host '[ERROR] ImageMagick not found in PATH.' -ForegroundColor Red
    exit 1
}

$files = @($Files | Where-Object { $_ })

if ($files.Count -eq 0) {
    Add-Type -AssemblyName System.Windows.Forms
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Multiselect = $true
    $d.Title = 'Select images to convert to grayscale'
    $d.Filter = 'Images|*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff;*.webp;*.gif|All files|*.*'
    if ($d.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 0 }
    $files = $d.FileNames
}

Write-Host ("Processing {0} file(s)..." -f $files.Count)
Write-Host ''

$failed = 0
foreach ($f in $files) {
    $i = Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
    if (-not $i -or $i.PSIsContainer) {
        Write-Host ("  [SKIP] {0} (not a file)" -f $f)
        continue
    }
    $out = Join-Path $i.DirectoryName ($i.BaseName + '-bw' + $i.Extension)
    # ImageMagick expands %d/%x in output names, so write to a plain temp name and move it.
    $temp = Join-Path $env:TEMP ('to-bw_' + [guid]::NewGuid().ToString('N') + $i.Extension)
    Write-Host ("Processing: {0}" -f $i.Name)
    & magick $i.FullName -colorspace Gray $temp
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $temp)) {
        Move-Item -LiteralPath $temp -Destination $out -Force
        Write-Host ("  [OK] {0}-bw{1}" -f $i.BaseName, $i.Extension)
    } else {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Write-Host ("  [FAIL] {0}" -f $i.Name) -ForegroundColor Red
        $failed++
    }
}

if ($failed -gt 0) {
    Write-Host ''
    Write-Host ("Done with {0} failure(s)." -f $failed)
    exit 1
}
exit 0
