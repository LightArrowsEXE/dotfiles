from functools import partial
import vapoursynth as vs
core = vs.core

# Experimental script for inverse telecining and deinterlacing
# This will be slower than YADIF and more resource-intensive,
# but since it involves IVTC, it's less destructive overall
# Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

# Additional dependencies:
# * NNEDI3CL <https://github.com/HomeOfVapourSynthEvolution/VapourSynth-NNEDI3CL>


def deinterlace(n, f, clip, nn3):
    return nn3 if f.props['_Combed'] > 0 else clip


src = video_in

src = core.resize.Bicubic(src, format=vs.YUV420P8)
vfm = core.vivtc.VFM(src, True)
nn3 = core.nnedi3cl.NNEDI3CL(src, True)

deint = core.std.FrameEval(vfm, partial(deinterlace, clip=vfm, nn3=nn3), prop_src=vfm)

deint.set_output()
