@echo off
setlocal EnableExtensions DisableDelayedExpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

REM --- ExifTool is optional: magick -strip already removes metadata ---
set "HAVE_EXIFTOOL="
where exiftool >nul 2>nul
if not errorlevel 1 set "HAVE_EXIFTOOL=1"

if "%~1"=="" (
    echo Drag and drop image files onto this script.
    echo Resizes, strips EXIF, randomizes filename.
    pause
    exit /b 1
)

set "FAILED=0"

:loop
if "%~1"=="" goto done

set "IS_IMAGE="
if /i "%~x1"==".jpg" set "IS_IMAGE=1"
if /i "%~x1"==".jpeg" set "IS_IMAGE=1"
if /i "%~x1"==".png" set "IS_IMAGE=1"
if /i "%~x1"==".webp" set "IS_IMAGE=1"

if not defined IS_IMAGE (
    echo [SKIP] "%~nx1" -- not a supported image
    goto next
)

echo Processing: "%~nx1"

:pickname
call :randname
if exist "%~dp1%RANDNAME%.jpg" goto pickname

REM --- -auto-orient before -strip, otherwise rotated photos come out sideways ---
magick "%~f1" -delete 1--1 -auto-orient -resize "2048x2048>" -background white -alpha remove -alpha off -quality 82 -strip "%~dp1%RANDNAME%.jpg"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
    goto next
)

if defined HAVE_EXIFTOOL exiftool -q -q -all= -overwrite_original "%~dp1%RANDNAME%.jpg" >nul 2>nul
echo   [OK] %RANDNAME%.jpg

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

:randname
setlocal EnableDelayedExpansion
set "CHARS=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
set "NAME="
for /L %%N in (1,1,12) do (
    set /a "R=!RANDOM! %% 62"
    for %%C in (!R!) do set "NAME=!NAME!!CHARS:~%%C,1!"
)
endlocal & set "RANDNAME=%NAME%"
exit /b 0
