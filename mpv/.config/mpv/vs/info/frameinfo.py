from funcs import diagnostics
import sys
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

# This is hacky, but ya gotta do what you gotta do
spec = spec_from_file_location("funcs", f"{Path(__file__).parents[1]}/funcs/__init__.py")
module = module_from_spec(spec)  # type:ignore
sys.modules[spec.name] = module  # type:ignore
spec.loader.exec_module(module)  # type:ignore


g = globals()


if 'video_in' in g:
    diagnostics.video_props(g['video_in'], g).set_output()
