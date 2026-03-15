@echo off
setlocal enabledelayedexpansion

REM --- Edit the path below to point to your virtual environment ---
call "C:\path\to\your\bgremove-venv\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment.
    pause
    exit /b 1
)

set PYTHONWARNINGS=ignore
set NO_ALBUMENTATIONS_UPDATE=1

if "%~1"=="" (
    echo Drag and drop image files onto this script to remove backgrounds.
    pause
    exit /b 1
)

REM --- Output to a folder next to the source file ---
set "OUTDIR=%~dp1removed-bg"
if not exist "!OUTDIR!" mkdir "!OUTDIR!"

:loop
if "%~1"=="" goto done

echo Processing: %~nx1
transparent-background --source "%~f1" --dest "!OUTDIR!" --type rgba --format png

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~n1 -- saved to removed-bg/
)

shift
goto loop

:done
echo.
echo Done. Output: !OUTDIR!
deactivate 2>nul
pause
