My configuration for mpv. Note that this is a setup used and written by a video encoder, so some stuff some users might prefer (like overlaid static noise or automatic debanding on every source) are either not included, commented out, or bound to a toggle. Feel free to modify this to your liking, including uncommenting or changing settings however you please.

By default FSRCNN and Krigbilateral are used for upscaling. If you notice heavy frame drops, please comment the imports for those and uncomment ravu-r3 instead.

## Included shaders/scripts:

* [acompressor](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/acompressor.lua)
* [autocrop](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autocrop.lua)
* [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)
* [auto-profiles](https://github.com/wiiaboo/mpv-scripts/blob/master/auto-profiles.lua)
* [boss-key](https://github.com/detuur/mpv-scripts)
* [playlistmanager](https://github.com/jonniek/mpv-playlistmanager)
* [reload](https://github.com/4e6/mpv-reload)
* [repl](https://github.com/rossy/mpv-repl)
* [status-line](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/status-line.lua)
* [visualizer](https://github.com/mfcc64/mpv-scripts/blob/master/visualizer.lua)


* [FSRCNN](https://github.com/igv/FSRCNN-TensorFlow/releases)
* [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)
* [Static Noise Luma](https://pastebin.com/yacMe6EZ)
* [ravu-r3](https://github.com/bjin/mpv-prescalers)

## How to install:

**Windows:**<br>
Create a new folder in `%appdata%/Roaming` and call it mpv. <br>Dump the contents of this directory in there. <br>Change the paths as necessary in `mpv.conf`

**Linux:**<br>
TBA

## Dependencies:

* [Youtube-dl](https://github.com/ytdl-org/youtube-dl)
* [Gandhi Sans](https://www.fontsquirrel.com/fonts/gandhi-sans) and [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)

For additional shaders and scripts, check out the following sources:
* [Shaders](https://github.com/mpv-player/mpv/wiki/User-Scripts#user-shaders)
* [Scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts#lua-scripts)