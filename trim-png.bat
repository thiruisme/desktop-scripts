@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

set "FAILED=0"

:loop
if "%~1"=="" goto done

if /i not "%~x1"==".png" (
    echo [SKIP] "%~nx1" -- not a PNG
    goto next
)

echo Processing: "%~nx1"
magick "%~f1" -delete 1--1 -define filename:literal=true -trim +repage "%~dp1%~n1-trimmed.png"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1-trimmed.png"
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
