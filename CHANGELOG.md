# Changelog

## 2026-10-31

A reliability pass over every script, plus two new tools and a setup script.

### Added

- **`_setup.bat`**: one-time interactive setup for new users.
  - Pick which tools to keep. All are on by default. Type numbers or ranges (e.g. `3 7 12` or `4-9`) to toggle; `A` turns all on, `N` turns all off.
  - Turned-off tools move to a `disabled\` folder. Run setup again to bring them back.
  - Installs only the programs the chosen tools need, using winget: FFmpeg, ImageMagick, Pandoc, 7-Zip, qpdf, and Python + transparent-background for `remove-bg`. Skips anything already installed.
- **`pdf-unlock.bat`**: removes the password from PDFs.
  - Asks for the password with hidden input; 3 tries, Enter to skip.
  - Removes edit/print restrictions from PDFs that open without a password.
  - Writes `name-unlocked.pdf` and never touches the original.
  - Uses qpdf, so nothing is re-rendered or recompressed. The file's dates are copied to the new file.
  - The password goes to qpdf through standard input, never on the command line.
  - Note: unlocking makes any digital signature show as invalid.
- **Embedded PowerShell**: `file-dedup`, `vid-compress`, `to-bw`, `pdf-unlock` and `_setup` carry PowerShell code inside the `.bat`, below a `#__POWERSHELL__` line. Every tool is still one self-contained file. The batch part runs that code from a temporary copy, which is deleted afterwards.

### Changed (all scripts)

- **Windows close by themselves on success.** They stay open only when something failed or nothing was dropped. `file-dedup` still always pauses, since its report is the output.
- **Exit codes are reliable**: 0 on success, 1 on any failure.
- **Filenames with `( ) & ! % ^` work.** Before, a name like `photo (1).jpg` broke the script, and `!` was silently dropped from names.
- **Folders dropped onto file scripts are skipped** instead of erroring.
- **ffmpeg calls use `-nostdin`**, so a stray key press can't interrupt an encode.

### Fixed

- **`file-dedup`**:
  - It ran every scanned file as a program, because of an unescaped `|`.
  - Its hash parsing returned nothing, so it never found a duplicate.
  - Rewritten in PowerShell: only files that share a size are hashed, overlapping drops aren't counted twice, empty files are ignored, and it reports how much space you'd get back.
- **`vid-compress`**:
  - Could run up to 7 full encodes, and crashed on a failed encode or on files over 2 GB.
  - Now does one CRF 23 encode; if that's over 60 MB, it does an exact 2-pass encode sized from the video's length.
  - Portrait video is capped at 1080 px wide (was 1920).
  - Temp files are always cleaned up.
- **`to-jpg`, `img-strip`**: photos came out sideways, because orientation data was stripped without rotating the image first.
- **`to-jpg`, `img-strip`, `img-optim`**: transparent areas turned black. They're now flattened onto white.
- **ImageMagick scripts**: `%d` or `%x` in a filename was expanded into a number (`copy%x.png` became `copy0.png`). Names are now used as given.
- **`to-mp4`**:
  - Odd pixel dimensions failed with libx264; they're now rounded to even sizes.
  - Output is forced to `yuv420p`, so 10-bit sources play everywhere.
  - All audio tracks are kept.
  - No longer pauses after every failed file.
- **`concat-audio`**: each file is converted to a common WAV first, so mixed formats and sample rates join cleanly, and apostrophes and non-English characters in names no longer break the file list. Album art no longer causes failures.
- **`dir-to-zip`**:
  - Uses .NET `ZipFile` instead of `Compress-Archive`: hidden files are now included and files over 2 GB work.
  - Names containing `'` or `[ ]` no longer break it.
  - A half-written zip is deleted on failure.
- **`dir-to-7z`**:
  - A half-written archive is deleted on failure. Before, the leftover file blocked the next attempt.
  - When 7-Zip skips files (exit code 1), you now get a warning instead of a silent "OK".
  - Also finds 7-Zip on PATH.
  - Removed the `-r` flag, which conflicted with the folder wildcard.
- **`flush-dns`, `restart-winnat`**: now show the UAC prompt themselves instead of telling you to re-run as admin. The admin check uses `fltmc` (`net session` failed when the Server service was off), and a guard stops it looping if elevation fails.
- **`img-optim`**:
  - Uses ImageMagick's `jpeg:extent=200KB` instead of a slow quality-retry loop.
  - Each file's `resized\` folder is next to that file. Before, everything went next to the first file dropped.
  - No longer crashes when the output is missing.
- **`img-strip`**:
  - ExifTool is now optional; ImageMagick's `-strip` already removes metadata. It used to stop with an error when ExifTool wasn't installed.
  - The random filename can't collide with an existing file.
- **`remove-bg`**: uses `transparent-background` from PATH by default. Set `VENV` at the top of the script to use a virtual environment instead; the old hard-coded placeholder path failed for everyone.
- **`to-md`**:
  - Dropped `.doc` and `.pdf`, which Pandoc can't read.
  - Added `.pptx`, `.xlsx`, `.ipynb`, `.org`, `.typ` and `.wiki`.
  - Each extension now passes its input format to Pandoc explicitly.
  - Pandoc's error messages are no longer hidden.
- **`hdr-to-sdr`**:
  - Maps only the main video and audio tracks; subtitle and data tracks made the ProRes MOV fail.
  - Outputs `yuv422p10le`, which ProRes HQ uses natively.
- **`to-64x64`**: paths with spaces broke (double quoting). Also added the missing FFmpeg check.
- **`to-favicon`**: added the missing ImageMagick check and error handling.
- **`vid-to-gif`**:
  - No longer upscales small videos.
  - Skips `.gif` inputs, which were overwriting themselves.
  - Temp palette names are now unique.
- **`to-webp-sm`**: no longer upscales images narrower than 700 px.
- **`to-webp`, `to-webp-sm`, `to-64x64`**: use only the first frame of animated or multi-frame input.
- **`to-png`, `to-jpg`, `trim-png`, `to-favicon`, `img-optim`, `img-4k-bg`, `img-strip`**: use only the first frame of multi-frame input. For example, an animated GIF dropped on `to-png` gives one PNG instead of dozens. `to-bw` still keeps all frames.
- **`to-mp3`**: maps the first audio track explicitly.
- **`to-bw`**: moved to PowerShell, with a file picker when you double-click it without dropping files.
