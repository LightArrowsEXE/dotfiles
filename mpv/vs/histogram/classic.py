from vstools import core, depth

g = globals()

if 'video_in' in g:
    core.hist.Classic(depth(video_in, 8)).set_output()  # type:ignore[name-defined]
