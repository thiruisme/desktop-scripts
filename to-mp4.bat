@echo off
setlocal EnableExtensions DisableDelayedExpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop video files onto this script to convert to MP4.
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
if /i "%~x1"==".mp4" (
    echo [SKIP] "%~nx1" -- already MP4
    goto next
)

echo Processing: "%~nx1"
REM --- Even dimensions + yuv420p keep libx264 happy and the output playable everywhere ---
ffmpeg -hide_banner -nostdin -y -i "%~f1" -map 0:v:0 -map 0:a? -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -preset slower -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -sn -dn -movflags +faststart "%~dpn1.mp4"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1.mp4"
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
