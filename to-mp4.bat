@echo off
where ffmpeg >nul 2>nul
if errorlevel 1 goto no_ffmpeg
if "%~1"=="" goto no_args

:loop
if "%~1"=="" goto done
if /i "%~x1"==".mp4" goto already_mp4
goto convert
:already_mp4
echo [SKIP] %~nx1 -- already MP4
shift
goto loop

:convert
echo Processing: %~nx1
ffmpeg -hide_banner -y -i "%~f1" -c:v libx264 -preset slower -crf 18 -c:a aac -b:a 192k -sn -dn -movflags +faststart "%~dpn1.mp4"
if errorlevel 1 goto fail
echo   [OK] %~n1.mp4
shift
goto loop

:fail
echo   [FAIL] %~nx1
pause
shift
goto loop

:done
echo.
echo Done.
goto end

:no_ffmpeg
echo [ERROR] FFmpeg not found in PATH.
pause
goto end

:no_args
echo Drag and drop video files onto this script to convert to MP4.

:end
