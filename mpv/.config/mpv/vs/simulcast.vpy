#!/usr/bin/env python3

from typing import Any

import lvsfunc as lvf
import vapoursynth as vs
from vsutil import depth, get_depth, join, plane, scale_value

core = vs.core

"""
    Generic debanding with detail masking script.

    Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

    Additional dependencies:
        * lvsfunc <https://github.com/Irrational-Encoding-Wizardry/lvsfunc>
        * vs-placebo <https://github.com/Lypheo/vs-placebo>
        * vs-util <https://github.com/Irrational-Encoding-Wizardry/vsutil>
"""


def generate_detail_mask(clip: vs.VideoNode,
                         brz_a: float = 0.045,
                         brz_b: float = 0.060,
                         **kwargs: Any) -> vs.VideoNode:
    """
        Generates a detail mask.
        If a float value is passed, it'll be scaled to the clip's bitdepth.

        :param clip:        Input clip
        :param brz_a:       Binarizing for the detail mask
        :param brz_b:       Binarizing for the edge mask
        :param kwargs:      Additional parameters passed to lvf.denoise.detail_mask

        :return:            Detail mask
    """
    return lvf.denoise.detail_mask(clip,
        brz_a=scale_value(brz_a, 32, clip.format.bits_per_sample)
            if brz_a is float else brz_a,
        brz_b=scale_value(brz_b, 32, clip.format.bits_per_sample)
            if brz_b is float else brz_b,
        **kwargs)


def debander(clip: vs.VideoNode,
             luma_grain: float = 4.0,
             **kwargs: Any) -> vs.VideoNode:
    """
        A quick 'n dirty generic debanding function.
        To be more specific, it would appear that it's faster to
        deband every plane separately (don't ask me why).

        To abuse this, we split up the clip into planes beforehand,
        and then join them back together again at the end.

        Although the vast, vast majority of video will be YUV,
        a sanity check for plane amount is done as well, just to be safe.

        :param clip:        Input clip
        :param luma_grain:  Grain added to the luma plane
        :param kwargs:        Additional parameters passed to placebo.Deband

        :return:            Debanded clip
    """
    if clip.format.num_planes == 0:
        return core.placebo.Deband(clip, grain=luma_grain, **kwargs)
    return join([
        core.placebo.Deband(plane(clip, 0), grain=luma_grain, **kwargs),
        core.placebo.Deband(plane(clip, 1), grain=0, **kwargs),
        core.placebo.Deband(plane(clip, 2), grain=0, **kwargs)
    ])


deband_args: Any = dict(iterations=2, threshold=4, radius=16)

if video_in_dh <= 810:
    deband_args.update(threshold=3, radius=12)


clip = depth(video_in, 16)
detail_mask = generate_detail_mask(clip, brz_a=0.045, brz_b=0.06)
deband = debander(clip, luma_grain=4.0, **deband_args)
deband = core.std.MaskedMerge(deband, clip, detail_mask).set_output()

depth(deband, get_depth(video_in)).set_output()
