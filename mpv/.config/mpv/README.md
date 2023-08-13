My configuration for mpv. Note that this is a setup used and written by a video encoder, so some stuff some users might prefer (like overlaid static noise or automatic debanding on every source) are either not included, commented out, or bound to a toggle. Feel free to modify this to your liking, including uncommenting or changing settings however you please.

By default FSRCNNX is used for upscaling. If you notice heavy frame drops, please comment the import and uncomment ravu-r3 instead.

YouTube-DL is not included. You can install it from its official repository. Link below.

The included updater.bat is taken from [shinchiro's SourceForge build of mpv](https://sourceforge.net/projects/mpv-player-windows/files/). It does not update the mpv.conf, but instead mpv itself. I highly suggest updating as frequently as possible.

## Custom keybinds

-   `k` - Subtitle style override [yes, force, no]
-   `o` - Leave video unscaled [yes, downscale-big, no]
-   `l` - Loop video [yes, no]
-   `j` - Cycle screenshot format [jpeg, png]
-   `alt+j` - Enable secondary track overlay [yes, no]

<br>

-   `WHEEL_UP` - volume + 2
-   `WHEEL_DOWN` - volume - 2
-   `WHEEL_LEFT` - Seek 10
-   `WHEEL_RIGHT` - Seek -10

<br>

-   `h` - Enable deband [yes, no]
-   `i` - Enable interpolation [yes, no]
-   `d` - Enable IVTC, deinterlacing (nnedi3, combed frames only) [yes, no]
-   `p` - Enable warpsharpening, line darkening [yes, no]

<br>

-   `Z` - Enable QuickTime gamma bug correction [yes, no]
-   `X` - Enable dynamic range compression fix [yes, no]
-   `C` - Enable colorspace mistag fix [709->601, 601->709, no]

<br>

-   `~` - Enable various diagnostic tools [videoinfo, python_globals, no]

## How to install the base setup

**Windows:**<br>

1. Create a new folder in `%appdata%` and call it mpv. <br>
2. Dump the contents of this directory in there. <br>
3. Change the paths as necessary in `mpv.conf`.<br>
4. **OPTIONAL:** Run `updater.bat` as Administrator to update your mpv.

**Linux:**<br>
TBA

## How to install VapourSynth and the filtering dependencies

1. Install the [latest version of VapourSynth](https://github.com/vapoursynth/vapoursynth/releases).<br>
   1.5. Install the latest required version of [Python](https://www.python.org/downloads/), and make sure it's added to PATH.<br>
2. Locate the following directories:<br> \* C:\Users\[your username]\AppData\Roaming\VapourSynth\plugins64<br> \* C:\Users\[your username]\AppData\Local\Programs\Python\Python311\Lib\site-packages<br>
3. Check the .vpy scripts in the repo (in the `vs` directory) and follow the links to the listed dependencies.
4. Download and move the required files to the relevant directories (Python modules go to the `site-packages` directory, everything else goes in the `plugins64` directory).
5. Verify that the scripts are running as intended by cycling through the profiles and pressing the `~` key during playback. It should tell you if it failed, and if it did what the missing dependencies are.

## Dependencies

-   [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases/tag/2021.10.10)
-   [Gandhi Sans](https://www.fontsquirrel.com/fonts/gandhi-sans) and [Noto Sans](https://fonts.google.com/specimen/Noto+Sans)
-   [VapourSynth](https://github.com/vapoursynth/vapoursynth/releases)

### _Optional VapourSynth-related dependencies_

-   [awarpSharp2](https://github.com/dubhater/vapoursynth-awarpsharp2/releases/tag/v4)
-   [havsfunc](https://github.com/HomeOfVapourSynthEvolution/havsfunc/releases)
-   [lvsfunc](https://pypi.org/project/lvsfunc/)
-   [NNEDI3CL](https://github.com/HomeOfVapourSynthEvolution/VapourSynth-NNEDI3CL/releases)
-   [TIVTC](https://github.com/dubhater/vapoursynth-tivtc/releases)
-   [vapoursynth-histogram](https://github.com/dubhater/vapoursynth-histogram)
-   [vs-kernels](https://pypi.org/project/vskernels/)
-   [vs-placebo](https://github.com/Lypheo/vs-placebo/releases)
-   [vsutil](https://pypi.org/project/vsutil/)

## Included shaders/scripts

-   [acompressor](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/acompressor.lua)
-   [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)
-   [auto-profiles](https://github.com/wiiaboo/mpv-scripts/blob/master/auto-profiles.lua)
-   [boss-key](https://github.com/detuur/mpv-scripts)
-   [reload](https://github.com/4e6/mpv-reload)
-   [repl](https://github.com/rossy/mpv-repl)
-   [status-line](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/status-line.lua)
-   [visualizer](https://github.com/mfcc64/mpv-scripts/blob/master/visualizer.lua)<br><br>
-   [FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)
-   [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)
-   [nnedi3](<(https://github.com/bjin/mpv-prescalers)>)
-   [ravu-r3](https://github.com/bjin/mpv-prescalers)

### Other

-   [Shinchiro's mpv updater](https://sourceforge.net/projects/mpv-player-windows/files/)

### _For additional shaders and scripts, check out the following sources_

-   [mpv shaders](https://github.com/mpv-player/mpv/wiki/User-Scripts#user-shaders)
-   [mpv scripts](https://github.com/mpv-player/mpv/wiki/User-Scripts#lua-scripts)
-   [VapourSynth scripts](https://github.com/LightArrowsEXE/Encoding-Projects/)

## Scalers

There are many schools of thought for which scaler is best.
Personally, I subscribe to blurrier output > super sharp output if it means introducing haloing.
There's little I find more unpleasant to look at than haloing and aliasing created by poor scaling,
so my settings are centred around suppressing those.

For upscaling, Nnedi3 is used.
Nnedi3 is fairly neutral and relatively fast compared to other NN upscalers.
FSRCNNX is prone to causing heavy ringing,
and while Waifu2x is pretty good for anime
(provided you use the one non-bad model),
it's much too slow to run in real-time,
even with vsmlrt's implementations.

TODO: Add upscaler comparisons.

For downscaling, a custom Bicubic kernel is used
(dubbed ZewiaCubic, after the person who came up with it).
The goal of this particular kernel is to suppress ringing and (dark) haloing.
This is ideal in situations where you want to downscale the image
to watch in the corner of your screen
(as I occasionally do).

The following scalers were tested (via VapourSynth):

| Catrom                                                                                                                     | Mitchell                                                                                                                     | Bilinear                                                                                                                     | Lanczos (3)                                                                                                                 | Spline36                                                                                                                     | ZewiaCubic                                                                                                                     | SSIM                                                                                                                     | DPID                                                                                                                     |
| -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/catrom.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/mitchell.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/bilinear.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/lanczos.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/spline36.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/zewiacubic.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/ssim.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale/dpid.png" width="98"> |

[As you can see in this comparison](https://slow.pics/c/pvfawmZJ),
when downscaling to lower resolutions,
ZewiaCubic introduces significantly less haloing
while preserving high-frequency information such as the lineart better.

The Achilles' heel is that this does not hold true for supersampled output,
as can be seen in [this comparison](https://slow.pics/c/Lx3WyWAk).

| src                                                                                                                                  | Catrom                                                                                                                                 | Mitchell                                                                                                                                 | Bilinear                                                                                                                                 | Lanczos (3)                                                                                                                             | Spline36                                                                                                                                 | ZewiaCubic                                                                                                                                 | SSIM                                                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img//dscale_supersample/src.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/catrom.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/mitchell.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/bilinear.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/lanczos.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/spline36.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/zewiacubic.png" width="98"> | <img src="https://github.com/LightArrowsEXE/dotfiles/blob/master/mpv/.config/mpv/github/img/dscale_supersample/ssim.png" width="98"> |

Lanczos and Spline36 perform better than the current setting in this context.
Currently, this config does not dynamically switch scalers depending on whether the image has been supersampled or not.
PRs are welcome.
