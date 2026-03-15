@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script to convert to WebP (90%% quality).
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if /i "%~x1"==".webp" (
    echo [SKIP] %~nx1 -- already WebP
    shift
    goto loop
)

echo Processing: %~nx1
ffmpeg -hide_banner -y -loglevel error -i "%~f1" -vcodec libwebp -lossless 0 -q:v 90 "%~dpn1.webp"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1.webp
)

shift
goto loop

:done
echo.
echo Done.
pause
