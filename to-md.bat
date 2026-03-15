@echo off
setlocal enabledelayedexpansion

where pandoc >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Pandoc not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop documents onto this script to convert to Markdown.
    echo Supported: docx, doc, html, htm, epub, odt, rtf, tex, rst, textile, mediawiki, pdf
    pause
    exit /b 1
)

set "SUPPORTED=.docx .doc .html .htm .epub .odt .rtf .tex .rst .textile .mediawiki .pdf"
set "converted=0"
set "skipped=0"

:loop
if "%~1"=="" goto done

set "ext=%~x1"
set "found=0"
for %%s in (%SUPPORTED%) do (
    if /i "%%s"=="!ext!" set "found=1"
)

if "!found!"=="0" (
    echo [SKIP] %~nx1 -- unsupported format
    set /a skipped+=1
    shift
    goto loop
)

set "outdir=%~dp1markdown_output"
if not exist "!outdir!" mkdir "!outdir!"

echo Processing: %~nx1
pandoc "%~f1" -t markdown -o "!outdir!\%~n1.md" --wrap=none 2>nul

if errorlevel 1 (
    echo   [FAIL] %~nx1
    set /a skipped+=1
) else (
    echo   [OK] %~n1.md
    set /a converted+=1
)

shift
goto loop

:done
echo.
echo Done. !converted! converted, !skipped! skipped.
if defined outdir echo Output: !outdir!
echo Note: files from different folders produce separate markdown_output folders.
pause
