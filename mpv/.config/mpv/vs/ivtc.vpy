import vapoursynth as vs
from typing import Optional
from vsutil import depth, get_depth

core = vs.core


def IVTC(clip: vs.VideoNode, TFF: Optional[bool] = None) -> vs.VideoNode:
    """"
        Experimental script for inverse telecining and deinterlacing.

        Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

        Additional dependencies:
            * vsutil <https://pypi.org/project/vsutil/>

        :param clip:         Input clip
        :param TFF:          Top-Field-First

        :return:             IVTC'd clip
    """
    if TFF is None:
        TFF = True

    down = depth(clip, 8)
    vfm = core.vivtc.VFM(down, TFF)
    return depth(vfm, get_depth(clip))


IVTC(video_in, TFF=True).set_output()
