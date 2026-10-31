@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM --- Optional: set VENV to a virtual environment that has transparent-background installed.
REM --- Leave it empty to use transparent-background from PATH.
set "VENV="

if defined VENV (
    set "TB=%VENV%\Scripts\transparent-background.exe"
) else (
    set "TB=transparent-background"
)

if defined VENV (
    if not exist "%VENV%\Scripts\transparent-background.exe" (
        echo [ERROR] transparent-background not found in "%VENV%".
        echo Edit VENV at the top of this script.
        pause
        exit /b 1
    )
) else (
    where transparent-background >nul 2>nul
    if errorlevel 1 (
        echo [ERROR] transparent-background not found in PATH.
        echo Install it ^(pip install transparent-background^) or set VENV in this script.
        pause
        exit /b 1
    )
)

set "PYTHONWARNINGS=ignore"
set "NO_ALBUMENTATIONS_UPDATE=1"

if "%~1"=="" (
    echo Drag and drop image files onto this script to remove backgrounds.
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

REM --- Output to a folder next to each source file ---
set "OUTDIR=%~dp1removed-bg"
if not exist "%OUTDIR%\" mkdir "%OUTDIR%" 2>nul

echo Processing: "%~nx1"
"%TB%" --source "%~f1" --dest "%OUTDIR%" --type rgba --format png

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "%~n1" -- saved to removed-bg\
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
