from typing import Any

import lvsfunc as lvf
import vapoursynth as vs
from vsutil import get_depth, join, plane, scale_value

core = vs.core

# A general-purpose filtering script for shitty simulcast video
# Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

# Additional dependencies:
# * lvsfunc <https://github.com/Irrational-Encoding-Wizardry/lvsfunc>
# * vs-placebo <https://github.com/Lypheo/vs-placebo>
# * vs-util <https://github.com/Irrational-Encoding-Wizardry/vsutil>


def debander(clip: vs.VideoNode,
             luma_grain: float = 4.0,
             **args: Any
             ) -> vs.VideoNode:
    return join([  # For some insane reason, splitting them is faster?
        core.placebo.Deband(plane(clip, 0), grain=luma_grain, **args),
        core.placebo.Deband(plane(clip, 1), grain=0, **args),
        core.placebo.Deband(plane(clip, 2), grain=0, **args)
    ])


deband_args = dict(iterations=2, threshold=4, radius=16)


src = video_in

if src.width <= 810:
    deband_args.update(threshold=3, radius=12)

src = core.resize.Bicubic(src, format=vs.YUV420P16)


detail_mask = lvf.denoise.detail_mask(
    src, brz_a=scale_value(0.045, 32, get_depth(src)),
    brz_b=scale_value(0.06, 32, get_depth(src)))
deband = debander(src, **deband_args)
deband = core.std.MaskedMerge(deband, src, detail_mask)

grain = core.std.MaskedMerge(
    deband, core.grain.Add(deband, var=0.1, uvar=0, constant=False),
    lvf.denoise.adaptive_mask(deband, luma_scaling=4.0)
)


grain.set_output()
