@echo off
setlocal EnableExtensions DisableDelayedExpansion

where pandoc >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Pandoc not found in PATH.
    pause
    exit /b 1
)

if "%~1"=="" (
    echo Drag and drop documents onto this script to convert to Markdown.
    echo Supported: docx, odt, epub, html, htm, rtf, tex, rst, textile, mediawiki, org, ipynb, pptx, xlsx, typ
    pause
    exit /b 1
)

set "CONVERTED=0"
set "SKIPPED=0"
set "FAILED=0"

:loop
if "%~1"=="" goto done

REM --- Explicit input format per extension; pandoc can't read .doc or .pdf ---
set "FMT="
if /i "%~x1"==".docx" set "FMT=docx"
if /i "%~x1"==".odt" set "FMT=odt"
if /i "%~x1"==".epub" set "FMT=epub"
if /i "%~x1"==".html" set "FMT=html"
if /i "%~x1"==".htm" set "FMT=html"
if /i "%~x1"==".rtf" set "FMT=rtf"
if /i "%~x1"==".tex" set "FMT=latex"
if /i "%~x1"==".rst" set "FMT=rst"
if /i "%~x1"==".textile" set "FMT=textile"
if /i "%~x1"==".mediawiki" set "FMT=mediawiki"
if /i "%~x1"==".wiki" set "FMT=mediawiki"
if /i "%~x1"==".org" set "FMT=org"
if /i "%~x1"==".ipynb" set "FMT=ipynb"
if /i "%~x1"==".pptx" set "FMT=pptx"
if /i "%~x1"==".xlsx" set "FMT=xlsx"
if /i "%~x1"==".typ" set "FMT=typst"

if not defined FMT (
    echo [SKIP] "%~nx1" -- unsupported format
    set /a SKIPPED+=1
    goto next
)

set "OUTDIR=%~dp1markdown_output"
if not exist "%OUTDIR%\" mkdir "%OUTDIR%" 2>nul

echo Processing: "%~nx1"
pandoc "%~f1" -f %FMT% -t markdown --wrap=none -o "%OUTDIR%\%~n1.md"

if errorlevel 1 (
    echo   [FAIL] "%~nx1"
    set /a FAILED+=1
) else (
    echo   [OK] "markdown_output\%~n1.md"
    set /a CONVERTED+=1
)

:next
shift
goto loop

:done
echo.
echo Done. %CONVERTED% converted, %SKIPPED% skipped, %FAILED% failed.
set /a "PROBLEMS=FAILED + SKIPPED"
if %PROBLEMS% GTR 0 (
    pause
    exit /b 1
)
exit /b 0
