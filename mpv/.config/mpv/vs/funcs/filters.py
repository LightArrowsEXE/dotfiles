from functools import partial

from vstools import core, get_depth, get_prop, vs


def deinterlace(clip: vs.VideoNode, tff: bool = True) -> vs.VideoNode:
    """
    Experimental script for inverse telecining and deinterlacing.

    This will be slower than YADIF and more resource-intensive,
    but since it involves IVTC, it's significantly less destructive overall.

    Only frames that are marked as being combed get nnedi3'd.
    After IVTC, this should ideally only be frames that had no matching fields.
    This can mean either a failure in the fieldmatching or 60i content.

    In an ideal world I'd also have 60i content returned in 60 fps,
    but mpv's API offers no real reliable way to do so as far as I can tell.

    Additional dependencies:
        * tivtc <https://github.com/dubhater/vapoursynth-tivtc/releases>
        * znedi3 <https://github.com/sekrit-twc/znedi3/releases/>
        * vs-util <https://pypi.org/project/vsutil/>

    It is recommended you use vsrepo <https://github.com/vapoursynth/vsrepo> to download these if possible.
    """
    def _deinterlace(n: int, f: vs.VideoFrame, clip: vs.VideoNode, nn3: vs.VideoNode) -> vs.VideoNode:
        """Only run and apply nnedi3 when the frame demands it"""
        return nn3 if get_prop(f, "_Combed", int) > 0 else clip

    # Perform deinterlacing
    vfm = core.tivtc.TFM(clip, order=tff, field=tff, chroma=False)
    nn3 = core.znedi3.nnedi3(clip, field=tff)

    return core.std.FrameEval(vfm, partial(_deinterlace, clip=vfm, nn3=nn3), vfm)


def warpsharp(clip: vs.VideoNode, thresh: int = 128, blur: int = 3,
              type: int = 1, depth: int = 8, darken_strength: int = 24) -> vs.VideoNode:
    """
    Experimental script for sharpening poorly blurred/starved video.

    This is done through awarpsharp2, which you typically AVOID LIKE THE PLAGUE.
    Blame the ones who requested I add bleeding-sharp filters.
    I at least try to limit it to keep myself slightly sane.

    If you have any semblance of sanity, you should not use this.

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
    :param darken_strength:     Line darkening amount, 0-255

    :return:                    Sharpened clip
    """
    from havsfunc import FastLineDarkenMOD  # type:ignore

    mask = core.warp.ASobel(clip, thresh=thresh).warp.ABlur(blur=blur, type=type)
    warp = core.warp.AWarpSharp2(clip, thresh=thresh, blur=blur, type=type, depth=depth)
    merged = core.std.MaskedMerge(clip, warp, mask)

    return FastLineDarkenMOD(merged, strength=darken_strength >> get_depth(clip))
