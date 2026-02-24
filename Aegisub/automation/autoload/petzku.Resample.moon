export script_name =        "Resample"
export script_description = "Recalculates 3D-transforms when resampling script"
export script_author =      "petzku"
export script_namespace =   "petzku.Resample"
export script_version =     "0.2.1"

DependencyControl = require "l0.DependencyControl"
dep = DependencyControl{
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https://github.com/TypesettingTools/ASSFoundation",
     feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
  }
}
LineCollection, ASS = dep\requireModules!

-- lua's trig works in radians, simplify to degrees
cos = (angle) -> math.cos(math.rad(angle))
tan = (angle) -> math.tan(math.rad(angle))
atan = (x) -> math.deg(math.atan(x))

mod_rotation = (alpha, x1, x2) ->
  atan(x1 * tan(alpha) / x2)

mod_scale = (alpha1, alpha2) ->
  cos(alpha1) / cos(alpha2)

resample = (src, sub, sel, modtags) ->
  --width, height. assume AR always stays the same
  _, target = aegisub.video_size!
  lines = LineCollection sub, sel
  lines\runCallback (lines, line) ->
    data = ASS\parse line
    oldx, oldy = nil, nil
    newx, newy = nil, nil
    data\modTags {"angle_x"}, (tag) ->
      oldx = tag.value
      newx = mod_rotation(tag.value, src, target)
      tag.value = newx
      tag
    data\modTags {"angle_y"}, (tag) ->
      oldy = tag.value
      newy = mod_rotation(tag.value, src, target)
      tag.value = newy
      tag
    
    if modtags
      style = line.styleRef
      -- if modified x, change y-scales, and vice versa
      -- TODO: this implementation inserts default tags even if the tags are present in the line,
      --       which is probably undesirable. Current workaround is to insert the tags at the start of the section.
      --       therefore, later tags will nicely override the former ones
      -- TODO: figure out how to automatically split bord/shad if present
      if oldx and oldx != newx
        scale = mod_scale(oldx, newx)
        data\insertDefaultTags {"scale_y", "outline_y", "shadow_y"}, 1, 1
        data\modTags {"scale_y", "outline_y", "shadow_y"}, (tag) ->
          tag * scale

      if oldy and oldy != newy
        scale = mod_scale(oldy, newy)
        data\insertDefaultTags {"scale_x", "outline_x", "shadow_x"}, 1, 1
        data\modTags {"scale_x", "outline_x", "shadow_x"}, (tag) ->
          tag * scale

    data\commit!
  lines\replaceLines!
  aegisub.set_undo_point string.format "resample rotations from %dp", src

seventwenty = (sub, sel) ->
  resample(720, sub, sel, true)

anyres = (sub, sel) ->
  diag = {
    {class: 'label', label: "Source &res", x: 0, y: 0},
    {class: 'intedit', name: 'res', value: 720, x: 1, y: 0},
    {class: 'checkbox', label: "&Modify scales", name: 'modscale', value: true, x: 2, y: 0}
  }
  btn, res = aegisub.dialog.display diag
  if btn then resample(res.res, sub, sel, res.modscale)

dep\registerMacro anyres
