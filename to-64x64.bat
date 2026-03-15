@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Drag and drop images onto this script.
    pause
    exit /b
)

echo ========================================
echo  64x64 Pixel Conform
echo ========================================

for %%f in (%*) do (
    echo Processing: %%~nxf
    ffmpeg -y -i "%%f" -vf "scale=64:64:flags=neighbor" -pix_fmt rgba "%%~dpf%%~nf_64x64.png" -loglevel warning
)

echo.
echo Done!
timeout /t 3