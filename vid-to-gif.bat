@echo off
setlocal enabledelayedexpansion

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

:loop
if "%~1"=="" goto done

set "inputFile=%~f1"
set "outputFile=%~dpn1.gif"
set "palette=%TEMP%\gif_palette_%RANDOM%.png"

echo Processing: %~nx1

echo   Generating palette...
ffmpeg -hide_banner -y -loglevel error -i "!inputFile!" -vf "fps=%FPS%,scale=%WIDTH%:-1:flags=lanczos,palettegen=stats_mode=diff" "!palette!"

if errorlevel 1 (
    echo   [FAIL] %~nx1 -- palette generation failed
    del "!palette!" 2>nul
    shift
    goto loop
)

echo   Encoding GIF...
ffmpeg -hide_banner -y -loglevel error -i "!inputFile!" -i "!palette!" -lavfi "fps=%FPS%,scale=%WIDTH%:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" "!outputFile!"

del "!palette!" 2>nul

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    for %%A in ("!outputFile!") do (
        set /a "size_kb=%%~zA / 1024"
        echo   [OK] %~n1.gif [!size_kb!KB]
    )
)

shift
goto loop

:done
echo.
echo Done.
pause
