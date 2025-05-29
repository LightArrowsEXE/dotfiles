#!/usr/bin/env python3

from typing import Any

from vsdeband import F3kdb, Placebo, adaptive_grain, deband_detail_mask
from vstools import core, depth, get_depth

"""
    Generic debanding with detail masking script.

    Requires VapourSynth <http://www.vapoursynth.com/about/> and a couple additional packages.

    Please run the following command before trying to use this script:
    pip install vsdeband vstools

    And install these additional dependencies in your VS plugin directory:
        * vs-placebo <https://github.com/Lypheo/vs-placebo>
        * f3kdb <https://f3kdb.readthedocs.io/en/latest/>
"""

grain_strength: tuple[float, float] = (0.15, 0.0)
# Post-graining strength. Sane values are between 0 and ~0.5 for `addGrain`.
# First value is for the luma grain, the second for the chroma grain.

f3kdb_arg: dict[str, Any] = dict(radius=18, threshold=24, grain=0)
placebo_args: dict[str, Any] = dict(iterations=2, threshold=4, radius=16, grains=0)

if video_in_dh <= 810:  # type:ignore
    f3kdb_arg.update(radius=16, threshold=16)
    placebo_args.update(threshold=3, radius=12)

vid = depth(video_in, 16)  # type:ignore

detail_mask = deband_detail_mask(vid, brz=(int(0.045, * 255) << 8, int(0.06, * 255) << 8))

deband_f3kdb = F3kdb.deband(vid, )
deband_placebo = Placebo.deband(vid, **placebo_args)
deband = core.std.MaskedMerge(deband_placebo, deband_f3kdb, detail_mask)

grain = adaptive_grain(deband, strength=list(grain_strength), luma_scaling=0)

depth(deband, get_depth(video_in)).set_output()  # type:ignore
