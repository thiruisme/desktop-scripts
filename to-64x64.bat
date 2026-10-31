@echo off
setlocal EnableExtensions DisableDelayedExpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop images onto this script.
    echo Conforms each image to 64x64 pixels ^(nearest-neighbor^).
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
ffmpeg -hide_banner -nostdin -y -loglevel warning -i "%~f1" -frames:v 1 -update 1 -vf "scale=64:64:flags=neighbor" -pix_fmt rgba "%~dp1%~n1_64x64.png"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1_64x64.png"
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
