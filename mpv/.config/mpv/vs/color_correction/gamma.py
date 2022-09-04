import importlib
import importlib.util
import sys
from pathlib import Path

import vapoursynth as vs

# This is hacky, but ya gotta do what you gotta do
spec = importlib.util.spec_from_file_location("funcs", f"{Path(__file__).parents[1]}/funcs/__init__.py")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)

from funcs import colors

core = vs.core

g = globals()

if 'video_in' in g:
    colors.fix_lvls(g['video_in']).set_output()
