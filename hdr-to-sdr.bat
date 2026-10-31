@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

set "FAILED=0"

:loop
if "%~1"=="" goto done

if exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- is a folder
    goto next
)

echo Processing: "%~nx1"
REM --- Map only the main video + audio; subtitle/data streams can't go into ProRes MOV ---
ffmpeg -hide_banner -nostdin -y -i "%~f1" -map 0:v:0 -map 0:a? -vf "zscale=t=linear:npl=100,format=gbrpf32le,tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv422p10le" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "%~dp1%~n1_sdr.mov"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1_sdr.mov"
)

:next
shift
goto loop

:done
echo.
if %FAILED% GTR 0 (
    echo Done with %FAILED% failure^(s^).
    pause
    exit /b 1
)
echo Done.
exit /b 0
