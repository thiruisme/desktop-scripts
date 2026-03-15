@echo off
setlocal enabledelayedexpansion

where certutil >nul 2>nul
if errorlevel 1 (
    echo [ERROR] certutil not found.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop files or folders onto this script to find duplicates.
    echo Compares files by SHA256 hash.
    pause
    exit /b 1
)

set "TEMPFILE=%TEMP%\dedup_%RANDOM%.txt"
if exist "%TEMPFILE%" del "%TEMPFILE%"

echo Collecting files...
set "filecount=0"

:collect
if "%~1"=="" goto analyze

if exist "%~f1\*" (
    for /r "%~f1" %%F in (*) do (
        echo %%~fF>> "%TEMPFILE%"
        set /a filecount+=1
    )
) else (
    echo %~f1>> "%TEMPFILE%"
    set /a filecount+=1
)

shift
goto collect

:analyze
if !filecount! LSS 2 (
    echo [INFO] Need at least 2 files to compare.
    del "%TEMPFILE%" 2>nul
    pause
    exit /b 0
)

echo Found !filecount! files. Computing hashes...

set "HASHFILE=%TEMP%\dedup_hashes_%RANDOM%.txt"
if exist "%HASHFILE%" del "%HASHFILE%"

for /f "usebackq delims=" %%F in ("%TEMPFILE%") do (
    for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%%F" SHA256 2^>nul ^| findstr /v "hash certutil"') do (
        set "hash=%%H"
        set "hash=!hash: =!"
        echo !hash!|"%%F">> "%HASHFILE%"
    )
)

echo.
echo ========================================
echo  Duplicate Report
echo ========================================
echo.

set "dupgroups=0"
set "dupfiles=0"
set "reported="

for /f "usebackq tokens=1,2 delims=|" %%A in ("%HASHFILE%") do (
    set "curhash=%%A"
    set "curfile=%%B"

    REM Check if this hash has duplicates and hasn't been reported yet
    set "matchcount=0"
    set "matches="
    for /f "usebackq tokens=1,2 delims=|" %%X in ("%HASHFILE%") do (
        if "%%X"=="!curhash!" (
            set /a matchcount+=1
            set "matches=!matches!%%Y|"
        )
    )

    if !matchcount! GTR 1 (
        echo !reported! | findstr /c:"!curhash!" >nul 2>nul
        if errorlevel 1 (
            set /a dupgroups+=1
            set /a "dupfiles+=matchcount-1"
            echo [GROUP !dupgroups!] Hash: !curhash:~0,16!...
            for %%M in ("!matches:|=" "!") do (
                if not "%%~M"=="" echo   %%~M
            )
            echo.
            set "reported=!reported!!curhash!;"
        )
    )
)

if !dupgroups! EQU 0 (
    echo No duplicates found.
) else (
    echo Found !dupgroups! group(s) of duplicates (!dupfiles! extra files).
)

del "%TEMPFILE%" 2>nul
del "%HASHFILE%" 2>nul
echo.
pause
