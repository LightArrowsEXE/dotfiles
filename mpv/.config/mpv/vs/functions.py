"""
    A Python module containing all the functions used for filtering.
    Individual VapourSynth scripts will remain, although ideally I'd figure out how to
    actually allow VS scripts to import functions from each other. Until I've figured
    that out, this will have to do.
"""
from functools import partial
from typing import Any

import havsfunc as haf
import lvsfunc as lvf
import vapoursynth as vs
from vsutil import depth, join, plane, scale_value

core = vs.core


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


def warpsharp(clip: vs.VideoNode,
              thresh: int = 128,
              blur: int = 3,
              type: int = 1,
              depth: int = 8,
              darken_strength: int = 24):
        """
            Experimental script for sharpening poorly blurred/starved video.
            This is done through awarpsharp2, which you typically AVOID LIKE THE PLAGUE.
            Blame the ones who requested I add bleeding-sharp filters.
            I at least try to limit it to keep myself slightly sane.

            If you have any resemblance of sanity, you should not use this.
            Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

            Additional dependencies:
                * awarpsharp2 <https://github.com/dubhater/vapoursynth-awarpsharp2>
                * havsfunc <https://github.com/HomeOfVapourSynthEvolution/havsfunc>

        :param clip:                Input clip
        :param thresh:              No pixel in the edge mask will have a value greater than thresh.
                                    Decrease for weaker sharpening.
        :param blur:                Controls the number of times to blur the edge mask.
                                    Increase for weaker sharpening.
        :param type:                Controls the type of blur to use.
                                    0 means some kind of 13x13 average.
                                    1 means some kind of 5x5 average.
        :param depth:               Controls how far to warp.
                                    Negative values warp in the other direction,
                                    i.e. will blur the image instead of sharpening.
        :param darken_strength:     Line darkening amount, 0-256

        :return:                    Sharpened clip
        """

        mask = core.warp.ASobel(clip, thresh=thresh) \
            .warp.ABlur(blur=blur, type=type)
        warp = core.warp.AWarpSharp2(
                clip, thresh=thresh, blur=blur, type=type, depth=depth)
        merged = core.std.MaskedMerge(clip, warp, mask)
        return haf.FastLineDarkenMOD(merged,
            strength=darken_strength >> clip.format.bits_per_sample)


def IVTC(clip: vs.VideoNode, TFF: bool):
    """"
        Experimental script for inverse telecining and deinterlacing.

        Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

        Additional dependencies:
            * vs-util <https://github.com/Irrational-Encoding-Wizardry/vsutil>

        :param clip:         Input clip
        :param TFF:          Top-Field-First

        :return:             IVTC'd clip
    """
    down = depth(clip, 8)
    vfm = core.vivtc.VFM(down, TFF)
    return depth(vfm, clip.format.bits_per_sample)


def deinterlace(clip: vs.VideoNode, TFF: bool) -> vs.VideoNode:
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
    def nn3(n, f, clip, nn3):
        """
            Only nnedi3 frames that are marked as being combed.
            After IVTC, this should ideally only be frames that had no matching fields.
            This can mean either a failure in the fieldmatching or 60i content.

            In an ideal world I'd also have 60i content returned in 60 fps,
            but there's no real way to do so reliably here.
        """
        return nn3 if f.props['_Combed'] > 0 else clip

    down = depth(clip, bitdepth=8)

    vfm = core.vivtc.VFM(down, True)
    nn3 = core.nnedi3cl.NNEDI3CL(down, True)

    deint = core.std.FrameEval(vfm, partial(deinterlace, clip=vfm, nn3=nn3), prop_src=vfm)
    return depth(deint, clip.format.bits_per_sample)
