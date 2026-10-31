@echo off
setlocal EnableExtensions DisableDelayedExpansion
REM --- Batch + PowerShell in one file. The batch part copies the PowerShell code below the
REM --- #__POWERSHELL__ line to a temp .ps1, runs it with the dropped files, then deletes it.
set "SELF=%~f0"
set "SCRIPT_DIR=%~dp0"
set "PS1=%TEMP%\%~n0_%RANDOM%%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = [IO.File]::ReadAllText($env:SELF); $i = $s.IndexOf([char]10 + '#__POWERSHELL__'); if ($i -lt 0) { exit 1 }; [IO.File]::WriteAllText($env:PS1, $s.Substring($s.IndexOf([char]10, $i + 1) + 1), (New-Object Text.UTF8Encoding $true))"
if errorlevel 1 (
    echo [ERROR] Could not prepare the PowerShell part of this script.
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%ERRORLEVEL%"
del "%PS1%" 2>nul
if not "%RC%"=="0" (
    echo.
    pause
)
exit /b %RC%
#__POWERSHELL__
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Files)

$ErrorActionPreference = 'Stop'

$MaxAttempts = 3

# qpdf's installer doesn't add itself to PATH, so also look in Program Files.
$qpdf = (Get-Command qpdf -ErrorAction SilentlyContinue).Source
if (-not $qpdf) {
    $qpdf = Get-ChildItem -Path "$env:ProgramFiles\qpdf*\bin\qpdf.exe", "${env:ProgramFiles(x86)}\qpdf*\bin\qpdf.exe" -ErrorAction SilentlyContinue |
        Sort-Object { $_.VersionInfo.FileVersionRaw } -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $qpdf) {
    Write-Host '[ERROR] qpdf not found. Install it with: winget install --id QPDF.QPDF -e' -ForegroundColor Red
    exit 1
}

$files = @($Files | Where-Object { $_ })
if ($files.Count -eq 0) {
    Write-Host 'Drag and drop password-protected PDFs onto this script to remove the password.'
    Write-Host 'Writes name-unlocked.pdf next to each file; the original is left untouched.'
    exit 1
}

# Runs qpdf, feeding the password on stdin (never on the command line, where other
# processes could read it). Raw UTF-8 bytes are written so non-ASCII passwords survive.
# $Password is untyped on purpose: [string] would turn "no password" ($null) into ''.
function Invoke-Qpdf([string[]]$QArgs, $Password = $null) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $qpdf
    $all = @()
    if ($null -ne $Password) { $all += '--password-file=-' }
    $all += $QArgs
    $psi.Arguments = ($all | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    # .NET builds qpdf's stdin writer from the console's input encoding, and on a UTF-8
    # console that writer sends a byte-order mark first, which qpdf would read as part of
    # the password. A BOM-less UTF-8 encoding is set just for the start.
    $prevEncoding = [Console]::InputEncoding
    try { [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false } catch { }
    try { $p = [System.Diagnostics.Process]::Start($psi) }
    finally { try { [Console]::InputEncoding = $prevEncoding } catch { } }
    $stdout = $p.StandardOutput.ReadToEndAsync()
    $stderr = $p.StandardError.ReadToEndAsync()
    if ($null -ne $Password) {
        $bytes = (New-Object System.Text.UTF8Encoding $false).GetBytes($Password + "`n")
        $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
        $p.StandardInput.BaseStream.Flush()
    }
    $p.StandardInput.Close()
    $p.WaitForExit()
    [pscustomobject]@{ Code = $p.ExitCode; Output = ($stdout.Result + $stderr.Result).Trim() }
}

function Read-Password([string]$Name) {
    $secure = Read-Host -AsSecureString ("  Password for {0} (Enter to skip)" -f $Name)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

$failed = 0
foreach ($f in $files) {
    $item = Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
    if (-not $item -or $item.PSIsContainer) {
        Write-Host ("[SKIP] {0} (not a file)" -f $f)
        continue
    }
    if ($item.Extension -ne '.pdf') {
        Write-Host ("[SKIP] {0} (not a PDF)" -f $item.Name)
        continue
    }

    Write-Host ("Processing: {0}" -f $item.Name)

    # --requires-password exit codes: 0 = password needed, 2 = not encrypted, 3 = opens without one
    $probe = Invoke-Qpdf @('--requires-password', $item.FullName)
    if ($probe.Code -eq 2) {
        if ($probe.Output) {
            Write-Host ("  [FAIL] Could not read PDF: {0}" -f $probe.Output) -ForegroundColor Red
            $failed++
        } else {
            Write-Host '  [SKIP] Not password-protected'
        }
        continue
    }

    $password = $null
    if ($probe.Code -eq 0) {
        for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
            $candidate = Read-Password $item.Name
            if ($candidate -eq '') { break }
            if ((Invoke-Qpdf @('--requires-password', $item.FullName) $candidate).Code -eq 3) {
                $password = $candidate
                break
            }
            Write-Host '  Wrong password.' -ForegroundColor Yellow
        }
        if ($null -eq $password) {
            Write-Host '  [SKIP] No valid password given'
            $failed++
            continue
        }
    } else {
        Write-Host '  Only has an owner password (editing/printing restrictions); removing it.'
        $password = ''
    }

    $out = Join-Path $item.DirectoryName ($item.BaseName + '-unlocked.pdf')
    $n = 2
    while (Test-Path -LiteralPath $out) {
        $out = Join-Path $item.DirectoryName ('{0}-unlocked ({1}).pdf' -f $item.BaseName, $n)
        $n++
    }
    $temp = $out + '.partial'

    try {
        # Keep the file's structure as-is: no recompression, same object streams, keep
        # unreferenced objects, and keep fast-web-view linearization if the original had it.
        $qargs = @('--decrypt', '--stream-data=preserve', '--object-streams=preserve', '--preserve-unreferenced')
        $lin = Invoke-Qpdf @('--check-linearization', $item.FullName) $password
        if ($lin.Code -eq 0 -and $lin.Output -notmatch 'not linearized') { $qargs += '--linearize' }

        $result = Invoke-Qpdf ($qargs + @($item.FullName, $temp)) $password
        # Exit 3 means qpdf succeeded but warned about something (usually minor damage it repaired).
        if ($result.Code -ne 0 -and $result.Code -ne 3) { throw $result.Output }
        if ($result.Code -eq 3) { Write-Host ("  [WARN] {0}" -f $result.Output) -ForegroundColor Yellow }

        if ((Invoke-Qpdf @('--is-encrypted', $temp)).Code -ne 2) { throw 'Output is still encrypted' }
        $check = Invoke-Qpdf @('--check', $temp)
        if ($check.Code -ne 0 -and $check.Code -ne 3) { throw ("Output failed qpdf --check: {0}" -f $check.Output) }

        Move-Item -LiteralPath $temp -Destination $out
        $outItem = Get-Item -LiteralPath $out
        $outItem.CreationTime = $item.CreationTime
        $outItem.LastWriteTime = $item.LastWriteTime
        Write-Host ("  [OK] {0}" -f $outItem.Name)
    } catch {
        Write-Host ("  [FAIL] {0}" -f $_.Exception.Message) -ForegroundColor Red
        $failed++
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
        $password = $null
    }
}

Write-Host ''
if ($failed -gt 0) {
    Write-Host ("Done with {0} problem(s)." -f $failed)
    exit 1
}
Write-Host 'Done.'
exit 0
