@echo off
setlocal enabledelayedexpansion

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

:loop
if "%~1"=="" goto done

echo Processing: %~nx1
magick "%~f1" -auto-orient -resize %WIDTH%x%HEIGHT%^^ -gravity center -extent %WIDTH%x%HEIGHT% -blur 0x200 -modulate 90 "%~f1" -auto-orient -gravity center -resize %WIDTH%x%HEIGHT% -composite -quality 95 "%~dp1%~n1-4k-landscape.jpg"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1-4k-landscape.jpg
)

shift
goto loop

:done
echo.
echo Done.
pause
