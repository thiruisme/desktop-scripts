@echo off
setlocal EnableExtensions DisableDelayedExpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script to convert to WebP ^(90%% quality^).
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
if /i "%~x1"==".webp" (
    echo [SKIP] "%~nx1" -- already WebP
    goto next
)

echo Processing: "%~nx1"
ffmpeg -hide_banner -nostdin -y -loglevel error -i "%~f1" -frames:v 1 -c:v libwebp -lossless 0 -q:v 90 "%~dpn1.webp"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1.webp"
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
