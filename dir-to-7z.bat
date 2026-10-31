@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "ZIP_PATH="
for %%P in ("%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles(x86)%\7-Zip\7z.exe") do (
    if not defined ZIP_PATH if exist "%%~P" set "ZIP_PATH=%%~P"
)
if not defined ZIP_PATH for /f "delims=" %%P in ('where 7z 2^>nul') do (
    if not defined ZIP_PATH set "ZIP_PATH=%%P"
)
if not defined ZIP_PATH (
    echo [ERROR] 7-Zip not found.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop folders onto this script to compress to .7z.
    pause
    exit /b 1
)

set "FAILED=0"

:loop
if "%~1"=="" goto done

if not exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- not a folder
    goto next
)
if exist "%~f1.7z" (
    echo [SKIP] "%~nx1" -- "%~nx1.7z" already exists
    goto next
)

echo Processing: "%~nx1"
"%ZIP_PATH%" a -t7z -mx=5 -bso0 -bsp1 -- "%~f1.7z" "%~f1\*"
set "RC=%ERRORLEVEL%"

REM --- 7-Zip exit codes: 0 = OK, 1 = warning (e.g. locked files skipped), 2+ = error ---
if "%RC%"=="0" (
    echo   [OK] "%~nx1.7z"
) else if "%RC%"=="1" (
    echo   [WARN] "%~nx1.7z" created, but some files were skipped
    set /a FAILED+=1
) else (
    echo   [FAIL] "%~nx1"
    del "%~f1.7z" 2>nul
    set /a FAILED+=1
)

:next
shift
goto loop

:done
echo.
if %FAILED% GTR 0 (
    echo Done with %FAILED% problem^(s^).
    pause
    exit /b 1
)
echo Done.
exit /b 0
