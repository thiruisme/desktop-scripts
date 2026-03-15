@echo off
setlocal enabledelayedexpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop video files onto this script to compress to ~60MB.
    pause
    exit /b 1
)

set "TARGET_MB=60"
set "MAX_CRF=28"

:loop
if "%~1"=="" goto done

set "inputFile=%~f1"
set "outputFile=%~dpn1_small.mp4"
set "tempFile=%~dpn1_temp.mp4"
set "crf=23"
set "preset=medium"
set "retried=0"

echo Processing: %~nx1

:encode
echo   Encoding CRF=!crf!, preset=!preset!...
ffmpeg -hide_banner -y -i "!inputFile!" -c:v libx264 -preset !preset! -crf !crf! -vf "scale=if(gte(iw\,ih)\,-2\,min(1920\,iw)):if(gte(iw\,ih)\,min(1080\,ih)\,-2)" -c:a aac -b:a 192k -movflags +faststart "!tempFile!"

for %%I in ("!tempFile!") do set "finalsize=%%~zI"
set /a "finalsize_mb=!finalsize! / 1024 / 1024"

if !finalsize_mb! LEQ !TARGET_MB! goto accept
if !retried! equ 1 goto accept

set /a "crf+=1"
if !crf! GTR !MAX_CRF! (
    set "preset=slower"
    set "crf=!MAX_CRF!"
    set "retried=1"
)
del "!tempFile!" 2>nul
goto encode

:accept
move /y "!tempFile!" "!outputFile!" >nul
echo   [OK] %~n1_small.mp4 [!finalsize_mb!MB, CRF=!crf!]

shift
goto loop

:done
echo.
echo Done.
pause
