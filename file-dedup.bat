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
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Paths)

$ErrorActionPreference = 'Stop'

$paths = @($Paths | Where-Object { $_ })
if ($paths.Count -eq 0) {
    Write-Host 'Drag and drop files or folders onto this script to find duplicates.'
    Write-Host 'Compares files by SHA256 hash.'
    exit 1
}

Write-Host 'Collecting files...'
$files = foreach ($p in $paths) {
    if (Test-Path -LiteralPath $p -PathType Container) {
        Get-ChildItem -LiteralPath $p -File -Recurse -Force -ErrorAction SilentlyContinue
    } elseif (Test-Path -LiteralPath $p -PathType Leaf) {
        Get-Item -LiteralPath $p -Force
    } else {
        Write-Host ("  [SKIP] {0} (not found)" -f $p)
    }
}
# Overlapping drops (a folder and a file inside it) would otherwise count the same file twice.
$files = @($files | Sort-Object -Property FullName -Unique)

if ($files.Count -lt 2) {
    Write-Host '[INFO] Need at least 2 files to compare.'
    exit 0
}

# Only files that share a size can be duplicates, so most files never need hashing.
$empty = @($files | Where-Object { $_.Length -eq 0 }).Count
$candidates = @($files | Where-Object { $_.Length -gt 0 } | Group-Object Length | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Group })

Write-Host ("Found {0} files, {1} share a size with another file. Hashing..." -f $files.Count, $candidates.Count)

$hashed = New-Object System.Collections.Generic.List[object]
$unreadable = 0
$n = 0
$sha = [System.Security.Cryptography.SHA256]::Create()
foreach ($file in $candidates) {
    $n++
    Write-Progress -Activity 'Hashing files' -Status $file.Name -PercentComplete ([int](100 * $n / $candidates.Count))
    $stream = $null
    try {
        $stream = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'ReadWrite')
        $hash = [System.BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '')
        $hashed.Add([pscustomobject]@{ Hash = $hash; File = $file })
    } catch {
        Write-Host ("  [WARN] Could not read {0}: {1}" -f $file.FullName, $_.Exception.Message)
        $unreadable++
    } finally {
        if ($stream) { $stream.Dispose() }
    }
}
$sha.Dispose()
Write-Progress -Activity 'Hashing files' -Completed

Write-Host ''
Write-Host '========================================'
Write-Host ' Duplicate Report'
Write-Host '========================================'
Write-Host ''

$groups = @($hashed | Group-Object Hash | Where-Object { $_.Count -gt 1 } | Sort-Object { $_.Group[0].File.Length } -Descending)

$extra = 0
$wasted = 0
$g = 0
foreach ($group in $groups) {
    $g++
    $size = $group.Group[0].File.Length
    $extra += $group.Count - 1
    $wasted += $size * ($group.Count - 1)
    Write-Host ("[GROUP {0}] {1:N0} KB, hash {2}..." -f $g, [math]::Ceiling($size / 1KB), $group.Name.Substring(0, 16))
    foreach ($entry in ($group.Group | Sort-Object { $_.File.FullName })) {
        Write-Host ("  {0}" -f $entry.File.FullName)
    }
    Write-Host ''
}

if ($groups.Count -eq 0) {
    Write-Host 'No duplicates found.'
} else {
    Write-Host ("Found {0} group(s) of duplicates ({1} extra files, {2:N1} MB reclaimable)." -f $groups.Count, $extra, ($wasted / 1MB))
}
if ($empty -gt 0) { Write-Host ("Ignored {0} empty file(s)." -f $empty) }
if ($unreadable -gt 0) { Write-Host ("Could not read {0} file(s)." -f $unreadable) }
exit 0
