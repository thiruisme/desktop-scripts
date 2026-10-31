@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

set "FAILED=0"

:loop
if "%~1"=="" goto done

if exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- is a folder
    goto next
)
if /i "%~x1"==".mp3" (
    echo [SKIP] "%~nx1" -- already MP3
    goto next
)

echo Processing: "%~nx1"
ffmpeg -hide_banner -nostdin -y -i "%~f1" -map 0:a:0 -c:a libmp3lame -q:a 2 "%~dpn1.mp3"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1.mp3"
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
