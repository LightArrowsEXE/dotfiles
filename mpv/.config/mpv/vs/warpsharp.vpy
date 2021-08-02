import havsfunc as haf
import vapoursynth as vs

core = vs.core

"""
    SUPERSEDED BY .warpsharp_neo. Basically the same, but a bit more sane.

    Experimental script for sharpening poorly blurred/starved video.
    This is done through awarpsharp2, which you typically AVOID LIKE THE PLAGUE.
    Blame the ones who requested I add bleeding-sharp filters.
    I at least try to limit it to keep myself slightly sane.

    If you have any resemblance of sanity, you should not use this.
    Requires VapourSynth <http://www.vapoursynth.com/doc/about.html>

    Additional dependencies:
        * awarpsharp2 <https://github.com/dubhater/vapoursynth-awarpsharp2>
        * havsfunc <https://github.com/HomeOfVapourSynthEvolution/havsfunc>
"""


def warpsharp(clip: vs.VideoNode,
              thresh: int = 128, blur: int = 3,
              type: int = 1, depth: int = 8,
              darken_strength: int = 24
              ) -> vs.VideoNode:
    """
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

    mask = core.warp.ASobel(clip, thresh=thresh) \
        .warp.ABlur(blur=blur, type=type)
    warp = core.warp.AWarpSharp2(
            clip, thresh=thresh, blur=blur, type=type, depth=depth)
    merged = core.std.MaskedMerge(clip, warp, mask)
    return haf.FastLineDarkenMOD(merged,
        strength=darken_strength >> clip.format.bits_per_sample)


warpsharp(video_in).set_output()
