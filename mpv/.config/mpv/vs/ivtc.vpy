from typing import Any, Dict
from functools import partial
import vapoursynth as vs
core = vs.core

# Experimental script for inverse telecining and deinterlacing
# Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>


src = video_in

src = core.resize.Bicubic(src, format=vs.YUV444P8)
vfm = core.vivtc.VFM(src, True)

vfm.set_output()
