#!/usr/bin/env python3

from functools import partial
from typing import Any, Dict

import vapoursynth as vs
from vsutil import depth, get_depth

core = vs.core

"""
    Experimental script for inverse telecining and deinterlacing
    This will be slower than YADIF and more resource-intensive,
    but since it involves IVTC, it's less destructive overall

    Only frames that are marked as being combed get nnedi3'd.
    After IVTC, this should ideally only be frames that had no matching fields.
    This can mean either a failure in the fieldmatching or 60i content.

    In an ideal world I'd also have 60i content returned in 60 fps,
    but mpv's API offers no real reliable way to do so as far as I can tell.

    Requires VapourSynth <http://www.vapoursynth.com/about/>

    Additional dependencies:
        * vivtc <https://github.com/vapoursynth/vivtc/releases/tag/R1>
        * znedi3 <https://github.com/sekrit-twc/znedi3/releases/tag/r2.1>
        * vs-util <https://pypi.org/project/vsutil/>

    It is recommended you use vsrepo <https://github.com/vapoursynth/vsrepo>
    to download these if possible.
"""


def deinterlace(n: int, f: vs.VideoFrame,
                clip: vs.VideoNode, nn3: vs.VideoNode
                ) -> vs.VideoNode:
    """Only run and apply nnedi3 when the frame demands it"""
    return nn3 if f.props['_Combed'] > 0 else clip


# TO-DO: Find a way to automatically determine if the clip is supposed to be TFF or BFF
tff = True

# Args set to affect performance. Adjust as necessary depending on your specs:
perf_args: Dict[str, Any] = {'mchroma': False}


# Actual IVTC + deinterlacing
clip = video_in  # noqa
down = depth(clip, 8)  # Must be 8bit for VFM to work

vfm = core.vivtc.VFM(down, order=tff, field=tff, clip2=clip, chroma=False, **perf_args)
nn3 = core.znedi3.nnedi3(clip, field=tff)

deint = core.std.FrameEval(vfm, partial(deinterlace, clip=vfm, nn3=nn3), prop_src=vfm)
out = depth(deint, get_depth(clip))

out.set_output()
