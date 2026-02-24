-- Copyright (c) 2020, petzku <petzku@zku.fi>

export script_name =        "Shake"
export script_description = "Shakes text"
export script_author =      "petzku"
export script_namespace =   "petzku.Shake"
export script_version =     "0.1.2"

DependencyControl = require "l0.DependencyControl"
dep = DependencyControl{
  feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
  {"a-mo.LineCollection", "l0.ASSFoundation"}
}
LC, ASS = dep\requireModules!

-- lua's trig works in radians, simplify to degrees
sin = (angle) -> math.sin(math.rad(angle))
cos = (angle) -> math.cos(math.rad(angle))

randomPos = (x, y, a) ->
  rad = math.random() * a
  rot = math.random() * 360

  dx = rad * cos(rot)
  dy = rad * sin(rot)

  x + dx, y + dy

shake = (sub, sel, astart, aend) ->
  lines = LC sub, sel
  step = 0
  unless #lines == 0
    step = (astart - aend) / (#lines - 1)
  amp = aend
  -- iterating backwards, start from final value

  lines\runCallback (lines, line) ->
    data = ASS\parse line
    x, y = data\getPosition!\getTagParams!
    nx, ny = randomPos(x, y, amp)
    data\removeTags {'position'}
    data\insertTags {ASS\createTag 'position', nx, ny}
    data\commit!
    -- linear decay because I'm lazy, proper should be exp
    amp += step
  lines\replaceLines!

shakeGui = (sub, sel) ->
  diag = {
    {class: 'label', label: "Amplitude at &start", x: 0, y: 0},
    {class: 'floatedit', name: "astart", value: 50, x: 1, y: 0},
    {class: 'label', label: "Amplitude at &end", x: 0, y: 1},
    {class: 'floatedit', name: "aend", value: 30, x: 1, y: 1}
  }
  btn, vars = aegisub.dialog.display diag
  if btn
    shake sub, sel, vars.astart, vars.aend

dep\registerMacro shakeGui
