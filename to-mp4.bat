@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop video files onto this script to convert to MP4 (H.264).
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if /i "%~x1"==".mp4" (
    echo [SKIP] %~nx1 -- already MP4
    shift
    goto loop
)

echo Processing: %~nx1
ffmpeg -hide_banner -y -i "%~f1" -c:v libx264 -preset slower -crf 18 -c:a aac -b:a 192k -movflags +faststart "%~dpn1.mp4"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1.mp4
)

shift
goto loop

:done
echo.
echo Done.
pause
