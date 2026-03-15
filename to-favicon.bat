@echo off
for %%F in (%*) do (
    if not exist "%%~dpF\favicons" mkdir "%%~dpF\favicons"
    magick "%%~F" -resize 64x64 -background transparent -gravity center -extent 64x64 "%%~dpF\favicons\%%~nF_favicon.ico"
    echo Done: %%~nF_favicon.ico
)
pause