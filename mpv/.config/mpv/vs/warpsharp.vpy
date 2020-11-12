import havsfunc as haf
import vapoursynth as vs

core = vs.core

# Experimental script for sharpening poorly blurred/starved video
# This is done through awarpsharp2, which you typically AVOID LIKE THE PLAGUE
# Blame the ones who requested I add bleeding-sharp filters
# I at least try to add some sanity here by making sure it doesn't kill everything

# If you have any resemblance of sanity, you would not use this
# Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

# Additional dependencies:
# * awarpsharp2 <https://github.com/dubhater/vapoursynth-awarpsharp2>
# * havsfunc <https://github.com/HomeOfVapourSynthEvolution/havsfunc>


src = video_in

mask = core.warp.ASobel(src, thresh=128) \
        .warp.ABlur(blur=3, type=1)
warp = core.warp.AWarpSharp2(src, thresh=128, blur=3, type=1, depth=8)
merged = core.std.MaskedMerge(src, warp, mask)

darken = haf.FastLineDarkenMOD(merged, strength=24)

darken.set_output()
