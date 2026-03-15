@echo off
setlocal enabledelayedexpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop PNG files onto this script to trim whitespace.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if /i not "%~x1"==".png" (
    echo [SKIP] %~nx1 -- not a PNG
    shift
    goto loop
)

echo Processing: %~nx1
magick "%~f1" -trim +repage "%~dp1%~n1-trimmed.png"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1-trimmed.png
)

shift
goto loop

:done
echo.
echo Done.
pause
