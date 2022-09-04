import sys
from pathlib import Path
from pprint import pformat

import vapoursynth as vs

core = vs.core

keys = [
    '__builtins__',
    'path',
    'vs',
    'key',
    'Path',
    'keys',
    'sys',
    'temp',
    'This menu displays all the meaningful mpv variables exposed to VS',
]

if 'video_in' in globals():
    clip = globals()['video_in']

    globals()['__file__'] = Path(globals()['__file__']).absolute()
    python = sys.version.split(" [")
    python[1] = "[" + python[1]

    ___ignore_me = globals()
    ___ignore_me |= locals()

    for _ in keys:
        ___ignore_me.pop(_, None)

    ___ignore_me |= {'__': '', '___': ''}

    clip.text.Text(pformat(___ignore_me, depth=4, sort_dicts=True)).set_output()
