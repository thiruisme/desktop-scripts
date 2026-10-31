@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

set "FAILED=0"

:loop
if "%~1"=="" goto done

if not exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- not a folder
    goto next
)
if exist "%~f1.zip" (
    echo [SKIP] "%~nx1" -- "%~nx1.zip" already exists
    goto next
)

echo Processing: "%~nx1"
REM --- Paths go through env vars so quotes/brackets in names can't break the command.
REM --- ZipFile (unlike Compress-Archive) includes hidden files and handles files over 2GB.
set "ZIP_SRC=%~f1"
set "ZIP_DST=%~f1.zip"
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::CreateFromDirectory($env:ZIP_SRC, $env:ZIP_DST, [IO.Compression.CompressionLevel]::Optimal, $false); $kb = [math]::Round((Get-Item -LiteralPath $env:ZIP_DST).Length / 1KB); Write-Host ('  [OK] ' + [IO.Path]::GetFileName($env:ZIP_DST) + ' [' + $kb + ' KB]') } catch { Write-Host ('  ' + $_.Exception.Message); if (Test-Path -LiteralPath $env:ZIP_DST) { Remove-Item -LiteralPath $env:ZIP_DST -Force }; exit 1 }"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
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
