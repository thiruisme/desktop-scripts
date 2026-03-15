@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop HDR video files onto this script to tone-map to SDR.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

echo Processing: %~nx1
ffmpeg -hide_banner -y -i "%~f1" -vf "zscale=t=linear:npl=100,format=gbrpf32le,tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p" -c:v prores_ks -profile:v 3 -c:a pcm_s16le -map 0 "%~dp1%~n1_sdr.mov"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1_sdr.mov
)

shift
goto loop

:done
echo.
echo Done.
pause
