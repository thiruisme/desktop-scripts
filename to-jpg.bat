@echo off
setlocal enabledelayedexpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script to convert to JPG.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if /i "%~x1"==".jpg" (
    echo [SKIP] %~nx1 -- already JPG
    shift
    goto loop
)
if /i "%~x1"==".jpeg" (
    echo [SKIP] %~nx1 -- already JPG
    shift
    goto loop
)

echo Processing: %~nx1
magick "%~f1" -quality 100 -strip "%~dpn1.jpg"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1.jpg
)

shift
goto loop

:done
echo.
echo Done.
pause
