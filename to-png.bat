@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

set "FAILED=0"

:loop
if "%~1"=="" goto done

if exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- is a folder
    goto next
)
if /i "%~x1"==".png" (
    echo [SKIP] "%~nx1" -- already PNG
    goto next
)

echo Processing: "%~nx1"
magick "%~f1" -delete 1--1 -define filename:literal=true -auto-orient "%~dpn1.png"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1.png"
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
