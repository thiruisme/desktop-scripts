@echo off
setlocal enabledelayedexpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script to convert to PNG.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if /i "%~x1"==".png" (
    echo [SKIP] %~nx1 -- already PNG
    shift
    goto loop
)

echo Processing: %~nx1
magick "%~f1" "%~dpn1.png"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1.png
)

shift
goto loop

:done
echo.
echo Done.
pause
