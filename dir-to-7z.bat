@echo off
setlocal enabledelayedexpansion

set "ZIP_PATH=C:\Program Files\7-Zip\7z.exe"
if not exist "%ZIP_PATH%" set "ZIP_PATH=C:\Program Files (x86)\7-Zip\7z.exe"
if not exist "%ZIP_PATH%" (
    echo [ERROR] 7-Zip not found.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop folders onto this script to compress to .7z.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

if not exist "%~f1\*" (
    echo [SKIP] %~nx1 -- not a folder
    shift
    goto loop
)

if exist "%~f1.7z" (
    echo [SKIP] %~nx1 -- %~nx1.7z already exists
    shift
    goto loop
)

echo Processing: %~nx1
"%ZIP_PATH%" a -t7z "%~f1.7z" "%~f1\*" -mx=5 -r

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    echo   [OK] %~nx1.7z
)

shift
goto loop

:done
echo.
echo Done.
pause
