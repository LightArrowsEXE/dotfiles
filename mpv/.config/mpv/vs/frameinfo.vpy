import vapoursynth as vs
core = vs.core

"""
Print basic frame information
"""

clip = video_in.std.PlaneStats()
h = clip.height
warning = "Note:\nInformation provided\nmay be limite due to mpv's API!"
thr = h < 900
thr_sd = h < 576

if not thr_sd:
    clip.text.FrameProps(alignment=9) \
        .text.ClipInfo(alignment=3 if thr else 6) \
        .text.CoreInfo(alignment=1 if thr else 3) \
        .text.Text(warning) \
        .set_output()
else:  # The text is simply too cramped on SD content, and ``scale`` only takes ints :(
    clip.text.FrameProps(alignment=7) \
        .text.ClipInfo(alignment=9) \
        .text.Text(warning, alignment=1) \
        .set_output()
