@echo off
setlocal EnableExtensions DisableDelayedExpansion

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [ERROR] FFmpeg not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop video files onto this script to convert to GIF.
    echo Uses palette optimization for high quality. Max width 640px, 15fps.
    pause
    exit /b 1
)

set "FPS=15"
set "WIDTH=640"
set "FAILED=0"

:loop
if "%~1"=="" goto done

if exist "%~f1\*" (
    echo [SKIP] "%~nx1" -- is a folder
    goto next
)
if /i "%~x1"==".gif" (
    echo [SKIP] "%~nx1" -- already GIF
    goto next
)

set "PALETTE=%TEMP%\gif_palette_%RANDOM%%RANDOM%.png"
set "FILTERS=fps=%FPS%,scale='min(%WIDTH%,iw)':-1:flags=lanczos"

echo Processing: "%~nx1"

echo   Generating palette...
ffmpeg -hide_banner -nostdin -y -loglevel error -i "%~f1" -vf "%FILTERS%,palettegen=stats_mode=diff" "%PALETTE%"
if errorlevel 1 (
    echo   [FAIL] "%~nx1" -- palette generation failed
    del "%PALETTE%" 2>nul
    set /a FAILED+=1
    goto next
)

echo   Encoding GIF...
ffmpeg -hide_banner -nostdin -y -loglevel error -i "%~f1" -i "%PALETTE%" -lavfi "%FILTERS%[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" "%~dpn1.gif"
set "RC=%ERRORLEVEL%"
del "%PALETTE%" 2>nul

if not "%RC%"=="0" (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
    goto next
)

for %%A in ("%~dpn1.gif") do set "SIZE=%%~zA"
set /a "SIZE_KB=SIZE / 1024"
echo   [OK] "%~n1.gif" [%SIZE_KB% KB]

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
