My configuration for mpv. Note that this is a setup used and written by a video encoder, so some stuff some users might prefer (like overlaid static noise or automatic debanding on every source) are either not included, commented out, or bound to a toggle. Feel free to modify this to your liking, including uncommenting or changing settings however you please.

By default FSRCNNX is used for upscaling. If you notice heavy frame drops, please comment the import and uncomment ravu-r3 instead.

YouTube-DL is not included. You can install it from its official repository. Link below.

The included updater.bat is taken from [shinchiro's SourceForge build of mpv](https://sourceforge.net/projects/mpv-player-windows/files/). It does not update the mpv.conf, but instead mpv itself. I highly suggest updating as frequently as possible.

## How to install the base setup:

**Windows:**<br>
1) Create a new folder in `%appdata%` and call it mpv. <br>
2) Dump the contents of this directory in there. <br>
3) Change the paths as necessary in `mpv.conf`.<br>
4) **OPTIONAL:** Run `updater.bat` as Administrator to update your mpv.

**Linux:**<br>
TBA


## How to install VapourSynth and the filtering dependencies:
1) Install the [latest version of VapourSynth](https://github.com/vapoursynth/vapoursynth/releases).<br>
1.5. Install the latest required version of [Python](https://www.python.org/downloads/), and make sure it's added to PATH.<br>
2) Locate the following directories:<br>
 \* C:\Users\[your username]\AppData\Roaming\VapourSynth\plugins64<br>
 \* C:\Users\[your username]\AppData\Local\Programs\Python\Python38\Lib\site-packages<br>
3) Check the .vpy scripts in the repo (in the `vs` directory) and follow the links to the listed dependencies.
4) Download and move the required files to the relevant directories (Python modules go to the `site-packages` directory, everything else goes in the `plugins64` directory).
5) Verify that the scripts are running as intended by cycling through the profiles and pressing the `~` key during playback. It should tell you if it failed, and if it did what the missing dependencies are.


## Dependencies:

* [Youtube-dl](https://github.com/ytdl-org/youtube-dl/releases)
* [Gandhi Sans](https://www.fontsquirrel.com/fonts/gandhi-sans) and [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)

*Optional: VapourSynth scripts*
* [VapourSynth](https://github.com/vapoursynth/vapoursynth/releases)
* [awarpSharp2](https://github.com/dubhater/vapoursynth-awarpsharp2/releases/tag/v4)
* [havsfunc](https://github.com/HomeOfVapourSynthEvolution/havsfunc/releases)
* [lvsfunc](https://pypi.org/project/lvsfunc/)
* [NNEDI3CL](https://github.com/HomeOfVapourSynthEvolution/VapourSynth-NNEDI3CL/releases)
* [vs-placebo](https://github.com/Lypheo/vs-placebo/releases)
* [vsutil](https://pypi.org/project/vsutil/)

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
* [visualizer](https://github.com/mfcc64/mpv-scripts/blob/master/visualizer.lua)<br><br>
* [FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)
* [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)
* [nnedi3]((https://github.com/bjin/mpv-prescalers))
* [ravu-r3](https://github.com/bjin/mpv-prescalers)
* [Static Noise Luma](https://pastebin.com/yacMe6EZ)


Other:
* [Shinchiro's mpv updater](https://sourceforge.net/projects/mpv-player-windows/files/)

*For additional shaders and scripts, check out the following sources:*
* [mpv shaders](https://github.com/mpv-player/mpv/wiki/User-Scripts#user-shaders)
* [mpv scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts#lua-scripts)
* [VapourSynth scripts](https://github.com/LightArrowsEXE/Encoding-Projects/)