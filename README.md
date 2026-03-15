# 🗂️ Desktop Scripts

> Drag-and-drop Windows batch scripts for everyday media tasks.
> Drop files onto any script — no terminal required.

![Platform](https://img.shields.io/badge/platform-Windows-0078D4?logo=windows&logoColor=white)
![Scripts](https://img.shields.io/badge/scripts-24-5db92c)
![License](https://img.shields.io/badge/license-free%20to%20use-1b4d3e)

A collection of `.bat` scripts for converting, compressing, and cleaning up files. Each one is self-contained — download whichever you need, install the corresponding tool, and start dragging files onto it.

---

## Contents

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

## How to Use

1. **Install** the tool(s) required by the script (see [Prerequisites](#prerequisites))
2. **Download** the `.bat` file to your desktop or a dedicated scripts folder
3. **Drag and drop** your files — or folders — onto the `.bat` file
4. A console window opens, processes your files, and pauses so you can read the output
5. Output appears alongside your originals, or in a named subfolder where noted

> **Tip:** Most scripts skip files they don't need to process (e.g. if the file is already in the target format). It's safe to drop mixed batches.

---

## Prerequisites

You only need to install tools for the scripts you actually use.

Most tools need to be on your system **PATH**. To add a tool: search **Edit the system environment variables** in Windows → Environment Variables → add the tool's folder to **Path** under System variables.

| Tool | Install | Used by |
|---|---|---|
| [FFmpeg](https://ffmpeg.org/download.html) | Add `ffmpeg.exe` to PATH | Audio, video & image scripts |
| [ImageMagick](https://imagemagick.org/script/download.php) | Install; add `magick` to PATH | Image editing scripts |
| [ExifTool](https://exiftool.org/) | Add `exiftool.exe` to PATH | `img-strip.bat` |
| [Pandoc](https://pandoc.org/installing.html) | Add `pandoc` to PATH | `to-md.bat` |
| [7-Zip](https://www.7-zip.org/download.html) | Standard installer (auto-detected) | `dir-to-7z.bat` |
| Python + [transparent-background](https://pypi.org/project/transparent-background/) | `pip install transparent-background` in a venv | `remove-bg.bat` |

---

## Scripts

---

### 🎬 Audio & Video

#### `concat-audio.bat`
**Joins multiple audio files into a single MP3, in the order they were dropped.**

- **Needs:** FFmpeg
- **Relevant to:** Podcasters, audiobook creators, anyone stitching together recordings
- **Example:** Merge three recorded interview segments into one final episode file
- **Output:** Timestamped `.mp3` file alongside the first dropped file

#### `to-mp3.bat`
**Converts any audio or video file to high-quality MP3 (VBR ~190 kbps). Skips existing MP3s.**

- **Needs:** FFmpeg
- **Relevant to:** Musicians, students, commuters building offline audio libraries
- **Example:** Convert a folder of downloaded video lectures to MP3 for audio-only playback
- **Output:** `.mp3` file alongside the source

#### `to-mp4.bat`
**Re-encodes video to H.264 MP4 at CRF 18 with AAC audio and web-optimised faststart. Skips existing MP4s.**

- **Needs:** FFmpeg
- **Relevant to:** Video editors and content creators sharing footage online
- **Example:** Convert a ProRes export into a shareable, streamable MP4 for client delivery
- **Output:** `.mp4` file alongside the source

#### `vid-compress.bat`
**Iteratively compresses video to a ~60 MB target, scaling resolution if needed. Saves as `*_small.mp4`.**

- **Needs:** FFmpeg
- **Relevant to:** Anyone uploading video to services with file-size limits (email, WhatsApp, web forms)
- **Example:** Shrink a 400 MB screen recording to under 60 MB to attach to a bug report
- **Output:** `*_small.mp4` alongside the source

#### `vid-to-gif.bat`
**Converts a short video clip to an optimised animated GIF at 15 fps and max 640 px wide.**

- **Needs:** FFmpeg
- **Relevant to:** Designers, developers, and social media users needing short looping animations
- **Example:** Turn a 10-second UI interaction recording into a GIF for a GitHub README
- **Output:** `.gif` alongside the source

#### `hdr-to-sdr.bat`
**Tone-maps HDR (HLG or PQ) video to SDR using the Hable algorithm. Outputs ProRes MOV.**

- **Needs:** FFmpeg
- **Relevant to:** Videographers editing HDR footage from phones or cameras in older NLEs
- **Example:** Convert a Dolby Vision iPhone clip to SDR ProRes for import into an older editing suite
- **Output:** `*_sdr.mov` alongside the source

---

### 🖼️ Image Conversion

#### `to-jpg.bat`
**Converts any image to JPG at 100% quality, stripping EXIF metadata. Skips existing JPGs.**

- **Needs:** ImageMagick
- **Relevant to:** Designers, photographers, and developers working with mixed image formats
- **Example:** Convert a batch of PNGs from a design export to JPG for a web asset folder
- **Output:** `.jpg` alongside the source

#### `to-png.bat`
**Converts any image to lossless PNG with transparency support. Skips existing PNGs.**

- **Needs:** ImageMagick
- **Relevant to:** Developers and designers needing lossless images with alpha channels
- **Example:** Convert a set of JPG screenshots to PNG for a documentation site
- **Output:** `.png` alongside the source

#### `to-webp.bat`
**Converts images to WebP at 90% quality for excellent web compression. Skips existing WebPs.**

- **Needs:** FFmpeg
- **Relevant to:** Web developers and designers optimising images for faster page loads
- **Example:** Convert a directory of product photos to WebP before deploying a website
- **Output:** `.webp` alongside the source

#### `to-webp-sm.bat`
**Converts images to WebP and scales down to a max of 700 px wide. Adds a `-sm` suffix.**

- **Needs:** FFmpeg
- **Relevant to:** Bloggers and content managers who need web-ready thumbnail images
- **Example:** Batch-resize and convert full-resolution photos to WebP thumbnails for a gallery
- **Output:** `*-sm.webp` alongside the source

#### `to-64x64.bat`
**Resizes any image to exactly 64×64 pixels as an RGBA PNG. Adds a `_64x64` suffix.**

- **Needs:** FFmpeg
- **Relevant to:** Developers creating game sprites, app icons, or small UI assets
- **Example:** Batch-convert character illustrations to 64×64 PNG sprites for a 2D game
- **Output:** `*_64x64.png` alongside the source

#### `to-bw.bat`
**Desaturates images to greyscale while keeping the original file format. Adds a `-bw` suffix.**

- **Needs:** ImageMagick
- **Relevant to:** Photographers, designers, and print artists needing quick greyscale conversions
- **Example:** Convert a set of portrait photos to B&W for a print layout
- **Output:** `*-bw.[ext]` alongside the source

---

### ✨ Image Enhancement

#### `img-optim.bat`
**Iteratively reduces quality until the file is under 200 KB. Max 1920 px tall. Saves to `resized/`.**

- **Needs:** ImageMagick
- **Relevant to:** Web developers and content managers uploading images to CMSes with file size limits
- **Example:** Prepare a batch of high-resolution product photos for upload to Webflow or WordPress
- **Output:** Optimised file inside `resized/` next to the source

#### `img-strip.bat`
**Strips all EXIF metadata (GPS, device info, timestamps) and renames the file to a random 12-character string.**

- **Needs:** ExifTool + ImageMagick
- **Relevant to:** Privacy-conscious users sharing photos publicly or submitting images anonymously
- **Example:** Anonymise photos before posting to a public forum or sending to an unknown recipient
- **Output:** Random-named `.jpg` alongside the source

#### `img-4k-bg.bat`
**Creates a 3840×3840 square image with the original centred on a blurred, darkened version of itself.**

- **Needs:** ImageMagick
- **Relevant to:** Social media creators and designers who need square wallpapers or post backgrounds
- **Example:** Turn a portrait photo into a square Instagram post with an aesthetic blurred backdrop
- **Output:** `*-4k-landscape.jpg` alongside the source

#### `trim-png.bat`
**Removes uniform border whitespace or transparency from PNG files. Adds a `-trimmed` suffix.**

- **Needs:** ImageMagick
- **Relevant to:** Designers and developers cleaning up exported icons, logos, or diagrams
- **Example:** Remove the transparent padding around exported Figma icons before using them in code
- **Output:** `*-trimmed.png` alongside the source

#### `to-favicon.bat`
**Generates a 64×64 pixel `.ico` favicon from any image. Saves to a `favicons/` subfolder.**

- **Needs:** ImageMagick
- **Relevant to:** Web developers and designers adding favicons to a new project
- **Example:** Turn a high-resolution logo PNG into a browser favicon in one step
- **Output:** `*_favicon.ico` inside `favicons/` next to the source

---

### 🤖 AI Tools

#### `remove-bg.bat`
**Removes image backgrounds using an AI segmentation model (InSPyReNet). Outputs transparent RGBA PNG.**

- **Needs:** Python + [transparent-background](https://pypi.org/project/transparent-background/) in a virtual environment
- **Relevant to:** Designers, e-commerce sellers, and content creators who need clean product cutouts
- **Example:** Cut product photos from their backgrounds to place on a white backdrop for an online store
- **Output:** Transparent `.png` inside `removed-bg/` next to the source

**Setup:** Before use, open `remove-bg.bat` and edit line 5 to point to your virtual environment:

```batch
call "C:\path\to\your\bgremove-venv\Scripts\activate.bat"
```

Create and set up the environment:

```bash
python -m venv bgremove-venv
bgremove-venv\Scripts\activate
pip install transparent-background
```

---

### 📄 Documents

#### `to-md.bat`
**Converts Word docs, HTML, EPUB, RTF, PDF and other formats to clean Markdown. Saves to `markdown_output/`.**

Supported input formats: `.docx`, `.doc`, `.html`, `.htm`, `.epub`, `.odt`, `.rtf`, `.tex`, `.rst`, `.textile`, `.mediawiki`, `.pdf`

- **Needs:** Pandoc
- **Relevant to:** Writers, developers, and knowledge managers who want content in portable plain text
- **Example:** Convert a Word document client brief into Markdown for a static site or knowledge base
- **Output:** `.md` file inside `markdown_output/` next to the source

---

### 📦 Compression

#### `dir-to-zip.bat`
**Compresses each dropped folder to a ZIP archive using PowerShell's built-in Compress-Archive. Skips existing ZIPs.**

- **Needs:** Nothing (uses built-in PowerShell)
- **Relevant to:** Anyone who needs to quickly archive and share folders
- **Example:** Zip a client project folder before uploading it to cloud storage for delivery
- **Output:** `foldername.zip` alongside the dropped folder

#### `dir-to-7z.bat`
**Compresses folders to 7Z format with medium compression (`-mx=5`). Skips existing archives.**

- **Needs:** [7-Zip](https://www.7-zip.org/download.html) (auto-detected from default install location)
- **Relevant to:** Power users who prefer 7Z for better compression ratios than ZIP
- **Example:** Archive large asset folders with better compression for long-term storage
- **Output:** `foldername.7z` alongside the dropped folder

---

### 🗂️ File Utilities

#### `file-dedup.bat`
**Computes SHA-256 hashes for all dropped files and reports any that share the same hash — exact duplicates.**

- **Needs:** Nothing (uses Windows built-in `certutil`)
- **Relevant to:** Anyone cleaning up cluttered downloads, photo libraries, or backup folders
- **Example:** Drop a collection of photos to find which ones are duplicates saved under different filenames
- **Output:** Duplicate report printed to the console

---

### 🌐 Network & System

#### `flush-dns.bat`
**Clears the Windows DNS resolver cache.**

> ⚠️ Requires Administrator privileges. Right-click → *Run as administrator*.

- **Needs:** Nothing (uses Windows built-in `ipconfig`)
- **Relevant to:** Developers and sysadmins troubleshooting DNS propagation or after updating domain records
- **Example:** After changing a domain's DNS settings, force Windows to pick up the new records immediately

#### `restart-winnat.bat`
**Stops and restarts the Windows NAT (winnat) service.**

> ⚠️ Requires Administrator privileges. Right-click → *Run as administrator*.

- **Needs:** Nothing (uses Windows built-in `net`)
- **Relevant to:** Developers using Docker Desktop, WSL2, or Hyper-V who experience networking conflicts
- **Example:** Fix WSL2 or Docker networking after a "port already in use" error caused by WinNAT

---

## Notes

- Scripts that produce output files **never overwrite** an existing file — they skip with a notice instead.
- Output subfolders (`resized/`, `removed-bg/`, `markdown_output/`, `favicons/`) are created automatically next to the source file.
- The system scripts (`flush-dns.bat`, `restart-winnat.bat`) must be run as Administrator — they check for this on launch and exit with an error message if not elevated.
- `remove-bg.bat` requires editing one line before first use (see setup instructions above).

---

## License

Free to use and modify. No warranty. Attribution appreciated but not required.
