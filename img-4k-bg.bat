@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "WIDTH=3840"
set "HEIGHT=2160"

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop images onto this script.
    echo Creates a 4K landscape with blurred background.
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
magick "%~f1" -delete 1--1 -define filename:literal=true -auto-orient -resize "%WIDTH%x%HEIGHT%^" -gravity center -extent %WIDTH%x%HEIGHT% -blur 0x200 -modulate 90 "(" "%~f1" -delete 1--1 -auto-orient -resize %WIDTH%x%HEIGHT% ")" -gravity center -composite -quality 95 "%~dp1%~n1-4k-landscape.jpg"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1-4k-landscape.jpg"
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
