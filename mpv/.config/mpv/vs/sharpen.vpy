from typing import Any

import havsfunc as haf
import vapoursynth as vs

core = vs.core

# Experimental script for sharpening poorly blurred/starved video
# This is done through standard sharpening, line darkening, and chroma warping

# If you have any resemblance of sanity, you would not use this
# Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

# Additional dependencies:
# * awarpsharp2 <https://github.com/dubhater/vapoursynth-awarpsharp2>
# * havsfunc <https://github.com/HomeOfVapourSynthEvolution/havsfunc>


def WarpChroma(clip: vs.VideoNode,
               thresh: int = 128,
               blur: int = 3,
               btype: int = 1,
               depth: int = 6,
               sigma: float = 1):
    """
        Modified version of xvs.WarpFixChromaBlend
        <https://github.com/xyx98/my-vapoursynth-script/blob/master/xvs.py#L840>
    """
    up = core.resize.Bicubic(src, format=vs.YUV444P16)
    planes = [core.std.ShufflePlanes(up, x, vs.GRAY)
              for x in range(up.format.num_planes)]

    mask = core.warp.ASobel(planes[0], thresh=thresh) \
        .warp.ABlur(blur=blur, type=btype)
    cwarp = [core.warp.AWarp(p, mask=mask, depth=depth) for p in planes[1:]]

    join = core.std.ShufflePlanes([planes[0], cwarp[0], cwarp[1]], [0, 0, 0], vs.YUV)
    lmask = core.tcanny.TCanny(up, mode=1, sigma=sigma)
    merged = core.std.MaskedMerge(join, up, lmask)
    return core.resize.Bicubic(merged, format=clip.format)


src = video_in

ec = haf.EdgeCleaner(src, strength=10, rmode=13, hot=True)

sharpen = haf.LSFmod(ec, strength=140, defaults='slow',
                     soft=10, edgemode=1, Smethod=2, Lmode=2)
cwarp = WarpChroma(sharpen, depth=10)

darken = haf.FastLineDarkenMOD(cwarp, strength=24)


darken.set_output()
