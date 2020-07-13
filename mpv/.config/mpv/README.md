My configuration for mpv. Note that this is a setup used and written by a video encoder, so some stuff some users might prefer (like overlaid static noise or automatic debanding on every source) are either not included, commented out, or bound to a toggle. Feel free to modify this to your liking, including uncommenting or changing settings however you please.

By default FSRCNNX is used for upscaling. If you notice heavy frame drops, please comment the import and uncomment ravu-r3 instead.

YouTube-DL is not included. You can install it from its official repository. Link below.

The included updater.bat is taken from [shinchiro's SourceForge build of mpv](https://sourceforge.net/projects/mpv-player-windows/files/). It does not update the mpv.conf, but instead mpv itself. I highly suggest updating as frequently as possible.

## How to install:

**Windows:**<br>
Create a new folder in `%appdata%/Roaming` and call it mpv. <br>
Dump the contents of this directory in there. <br>
Change the paths as necessary in `mpv.conf`.<br>
**OPTIONAL:** Run `updater.bat` as Administrator to update your mpv.

**Linux:**<br>
TBA

## Dependencies:

* [Youtube-dl](https://github.com/ytdl-org/youtube-dl/releases)
* [Gandhi Sans](https://www.fontsquirrel.com/fonts/gandhi-sans) and [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)

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


* [FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)
* [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)
* [Static Noise Luma](https://pastebin.com/yacMe6EZ)
* [ravu-r3](https://github.com/bjin/mpv-prescalers)


Other:
* [Shinchiro's mpv updater](https://sourceforge.net/projects/mpv-player-windows/files/)

*For additional shaders and scripts, check out the following sources:*
* [Shaders](https://github.com/mpv-player/mpv/wiki/User-Scripts#user-shaders)
* [Scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts#lua-scripts)