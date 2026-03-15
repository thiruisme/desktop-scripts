@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop video/audio files onto this script to extract MP3.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if /i "%~x1"==".mp3" (
    echo [SKIP] %~nx1 -- already MP3
    shift
    goto loop
)

echo Processing: %~nx1
ffmpeg -hide_banner -i "%~f1" -y -vn -acodec libmp3lame -q:a 2 "%~dpn1.mp3"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1.mp3
)

shift
goto loop

:done
echo.
echo Done.
pause
