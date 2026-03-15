@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script.
    echo Converts to WebP, max 700px wide, 90%% quality.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

echo Processing: %~nx1
ffmpeg -hide_banner -y -loglevel error -i "%~f1" -vf scale=700:-1 -vcodec libwebp -q:v 90 "%~dp1%~n1-sm.webp"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1-sm.webp
)

shift
goto loop

:done
echo.
echo Done.
pause
