import vapoursynth as vs
core = vs.core

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

clip = video_in.std.PlaneStats()
h = clip.height
disclaimer = "Disclaimer:\nInformation provided may be limited\nor potentially even WRONG due to mpv's limited API!"
scale = 4 if h > 4000 and h <= 1400 else 2 if h > 1400 else 1

if h < 576:  # Dropping CoreInfo because text is waaay too cramped if I keep it
    clip.text.ClipInfo(alignment=7) \
        .text.FrameProps(alignment=9) \
        .text.Text(disclaimer, alignment=1) \
        .set_output()
else:
    clip.text.ClipInfo(alignment=9, scale=scale) \
    .text.FrameProps(alignment=3 if h < 900 else 6, scale=scale) \
    .text.CoreInfo(alignment=1 if h < 900 else 3, scale=scale) \
    .text.Text(disclaimer, scale=scale) \
    .set_output()
