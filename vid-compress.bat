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

$TargetMB = 60
$Crf = 23
$AudioKbps = 192
# Cap the short side at 1080px; both sides are kept even, which libx264 requires.
$Scale = "scale=w='if(gte(iw,ih),-2,trunc(min(1080,iw)/2)*2)':h='if(gte(iw,ih),trunc(min(1080,ih)/2)*2,-2)'"

foreach ($tool in 'ffmpeg', 'ffprobe') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host ("[ERROR] {0} not found in PATH." -f $tool) -ForegroundColor Red
        exit 1
    }
}

$files = @($Files | Where-Object { $_ })
if ($files.Count -eq 0) {
    Write-Host ("Drag and drop video files onto this script to compress to ~{0}MB." -f $TargetMB)
    exit 1
}

function Invoke-Ffmpeg([string[]]$FfArgs) {
    & ffmpeg -hide_banner -nostdin -y @FfArgs | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg exited with code $LASTEXITCODE" }
}

$targetBytes = $TargetMB * 1MB
$failed = 0

foreach ($f in $files) {
    $item = Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
    if (-not $item -or $item.PSIsContainer) {
        Write-Host ("[SKIP] {0} (not a file)" -f $f)
        continue
    }

    $out = Join-Path $item.DirectoryName ($item.BaseName + '_small.mp4')
    $temp = Join-Path $item.DirectoryName ($item.BaseName + '_small.partial.mp4')
    $passLog = Join-Path $env:TEMP ('vidcompress_' + [guid]::NewGuid().ToString('N'))
    $video = @('-map', '0:v:0', '-map', '0:a:0?', '-vf', $Scale, '-c:v', 'libx264', '-pix_fmt', 'yuv420p')

    Write-Host ("Processing: {0}" -f $item.Name)
    try {
        Write-Host ("  Encoding CRF={0}..." -f $Crf)
        Invoke-Ffmpeg (@('-i', $item.FullName) + $video + @('-preset', 'medium', '-crf', "$Crf", '-c:a', 'aac', '-b:a', "${AudioKbps}k", '-movflags', '+faststart', $temp))
        $mode = "CRF=$Crf"

        if ((Get-Item -LiteralPath $temp).Length -gt $targetBytes) {
            # Too big: compute the bitrate that fits the target and do an exact two-pass encode.
            $probe = & ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 $item.FullName | Select-Object -First 1
            $duration = 0.0
            if (-not [double]::TryParse("$probe", [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$duration) -or $duration -le 0) {
                throw "Could not read video duration (ffprobe said '$probe')"
            }
            $totalKbps = [math]::Floor($targetBytes * 8 * 0.97 / $duration / 1000)
            $audio = $AudioKbps
            if ($totalKbps - $audio -lt 400) { $audio = 96 }
            $videoKbps = [math]::Max(50, $totalKbps - $audio)
            $mode = "2-pass {0}k video" -f $videoKbps

            Write-Host ("  Too large; two-pass encode at {0}k video + {1}k audio..." -f $videoKbps, $audio)
            Invoke-Ffmpeg (@('-i', $item.FullName) + $video + @('-preset', 'slow', '-b:v', "${videoKbps}k", '-pass', '1', '-passlogfile', $passLog, '-an', '-f', 'null', 'NUL'))
            Invoke-Ffmpeg (@('-i', $item.FullName) + $video + @('-preset', 'slow', '-b:v', "${videoKbps}k", '-pass', '2', '-passlogfile', $passLog, '-c:a', 'aac', '-b:a', "${audio}k", '-movflags', '+faststart', $temp))
        }

        Move-Item -LiteralPath $temp -Destination $out -Force
        $sizeMB = (Get-Item -LiteralPath $out).Length / 1MB
        if ($sizeMB -gt $TargetMB) {
            Write-Host ("  [WARN] {0} [{1:N1}MB, {2}] is over the {3}MB target" -f (Split-Path $out -Leaf), $sizeMB, $mode, $TargetMB) -ForegroundColor Yellow
        } else {
            Write-Host ("  [OK] {0} [{1:N1}MB, {2}]" -f (Split-Path $out -Leaf), $sizeMB, $mode)
        }
    } catch {
        Write-Host ("  [FAIL] {0} -- {1}" -f $item.Name, $_.Exception.Message) -ForegroundColor Red
        $failed++
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
        Get-ChildItem -LiteralPath $env:TEMP -Filter ((Split-Path $passLog -Leaf) + '*') -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
if ($failed -gt 0) {
    Write-Host ("Done with {0} failure(s)." -f $failed)
    exit 1
}
Write-Host 'Done.'
exit 0
