@echo off
setlocal enabledelayedexpansion

where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop image files onto this script.
    echo Resizes to max 1920px height, targets under 200KB.
    pause
    exit /b 1
)

set "OUTDIR=%~dp1resized"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

for %%F in (%*) do call :process "%%~fF" "%%~nF" "%%~nxF"

echo.
echo Done. Output: %OUTDIR%
pause
exit /b

:process
set "FILEPATH=%~1"
set "NAME=%~2"
set "FULLNAME=%~3"
set "QUALITY=90"

echo Processing: %FULLNAME%
magick "%FILEPATH%" -resize "x1920>" -quality %QUALITY% "%OUTDIR%\%NAME%.jpg"

:checksize
for %%A in ("%OUTDIR%\%NAME%.jpg") do set "FSIZE=%%~zA"
if !FSIZE! GTR 204800 (
    set /a QUALITY-=5
    if !QUALITY! LEQ 10 (
        echo   [WARN] %FULLNAME% could not get under 200KB
        goto :donefile
    )
    magick "%FILEPATH%" -resize "x1920>" -quality !QUALITY! "%OUTDIR%\%NAME%.jpg"
    goto :checksize
)

:donefile
set /a FSIZE_KB=!FSIZE! / 1024
echo   [OK] %NAME%.jpg [!FSIZE_KB!KB, q=!QUALITY!]
exit /b
