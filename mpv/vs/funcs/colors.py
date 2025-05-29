from vstools import depth, get_depth, scale_value, vs

core = vs.core


def fix_colorspace(clip: vs.VideoNode, csp: int = 1, actual_csp: int = 6) -> vs.VideoNode:
    """
    Fix wrongly tagged colorspaces.

    See: https://silentaperture.gitlab.io/mdbook-guide/filtering/detinting.html#improper-color-matrix
    """
    clip = clip.resize.Bicubic(matrix_in=csp, transfer_in=csp, primaries_in=csp,
                               matrix=actual_csp, transfer=actual_csp, primaries=actual_csp)
    return clip.std.SetFrameProps(_Matrix=csp, _Transfer=csp, _Primaries=csp)


def fix_drc(clip: vs.VideoNode) -> vs.VideoNode:
    """
    Experimental real-time double range compression fixing.

    See: https://silentaperture.gitlab.io/mdbook-guide/filtering/detinting.html#double-range-compression
    """
    clip = clip.resize.Point(range_in=0, range=1, dither_type="error_diffusion")
    return clip.std.SetFrameProp(prop="_ColorRange", intval=1)


def fix_lvls(clip: vs.VideoNode) -> vs.VideoNode:
    """
    Experimental real-time gammabug fixing.

    See:
        * https://silentaperture.gitlab.io/mdbook-guide/filtering/detinting.html#the-088-gamma-bug
        * https://vitrolite.wordpress.com/2010/12/31/quicktime_gamma_bug/

    Dependencies:
        * awmsfunc <https://github.com/OpusGang/awsmfunc>_
    """

    clip, bits = depth(clip, 32), get_depth(clip)

    clip = clip.std.Levels(
        gamma=0.88,
        min_in=scale_value(4096, 16, 32), max_in=scale_value(60160, 16, 32),
        min_out=scale_value(4096, 16, 32), max_out=scale_value(60160, 16, 32),
        planes=0
    )

    return depth(clip, bits)
