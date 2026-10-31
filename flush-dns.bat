@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM --- fltmc only succeeds when elevated (and, unlike "net session", doesn't need the Server service) ---
fltmc >nul 2>&1
if errorlevel 1 (
    if /i "%~1"=="elevated" (
        echo [ERROR] Still not elevated after the UAC prompt.
        pause
        exit /b 1
    )
    set "SELF=%~f0"
    powershell -NoProfile -Command "try { Start-Process -FilePath $env:SELF -ArgumentList 'elevated' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo [ERROR] Requires administrator privileges ^(UAC prompt was declined^).
        pause
        exit /b 1
    )
    exit /b 0
)

echo Flushing DNS resolver cache...
ipconfig /flushdns

if errorlevel 1 (
    echo [FAIL] Could not flush DNS cache.
    pause
    exit /b 1
)

echo [OK] DNS cache flushed.
exit /b 0
