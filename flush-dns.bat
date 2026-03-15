@echo off

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Requires administrator privileges.
    echo Right-click and select "Run as administrator".
    pause
    exit /b 1
)

echo Flushing DNS resolver cache...
ipconfig /flushdns

if errorlevel 1 (
    echo [FAIL] Could not flush DNS cache.
) else (
    echo.
    echo [OK] DNS cache flushed.
)

pause
