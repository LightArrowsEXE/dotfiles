#!/usr/bin/env python3

from functools import partial
from typing import Optional

import vapoursynth as vs
from vsutil import depth, get_depth

core = vs.core


def deinterlace(clip: vs.VideoNode, TFF: Optional[bool] = None) -> vs.VideoNode:
    """
        Experimental script for inverse telecining and deinterlacing
        This will be slower than YADIF and more resource-intensive,
        but since it involves IVTC, it's less destructive overall

        Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

        Additional dependencies:
            * NNEDI3CL <https://github.com/HomeOfVapourSynthEvolution/VapourSynth-NNEDI3CL>
            * vs-util <https://github.com/Irrational-Encoding-Wizardry/vsutil>

        :param clip:         Input clip
        :param TFF:          Top-Field-First

        :return:             IVTC'd clip with deinterlacing applied to frames with leftover combing
    """
    def deint(n, f, clip: vs.VideoNode, nn3: vs.VideoNode) -> vs.VideoNode:
        """
            Only nnedi3 frames that are marked as being combed.
            After IVTC, this should ideally only be frames that had no matching fields.
            This can mean either a failure in the fieldmatching or 60i content.

            In an ideal world I'd also have 60i content returned in 60 fps,
            but mpv's API offers no real reliable way to do so as far as I can tell.
        """
        return nn3 if f.props['_Combed'] > 0 else clip

    if TFF is None:
        TFF = True

    down = depth(clip, 8)

    vfm = core.vivtc.VFM(down, True)
    nn3 = core.nnedi3cl.NNEDI3CL(down, True)

    deint = core.std.FrameEval(vfm, partial(deint, clip=vfm, nn3=nn3), prop_src=vfm)
    return depth(deint, get_depth(clip))


deinterlace(video_in, TFF=True).set_output()
