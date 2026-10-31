@echo off
setlocal EnableExtensions DisableDelayedExpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop images onto this script to create 64x64 favicons.
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

set "OUTDIR=%~dp1favicons"
if not exist "%OUTDIR%\" mkdir "%OUTDIR%" 2>nul
if not exist "%OUTDIR%\" (
    echo [FAIL] "%~nx1" -- could not create "%OUTDIR%"
    set /a FAILED+=1
    goto next
)

echo Processing: "%~nx1"
magick "%~f1" -delete 1--1 -define filename:literal=true -auto-orient -resize 64x64 -background transparent -gravity center -extent 64x64 "%OUTDIR%\%~n1_favicon.ico"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "favicons\%~n1_favicon.ico"
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
