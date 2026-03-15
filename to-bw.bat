@echo off
setlocal enabledelayedexpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script to convert to grayscale.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

echo Processing: %~nx1
magick "%~f1" -colorspace Gray "%~dp1%~n1-bw%~x1"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1-bw%~x1
)

shift
goto loop

:done
echo.
echo Done.
pause
