from __future__ import annotations

from fractions import Fraction
from pprint import pformat
from typing import Any

from vstools import get_depth, get_prop, vs


def get_scale(clip: vs.VideoNode) -> int:
    h = clip.height

    scale: int = 1

    match h:
        case _ if h > 4000 and h <= 1400: scale = 4
        case _ if h > 1400: scale = 2
        case _: scale = 1

    return scale


def assume_framerate(fps: float) -> Fraction | None:
    match f'{fps:.3f}':
        case '23.976': return Fraction(24000, 1001)
        case '29.970': return Fraction(30000, 1001)
        case '59.940': return Fraction(60000, 1001)
        case _: return Fraction(0, 1)  # VapourSynth default


def video_props(clip: vs.VideoNode, globals: dict[str, Any]) -> vs.VideoNode:
    """
    Print basic frame information.

    Text positioning is dependent on clip height.
    More checks for weird resolutions may be added at a future date.

    Text is scaled at 1 except for 4k, where it's scaled at 2,
    and 8k, where it's scaled at 4.


    TO-DO:  Calculations to determine stuff like framerate, matrix?
            Maybe even figure out a way to get the path from mpv
            and parse it through mediainfo? Depends on if
            it reruns the vpy over every single frame or just one
            (I assume just once like it would usually).
            I could also run a frameeval to get just information
            that's useful for your average user, but that's
            incredibly slow. Can't think of a nice way to do it
            short of writing my own plugin, unfortunately.
    """

    clip = clip.std.PlaneStats()

    disclaimer = "Disclaimer:\nInformation provided may be limited\nor potentially even WRONG \ndue to mpv's limited API!"
    scale = get_scale(clip)

    frame = clip.get_frame(0)

    props: dict[str, Any] = dict(Bitdepth=get_depth(clip))

    # Dimensions (actual, DAR)
    props |= dict(
        ClipWidth=clip.width, ClipHeight=clip.height,
        DisplayWidth=globals['video_in_dw'], DisplayHeight=globals['video_in_dh']
    )

    # Framerate
    fps = assume_framerate(globals['container_fps'])
    if fps:
        props |= dict(
            FPS_ContainerDen=fps.denominator,
            FPS_ContainerNum=fps.numerator,
            FPS_Display=globals['display_fps']
        )

    # Matrices
    csp = get_prop(frame, "_ColorSpace", int, int, 2)
    props |= dict(CPS_Matrix=csp, CPS_Transfer=csp, CPS_Primaries=csp)

    # format props
    original_props = pformat({"VideoNode": '', '_P': dict(frame.props)}, sort_dicts=True)
    props = pformat({"Mpv": '', '_P': props}, sort_dicts=True)  # type:ignore

    if clip.height < 576:  # Dropping CoreInfo because text is waaay too cramped if I keep it
        return clip \
            .text.Text(original_props, alignment=9) \
            .text.Text(props, alignment=3) \
            .text.CoreInfo(alignment=1, scale=scale) \
            .text.Text(disclaimer, alignment=7)
    else:
        return clip \
            .text.Text(original_props, alignment=9, scale=scale) \
            .text.Text(props, alignment=3 if clip.height < 900 else 6, scale=scale) \
            .text.CoreInfo(alignment=1, scale=scale) \
            .text.Text(disclaimer, alignment=7, scale=scale)
