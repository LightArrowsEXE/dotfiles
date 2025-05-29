from vsdenoise import knl_means_cl, ChannelMode
from vsrgtools import contrasharpening


den = knl_means_cl(video_in, strength=1.25, channels=ChannelMode.LUMA)  # type:ignore
csharp = contrasharpening(den, video_in)  # type:ignore

csharp.set_output()
