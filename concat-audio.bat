@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop audio files onto this script to concatenate them.
    pause
    exit /b 1
)

set "OUTPUT_DIR=%~dp1"

REM --- Locale-safe timestamp via PowerShell ---
for /f "usebackq" %%T in (`powershell -noprofile -command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "timestamp=%%T"
set "OUTPUT_FILE=%OUTPUT_DIR%concatenated_%timestamp%.mp3"

set "FILELIST=%TEMP%\ffmpeg_concat_%timestamp%.txt"
if exist "%FILELIST%" del "%FILELIST%"

echo Building file list...
:buildlist
if "%~1"=="" goto concat

REM --- Escape single quotes for ffmpeg concat format ---
set "filepath=%~f1"
set "filepath=!filepath:'='\''!"
echo file '!filepath!'>> "%FILELIST%"
echo   - %~nx1
shift
goto buildlist

:concat
echo.
echo Concatenating...
ffmpeg -hide_banner -y -f concat -safe 0 -i "%FILELIST%" -acodec libmp3lame -b:a 192k "%OUTPUT_FILE%"

if errorlevel 1 (
    echo.
    echo [FAIL] Concatenation failed.
) else (
    echo.
    echo [OK] %OUTPUT_FILE%
)

del "%FILELIST%" 2>nul
echo.
pause
