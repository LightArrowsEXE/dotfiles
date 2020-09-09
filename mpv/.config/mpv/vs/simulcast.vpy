import kagefunc as kgf
import lvsfunc as lvf
from vsutil import join, plane

import vapoursynth as vs

core = vs.core


deband_args = dict(iterations=2, threshold=4, radius=16)


src = video_in

if src.width < 720:
    deband_args.update(threshold=3, radius=12)

deband = join([ # For some insane reason, splitting is twice as fast to process
    core.placebo.Deband(plane(src, 0), grain=4, **deband_args),
    core.placebo.Deband(plane(src, 1), grain=0, **deband_args),
    core.placebo.Deband(plane(src, 2), grain=0, **deband_args)
])
detail_mask = lvf.denoise.detail_mask(src, brz_a=0.045, brz_b=0.06)
merged = core.std.MaskedMerge(deband, src, detail_mask)

grain = kgf.adaptive_grain(merged, 0.1, luma_scaling=4)

out = grain
out.set_output()
