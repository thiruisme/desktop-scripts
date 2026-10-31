@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

set "FAILED=0"

:loop
if "%~1"=="" goto done

if exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- is a folder
    goto next
)
if /i "%~x1"==".jpg" (
    echo [SKIP] "%~nx1" -- already JPG
    goto next
)
if /i "%~x1"==".jpeg" (
    echo [SKIP] "%~nx1" -- already JPG
    goto next
)

echo Processing: "%~nx1"
REM --- -auto-orient before -strip, otherwise rotated photos come out sideways.
REM --- Transparency is flattened onto white instead of turning black.
magick "%~f1" -delete 1--1 -define filename:literal=true -auto-orient -background white -alpha remove -alpha off -quality 100 -strip "%~dpn1.jpg"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1.jpg"
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
