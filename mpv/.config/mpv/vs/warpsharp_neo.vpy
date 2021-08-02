from typing import Any

import havsfunc as haf
import vapoursynth as vs
from vsutil import depth, get_depth, join, split

core = vs.core

"""
    Slightly better implementation of my warpsharp function,
    and also a bit less awful with the line warping.
    Still wouldn't really recommend it, but if you *really* need sharpening...

    Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

    Additional dependencies:
        * vsutil <https://pypi.org/project/vsutil/>
        * awarpsharp2 <https://github.com/dubhater/vapoursynth-awarpsharp2>
        * havsfunc <https://github.com/HomeOfVapourSynthEvolution/havsfunc>
"""


def chromawarp(clip: vs.VideoNode) -> vs.VideoNode:
    """Basically a simple rewrite of xvs.WarpFixChromaBlend to fix chroma around edges"""
    up = core.resize.Bicubic(clip, format=vs.YUV444P16)
    planes = split(up)
    warp_mask = planes[0].warp.ASobel(thresh=128).warp.ABlur(blur=3, type=1)
    planes[1], planes[2] = [p.warp.AWarp(mask=warp_mask, depth=10) for p in planes[1:]]
    return join(planes).resize.Bicubic(format=clip.format)


clip = video_in
up = depth(clip, 16)
darken = haf.FastLineDarkenMOD(clip, strength=48, protection=4, threshold=5, luma_cap=204)
warp = darken.warp.AWarpSharp2(depth=6, blur=2, thresh=112)
cwarp = chromawarp(warp)


depth(cwarp, get_depth(clip)).set_output()
