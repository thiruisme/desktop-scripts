@echo off
setlocal enabledelayedexpansion

where powershell >nul 2>nul
if errorlevel 1 (
    echo [ERROR] PowerShell not found.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop folders onto this script to compress to .zip.
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

if exist "%~f1.zip" (
    echo [SKIP] %~nx1 -- %~nx1.zip already exists
    shift
    goto loop
)

echo Processing: %~nx1
powershell -noprofile -command "Compress-Archive -Path '%~f1\*' -DestinationPath '%~f1.zip' -CompressionLevel Optimal"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    for %%A in ("%~f1.zip") do (
        set /a "size_kb=%%~zA / 1024"
        echo   [OK] %~nx1.zip [!size_kb!KB]
    )
)

shift
goto loop

:done
echo.
echo Done.
pause
