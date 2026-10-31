@echo off
setlocal EnableExtensions DisableDelayedExpansion

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

REM --- Locale-safe timestamp via PowerShell, with a fallback ---
set "TIMESTAMP="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "TIMESTAMP=%%T"
if not defined TIMESTAMP set "TIMESTAMP=%RANDOM%%RANDOM%"
set "OUTPUT_FILE=%OUTPUT_DIR%concatenated_%TIMESTAMP%.mp3"

REM --- Each input is first decoded to a uniform WAV so mixed formats/sample rates
REM --- concatenate cleanly, and the concat list only ever contains plain ASCII paths.
set "WORKDIR=%TEMP%\ffmpeg_concat_%RANDOM%%RANDOM%"
mkdir "%WORKDIR%" 2>nul
if not exist "%WORKDIR%\" (
    echo [ERROR] Could not create temp folder "%WORKDIR%".
    pause
    exit /b 1
)
set "FILELIST=%WORKDIR%\list.txt"
set "COUNT=0"

echo Preparing files...
:buildlist
if "%~1"=="" goto concat

if exist "%~f1\*" (
    echo   [SKIP] "%~nx1" -- is a folder
    goto nextfile
)

set /a COUNT+=1
echo   - "%~nx1"
ffmpeg -hide_banner -nostdin -y -loglevel error -i "%~f1" -map 0:a:0 -ar 44100 -ac 2 -c:a pcm_s16le "%WORKDIR%\%COUNT%.wav"
if errorlevel 1 (
    echo.
    echo [FAIL] Could not decode "%~nx1". Nothing was written.
    rd /s /q "%WORKDIR%" 2>nul
    pause
    exit /b 1
)
>>"%FILELIST%" echo file '%WORKDIR%\%COUNT%.wav'

:nextfile
shift
goto buildlist

:concat
if %COUNT% EQU 0 (
    echo [ERROR] No audio files to concatenate.
    rd /s /q "%WORKDIR%" 2>nul
    pause
    exit /b 1
)

echo.
echo Concatenating %COUNT% file^(s^)...
ffmpeg -hide_banner -nostdin -y -loglevel error -f concat -safe 0 -i "%FILELIST%" -c:a libmp3lame -b:a 192k "%OUTPUT_FILE%"
set "RC=%ERRORLEVEL%"
rd /s /q "%WORKDIR%" 2>nul

if not "%RC%"=="0" (
    echo.
    echo [FAIL] Concatenation failed.
    del "%OUTPUT_FILE%" 2>nul
    pause
    exit /b 1
)

echo.
echo [OK] "%OUTPUT_FILE%"
exit /b 0
