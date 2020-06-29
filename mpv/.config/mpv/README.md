My configuration for mpv. Note that this is a setup used and written by a video encoder, so some stuff some users might prefer (like overlaid static noise or automatic debanding on every source) are either not included, commented out, or bound to a toggle. Feel free to modify this to your liking, including uncommenting or changing settings however you please.

By default FSRCNN and KrigBilateral are used for upscaling the luma and chroma respectively. If you notice heavy frame drops, please comment the imports for those and uncomment ravu-r3 instead.

## How to install

**Windows:**

1) Create a new folder in `%appdata%/Roaming` and call it mpv.
2) Dump the contents of this directory in there.
3) Change the paths as necessary in `mpv.conf`.
4) Install any additional third-party dependencies.

**Linux:**

* TBA

## Additional Third-Party Dependencies

* [Gandhi Sans](https://www.fontsquirrel.com/fonts/gandhi-sans)
* [Kagefunc](https://github.com/Irrational-Encoding-Wizardry/kagefunc)
* [lvsfunc](https://github.com/Irrational-Encoding-Wizardry/lvsfunc)
* [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)
* [VapourSynth](http://www.vapoursynth.com/)
* [vsutil](https://github.com/Irrational-Encoding-Wizardry/vsutil)
* [youtube-dl](https://github.com/ytdl-org/youtube-dl/releases)

## Included Third-Party Shaders/Scripts

* [acompressor](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/acompressor.lua)
* [auto-profiles](https://github.com/wiiaboo/mpv-scripts/blob/master/auto-profiles.lua)
* [autocrop](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autocrop.lua)
* [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)
* [boss-key](https://github.com/detuur/mpv-scripts)
* [playlistmanager](https://github.com/jonniek/mpv-playlistmanager)
* [reload](https://github.com/4e6/mpv-reload)
* [repl](https://github.com/rossy/mpv-repl)
* [sponsorblock](https://github.com/po5/mpv_sponsorblock)
* [status-line](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/status-line.lua)
* [visualizer](https://github.com/mfcc64/mpv-scripts/blob/master/visualizer.lua)
<br><br>
* [FSRCNN](https://github.com/igv/FSRCNN-TensorFlow/releases)
* [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)
* [ravu-r3](https://github.com/bjin/mpv-prescalers)
* [Static Noise Luma](https://pastebin.com/yacMe6EZ)

*For additional shaders and scripts, check out the following sources:*

* [Scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts#lua-scripts)
* [Shaders](https://github.com/mpv-player/mpv/wiki/User-Scripts#user-shaders)
