# 🗂️ Desktop Scripts

> Drag-and-drop Windows scripts for everyday media tasks.
> Drop files onto any script, no terminal required.

![Platform](https://img.shields.io/badge/platform-Windows-0078D4?logo=windows&logoColor=white)
![Scripts](https://img.shields.io/badge/scripts-25-5db92c)
![License](https://img.shields.io/badge/license-free%20to%20use-1b4d3e)

A collection of scripts for converting, compressing, and cleaning up files. Run the setup once, then drag files or folders onto any script.

---

## Contents

- [Quick Start](#quick-start)
- [How to Use](#how-to-use)
- [Prerequisites](#prerequisites)
- [Scripts](#scripts)
  - [🎬 Audio & Video](#-audio--video)
  - [🖼️ Image Conversion](#️-image-conversion)
  - [✨ Image Enhancement](#-image-enhancement)
  - [🤖 AI Tools](#-ai-tools)
  - [📄 Documents](#-documents)
  - [📦 Compression](#-compression)
  - [🗂️ File Utilities](#️-file-utilities)
  - [🌐 Network & System](#-network--system)
- [Notes](#notes)

---

## Quick Start

1. **Download** this repository (Code → Download ZIP) and extract it anywhere, such as your desktop.
2. **Double-click `_setup.bat`.**
3. **Choose your tools.** All of them are on by default. Type numbers to toggle tools (e.g. `3 7 12` or `4-9`), `A` for all, `N` for none, then press **Enter**.
4. **Confirm.** Setup installs only the programs your chosen tools need, using winget, and skips anything already installed.

Tools you turn off are moved into a `disabled` folder, not deleted. Run `_setup.bat` again at any time to change your choices.

> If a script says a program is "not found" right after setup, sign out of Windows and back in once so the new PATH is picked up.

---

## How to Use

1. **Drag and drop** files or folders onto a script.
2. A console window opens and processes each item.
3. **On success, the window closes by itself.** If anything failed, it stays open so you can read the error.
4. Output appears next to your originals, or in a named subfolder where noted.

> **Tip:** Scripts skip files they don't need to process (e.g. a file already in the target format, or a folder dropped on a file script). It's safe to drop mixed batches.

Double-clicking a script without dropping anything shows a short usage message. `to-bw.bat` opens a file picker instead.

---

## Prerequisites

`_setup.bat` installs all of these for you. To install them by hand, you only need the tools for the scripts you use.

| Tool | winget ID | Used by |
|---|---|---|
| [FFmpeg](https://ffmpeg.org/download.html) | `Gyan.FFmpeg` | Audio, video & some image scripts |
| [ImageMagick](https://imagemagick.org/script/download.php) | `ImageMagick.ImageMagick` | Image editing scripts |
| [Pandoc](https://pandoc.org/installing.html) | `JohnMacFarlane.Pandoc` | `to-md.bat` |
| [7-Zip](https://www.7-zip.org/download.html) | `7zip.7zip` | `dir-to-7z.bat` |
| [qpdf](https://github.com/qpdf/qpdf) | `QPDF.QPDF` | `pdf-unlock.bat` |
| Python + [transparent-background](https://pypi.org/project/transparent-background/) | `Python.Python.3.12`, then `pip install transparent-background` | `remove-bg.bat` |
| [ExifTool](https://exiftool.org/) *(optional)* | `OliverBetz.ExifTool` | `img-strip.bat` (extra metadata pass) |

FFmpeg, ImageMagick and Pandoc must be on your **PATH**; their installers add themselves. 7-Zip and qpdf are found in their default install folders even when they aren't on PATH.

> Every tool is a single `.bat` file, so you can copy just the ones you want. A few (`_setup`, `file-dedup`, `pdf-unlock`, `to-bw`, `vid-compress`) carry PowerShell code inside them, below a `#__POWERSHELL__` line. The batch part at the top runs it from a temporary copy.

---

## Scripts

---

### 🎬 Audio & Video

#### `concat-audio.bat`
**Joins multiple audio files into a single 192 kbps MP3.**

Files can be in different formats and sample rates; each is converted to a common format before joining. Files are joined in the order Windows passes them, which usually starts with the file you dragged by.

- **Needs:** FFmpeg
- **Relevant to:** Podcasters, audiobook creators, anyone stitching together recordings
- **Example:** Merge three recorded interview segments into one final episode file
- **Output:** `concatenated_<timestamp>.mp3` next to the first dropped file

#### `to-mp3.bat`
**Extracts the audio from any audio or video file as high-quality MP3 (VBR ~190 kbps). Skips existing MP3s.**

- **Needs:** FFmpeg
- **Relevant to:** Musicians, students, commuters building offline audio libraries
- **Example:** Convert a folder of downloaded video lectures to MP3 for audio-only playback
- **Output:** `.mp3` next to the source

#### `to-mp4.bat`
**Re-encodes video to H.264 MP4 (CRF 18, `yuv420p`) with AAC audio and web-optimised faststart. Skips existing MP4s.**

Keeps all audio tracks, drops subtitle and data tracks that MP4 can't hold, and rounds odd dimensions to even so any source works.

- **Needs:** FFmpeg
- **Relevant to:** Video editors and content creators sharing footage online
- **Example:** Convert a ProRes export or MKV into a shareable, streamable MP4
- **Output:** `.mp4` next to the source

#### `vid-compress.bat`
**Compresses video to fit under ~60 MB. Saves as `*_small.mp4`.**

Tries a CRF 23 encode first. If the result is still too big, it calculates the exact bitrate from the video's length and does a 2-pass encode. Resolution is capped at 1080p on the short side.

- **Needs:** FFmpeg
- **Relevant to:** Anyone uploading video to services with file-size limits (email, WhatsApp, web forms)
- **Example:** Shrink a 400 MB screen recording to under 60 MB to attach to a bug report
- **Output:** `*_small.mp4` next to the source

#### `vid-to-gif.bat`
**Converts a video clip to an optimised animated GIF at 15 fps and at most 640 px wide.**

- **Needs:** FFmpeg
- **Relevant to:** Designers, developers, and social media users needing short looping animations
- **Example:** Turn a 10-second UI interaction recording into a GIF for a GitHub README
- **Output:** `.gif` next to the source

#### `hdr-to-sdr.bat`
**Tone-maps HDR (HLG or PQ) video to SDR using the Hable algorithm. Outputs ProRes 422 HQ MOV.**

The source must be tagged as HDR; plain SDR video will fail.

- **Needs:** FFmpeg
- **Relevant to:** Videographers editing HDR footage from phones or cameras in older NLEs
- **Example:** Convert an HDR iPhone clip to SDR ProRes for import into an older editing suite
- **Output:** `*_sdr.mov` next to the source

---

### 🖼️ Image Conversion

#### `to-jpg.bat`
**Converts any image to JPG at 100% quality, stripping metadata. Skips existing JPGs.**

Photos are rotated upright before the orientation data is removed, and transparent areas become white.

- **Needs:** ImageMagick
- **Relevant to:** Designers, photographers, and developers working with mixed image formats
- **Example:** Convert a batch of PNGs from a design export to JPG for a web asset folder
- **Output:** `.jpg` next to the source

#### `to-png.bat`
**Converts any image to lossless PNG with transparency support. Skips existing PNGs.**

- **Needs:** ImageMagick
- **Relevant to:** Developers and designers needing lossless images with alpha channels
- **Example:** Convert a set of JPG screenshots to PNG for a documentation site
- **Output:** `.png` next to the source

#### `to-webp.bat`
**Converts images to WebP at 90% quality. Skips existing WebPs.**

- **Needs:** FFmpeg
- **Relevant to:** Web developers and designers optimising images for faster page loads
- **Example:** Convert a directory of product photos to WebP before deploying a website
- **Output:** `.webp` next to the source

#### `to-webp-sm.bat`
**Converts images to WebP, scaling down to at most 700 px wide. Smaller images are not enlarged. Adds a `-sm` suffix.**

- **Needs:** FFmpeg
- **Relevant to:** Bloggers and content managers who need web-ready thumbnail images
- **Example:** Batch-resize and convert full-resolution photos to WebP thumbnails for a gallery
- **Output:** `*-sm.webp` next to the source

#### `to-64x64.bat`
**Resizes any image to exactly 64×64 pixels (nearest-neighbour) as an RGBA PNG. Adds a `_64x64` suffix.**

- **Needs:** FFmpeg
- **Relevant to:** Developers creating game sprites, app icons, or small UI assets
- **Example:** Batch-convert pixel-art illustrations to 64×64 PNG sprites for a 2D game
- **Output:** `*_64x64.png` next to the source

#### `to-bw.bat`
**Desaturates images to greyscale while keeping the original file format, including animated GIFs. Adds a `-bw` suffix.**

Double-click it without dropping anything to pick files from a dialog.

- **Needs:** ImageMagick
- **Relevant to:** Photographers, designers, and print artists needing quick greyscale conversions
- **Example:** Convert a set of portrait photos to B&W for a print layout
- **Output:** `*-bw.[ext]` next to the source

---

### ✨ Image Enhancement

#### `img-optim.bat`
**Resizes images to at most 1920 px tall and saves them as JPG under 200 KB. Saves to `resized/`.**

ImageMagick searches for the highest quality that fits in 200 KB. If an image can't get under it, you get a warning with the final size.

- **Needs:** ImageMagick
- **Relevant to:** Web developers and content managers uploading images to CMSes with file size limits
- **Example:** Prepare a batch of high-resolution product photos for upload to Webflow or WordPress
- **Output:** `.jpg` inside `resized/` next to each source

#### `img-strip.bat`
**Resizes to at most 2048 px, strips all metadata (GPS, device info, timestamps), and renames the file to a random 12-character string.**

Works with `.jpg`, `.jpeg`, `.png` and `.webp`. Photos are rotated upright before the orientation data is removed.

- **Needs:** ImageMagick (ExifTool optional, for an extra metadata pass)
- **Relevant to:** Privacy-conscious users sharing photos publicly or submitting images anonymously
- **Example:** Anonymise photos before posting to a public forum or sending to an unknown recipient
- **Output:** Random-named `.jpg` next to the source; the original is kept

#### `img-4k-bg.bat`
**Creates a 3840×2160 (4K landscape) image with the original centred on a blurred, darkened copy of itself.**

- **Needs:** ImageMagick
- **Relevant to:** Anyone turning portrait or square photos into widescreen wallpapers or video backgrounds
- **Example:** Turn a portrait phone photo into a 4K desktop wallpaper with an aesthetic blurred backdrop
- **Output:** `*-4k-landscape.jpg` next to the source

#### `trim-png.bat`
**Removes uniform borders or transparent padding from PNG files. Adds a `-trimmed` suffix.**

- **Needs:** ImageMagick
- **Relevant to:** Designers and developers cleaning up exported icons, logos, or diagrams
- **Example:** Remove the transparent padding around exported Figma icons before using them in code
- **Output:** `*-trimmed.png` next to the source

#### `to-favicon.bat`
**Generates a 64×64 pixel `.ico` favicon from any image, padded to square. Saves to a `favicons/` subfolder.**

- **Needs:** ImageMagick
- **Relevant to:** Web developers and designers adding favicons to a new project
- **Example:** Turn a high-resolution logo PNG into a browser favicon in one step
- **Output:** `*_favicon.ico` inside `favicons/` next to the source

---

### 🤖 AI Tools

#### `remove-bg.bat`
**Removes image backgrounds using an AI segmentation model (InSPyReNet). Outputs transparent RGBA PNG.**

- **Needs:** Python + [transparent-background](https://pypi.org/project/transparent-background/)
- **Relevant to:** Designers, e-commerce sellers, and content creators who need clean product cutouts
- **Example:** Cut product photos out of their backgrounds to place on a white backdrop for an online store
- **Output:** Transparent `.png` inside `removed-bg/` next to the source

**Setup:** `_setup.bat` installs everything, including PyTorch, which is a large download (around 2–3 GB). The model is downloaded on first use.

To set it up by hand, run `pip install transparent-background`. The script uses `transparent-background` from your PATH. To use a virtual environment instead, set `VENV` near the top of `remove-bg.bat`:

```batch
set "VENV=C:\path\to\your\bgremove-venv"
```

---

### 📄 Documents

#### `to-md.bat`
**Converts Word docs, HTML, EPUB, slides, spreadsheets and other formats to clean Markdown. Saves to `markdown_output/`.**

Supported input formats: `.docx`, `.odt`, `.epub`, `.html`, `.htm`, `.rtf`, `.tex`, `.rst`, `.textile`, `.mediawiki`, `.wiki`, `.org`, `.ipynb`, `.pptx`, `.xlsx`, `.typ`

Pandoc can't read legacy `.doc` or `.pdf` files. Save `.doc` as `.docx` first.

- **Needs:** Pandoc
- **Relevant to:** Writers, developers, and knowledge managers who want content in portable plain text
- **Example:** Convert a Word document client brief into Markdown for a static site or knowledge base
- **Output:** `.md` file inside `markdown_output/` next to the source

#### `pdf-unlock.bat`
**Removes the password from PDFs, leaving everything else in the file exactly as it was.**

- Asks for the password with hidden input. You get 3 tries; press Enter to skip a file.
- PDFs that open without a password but have printing or editing restrictions are unlocked without asking.
- Nothing is re-rendered or recompressed: pages, fonts, images, bookmarks, forms and metadata stay identical. The file's dates are kept.
- The password is passed to qpdf privately, never on its command line.

> ⚠️ A digitally signed PDF will show its signature as invalid after unlocking, because the file has changed.

- **Needs:** qpdf
- **Relevant to:** Anyone who keeps statements, payslips, or tickets that arrive password-protected
- **Example:** Unlock a monthly bank statement so it opens without a prompt and can be merged or annotated
- **Output:** `*-unlocked.pdf` next to the source; the original is never changed

---

### 📦 Compression

#### `dir-to-zip.bat`
**Compresses each dropped folder to a ZIP archive. Includes hidden files and handles files over 2 GB. Skips folders whose ZIP already exists.**

- **Needs:** Nothing (uses built-in .NET compression via PowerShell)
- **Relevant to:** Anyone who needs to quickly archive and share folders
- **Example:** Zip a client project folder before uploading it to cloud storage for delivery
- **Output:** `foldername.zip` next to the dropped folder

#### `dir-to-7z.bat`
**Compresses folders to 7Z format with medium compression (`-mx=5`). Skips folders whose archive already exists.**

If some files are locked and get skipped, you get a warning instead of a silent success.

- **Needs:** [7-Zip](https://www.7-zip.org/download.html) (found in its default install folder or on PATH)
- **Relevant to:** Power users who prefer 7Z for better compression ratios than ZIP
- **Example:** Archive large asset folders with better compression for long-term storage
- **Output:** `foldername.7z` next to the dropped folder

---

### 🗂️ File Utilities

#### `file-dedup.bat`
**Finds exact duplicates among the dropped files and folders (searched recursively) by SHA-256 hash.**

Only files that share a size with another file are hashed, so large folders are fast. Empty files are ignored. The report lists each group of duplicates, largest first, and how much space you'd get back. Nothing is deleted.

- **Needs:** Nothing (uses built-in PowerShell)
- **Relevant to:** Anyone cleaning up cluttered downloads, photo libraries, or backup folders
- **Example:** Drop your Pictures folder to find photos saved twice under different names
- **Output:** Duplicate report printed to the console (this window always stays open)

---

### 🌐 Network & System

#### `flush-dns.bat`
**Clears the Windows DNS resolver cache.**

> Needs administrator rights. The script shows the UAC prompt itself, so just double-click it.

- **Needs:** Nothing (uses Windows built-in `ipconfig`)
- **Relevant to:** Developers and sysadmins troubleshooting DNS propagation or after updating domain records
- **Example:** After changing a domain's DNS settings, force Windows to pick up the new records immediately

#### `restart-winnat.bat`
**Stops and restarts the Windows NAT (winnat) service.**

> Needs administrator rights. The script shows the UAC prompt itself, so just double-click it.

- **Needs:** Nothing (uses Windows built-in `net`)
- **Relevant to:** Developers using Docker Desktop, WSL2, or Hyper-V who experience networking conflicts
- **Example:** Fix WSL2 or Docker networking after a "port already in use" error caused by WinNAT

---

## Notes

- **Existing output is overwritten** by the conversion scripts (e.g. running `to-mp3` twice replaces the first `.mp3`). These never overwrite anything:
  - `dir-to-zip` and `dir-to-7z` skip folders whose archive already exists.
  - `pdf-unlock` numbers its output instead (`-unlocked (2).pdf`).
  - `concat-audio` and `img-strip` always create a new, uniquely named file.
- **The files you drop are never modified.** A conversion can still replace a different file that has the output's name. For example, dropping `photo.png` on `to-jpg` replaces an existing `photo.jpg` in the same folder.
- **Multi-frame images** (animated GIFs, multi-page TIFFs) use only the first frame in the image conversion scripts. `to-bw` keeps every frame.
- **Filenames with spaces and special characters** like `( ) & ! % ^ '` and non-English characters are handled.
- **Output subfolders** (`resized/`, `removed-bg/`, `markdown_output/`, `favicons/`) are created automatically next to each source file.
- **Turned-off tools** live in `disabled/`, which is created by `_setup.bat` and isn't part of the repository.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

## License

Free to use and modify. No warranty. Attribution appreciated but not required.
