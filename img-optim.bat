@echo off
setlocal EnableExtensions DisableDelayedExpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script.
    echo Resizes to max 1920px height, targets under 200KB.
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

set "OUTDIR=%~dp1resized"
if not exist "%OUTDIR%\" mkdir "%OUTDIR%" 2>nul
if not exist "%OUTDIR%\" (
    echo [FAIL] "%~nx1" -- could not create "%OUTDIR%"
    set /a FAILED+=1
    goto next
)

echo Processing: "%~nx1"
REM --- jpeg:extent makes ImageMagick search for the best quality that fits in 200KB ---
magick "%~f1" -delete 1--1 -define filename:literal=true -auto-orient -resize "x1920>" -background white -alpha remove -alpha off -quality 90 -define jpeg:extent=200KB "%OUTDIR%\%~n1.jpg"

if errorlevel 1 goto optim_fail
if not exist "%OUTDIR%\%~n1.jpg" goto optim_fail

set "SIZE=0"
for %%A in ("%OUTDIR%\%~n1.jpg") do set "SIZE=%%~zA"
set /a "SIZE_KB=SIZE / 1024"
if %SIZE% GTR 204800 (
    echo   [WARN] "%~n1.jpg" could not get under 200KB [%SIZE_KB% KB]
) else (
    echo   [OK] "resized\%~n1.jpg" [%SIZE_KB% KB]
)
goto next

:optim_fail
echo   [FAIL] "%~nx1"
set /a FAILED+=1

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
