@echo off

net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Requires administrator privileges.
    echo Right-click and select "Run as administrator".
    pause
    exit /b 1
)

echo Stopping WinNAT...
net stop winnat /y
if errorlevel 1 (
    echo [WARN] Failed to stop WinNAT (may already be stopped).
)

echo Starting WinNAT...
net start winnat
if errorlevel 1 (
    echo [FAIL] Failed to start WinNAT.
    pause
    exit /b 1
)

echo.
echo [OK] WinNAT restarted.
pause
