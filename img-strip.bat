@echo off
setlocal enabledelayedexpansion

where exiftool >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ExifTool not found in PATH.
    pause
    exit /b 1
)
where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script.
    echo Resizes, strips EXIF, randomizes filename.
    pause
    exit /b 1
)

:loop
if "%~1"=="" goto done

set "is_image="
set "ext=%~x1"
if /i "!ext!"==".jpg" set "is_image=1"
if /i "!ext!"==".jpeg" set "is_image=1"
if /i "!ext!"==".png" set "is_image=1"
if /i "!ext!"==".webp" set "is_image=1"

if not defined is_image (
    echo [SKIP] %~nx1 -- not a supported image
    shift
    goto loop
)

echo Processing: %~nx1
set "chars=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
set "randname="
for /L %%N in (1,1,12) do (
    set /a "rand=!random! %% 62"
    for %%C in (!rand!) do set "randname=!randname!!chars:~%%C,1!"
)

magick "%~f1" -geometry 2048x2048^> -quality 82 -strip "%~dp1!randname!.jpg"

if errorlevel 1 (
    echo   [FAIL] %~nx1
) else (
    exiftool -all= -overwrite_original "%~dp1!randname!.jpg" >nul 2>nul
    echo   [OK] !randname!.jpg
)

shift
goto loop

:done
echo.
echo Done.
pause
