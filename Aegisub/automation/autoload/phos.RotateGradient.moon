export script_name = "Rotate Gradient"
export script_description = "Create rotated gradient with clip."
export script_author = "PhosCity"
export script_namespace = "phos.RotateGradient"
export script_version = "2.0.2"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"a-mo.Line", version: "1.5.3", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
  }
}
LineCollection, Line, ASS, Functional = depctrl\requireModules!
{ :list, :util } = Functional

tags_grouped = {
    {"1c", "3c", "4c"},
    {"alpha", "1a", "2a", "3a", "4a"},
    {"bord", "xbord", "ybord"},
    {"shad", "xshad", "yshad"},
    {"blur", "be"},
}
tags_flat = list.join unpack tags_grouped
-- Generate a key, value pair of tag's override name and assf tag names
tagMap = {item, (ASS\getTagNames "\\#{item}")[1] for item in *tags_flat}

--TODO: This was taken and slightly modified from logger module of depctrl. For some reason windowError doesn't work when required from that module. Check why.
windowAssertError = ( condition, errorMessage ) ->
  if not condition
    aegisub.dialog.display { { class: "label", label: errorMessage } }, { "&Close" }, { cancel: "&Close" }
    aegisub.cancel!
  else
    return condition

create_dialog = ->
  dlg = {
    { x: 0, y: 0, width: 2, height: 1, class: "label", label:"Pixels per strip: "},
    { x: 2, y: 0, width: 2, height: 1, class: "intedit", name: "strip", min: 1, value: 1, step: 1 },
    { x: 0, y: 6, width: 2, height: 1, class: "label", label: "Acceleration: " },
    { x: 2, y: 6, width: 2, height: 1, class:"floatedit", name: "accel", value: 1, hint: "1 means no acceleration, >1 starts slow and ends fast, <1 starts fast and ends slow" },
  }
  for y, group in ipairs tags_grouped
    dlg[#dlg+1] = { name: tag, class: "checkbox", x: x-1, y: y, width: 1, height: 1, label: "\\#{tag}", value: false } for x, tag in ipairs group

  btn, res = aegisub.dialog.display dlg, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  return res if btn else aegisub.cancel!


-- Gets clip, tag values, bounding box etc that are required for further processing
prepare_line = (sub, sel, res) ->
  lines = LineCollection sub, sel
  aegisub.cancel! if #lines.lines < 2
  hasClip, clip, tagState, text, bound = false, {}, {}
  lines\runCallback ((lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    data = ASS\parse line
    -- Collect text of the line
    currText = ""
    data\callback (section) ->
      currText ..= section\getString! if section.class == ASS.Section.Text or section.class == ASS.Section.Drawing

    -- Collect the tag that must be gradiented
    effTags = (data\getEffectiveTags -1, true, true, false).tags
    for tag in *tags_flat
      tagState[i] or= {}
      tagState[i][tag] = effTags[tagMap[tag]] if res[tag]

    -- Collect vectorial clip from the line
    clipTable = data\getTags "clip_vect"
    if #clipTable != 0 and not hasClip
      hasClip = true
      for index, cnt in ipairs clipTable[1].contours[1].commands          -- Is this the best way to loop through co-ordinate?
        data\removeTags "clip_vect"                                       -- Clip affects the bounding box of the line.
        break if index == 4
        x, y = cnt\get!
        table.insert clip, x
        table.insert clip, y

    -- Collect bounding box of the line
    currBound = data\getLineBounds!
    
    -- Check if text of selected lines differ. They should not. Also update bounding box with the bigger bound. (Tags like blur increase bounding box of lines)
    if i == 1
      text, bound = currText, currBound
    else
      windowAssertError text == currText, "You must select the lines that have same text or drawing."
      bound = currBound if bound.w < currBound.w or bound.h < currBound.h
  ), true
  windowAssertError hasClip, "No clip found in the selected lines."
  windowAssertError #clip == 6, "The vectorial clip must have at least 3 points."
  return clip, tagState, bound


-- For 3 points, determine the point of intersection of line passing through first 2 points and a line perpendicular to it passing through 3rd point
intersect_perpendicular = (clip) ->
  x1, y1, x2, y2, x3, y3 = unpack clip
  k = ((x3 - x1) * (x2 - x1) + (y3 - y1) * (y2 - y1)) / ((x2 - x1)^2 + (y2 - y1)^2)
  x = x1 + k * (x2 - x1)
  y = y1 + k * (y2 - y1)
  return x, y


-- Divides a line between 2 points in equal interval (user defined pixels in this case)
divide = (x1, y1, x2, y2, pixel)->
  distance = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
  no_of_section = math.ceil(distance / pixel)
  points = {}
  for i = 0, no_of_section
    k = i / no_of_section
    x = x1 + k * (x2 - x1)
    y = y1 + k * (y2 - y1)
    points[i] or= {}
    points[i]["x"] = x
    points[i]["y"] = y
  return points


-- Determine the clip for each interval
--  (x1, y1)  ---------------------- (x2,y2)
--           |                     |
--  (x1, y4) ----------------------  (x2,y3)
clipCreator = (points, bounds, slope, gradientDirection) ->
  x1, x2 =  bounds[1].x, bounds[2].x
  m = ASS.Draw.Move
  l = ASS.Draw.Line
  clip = {}
  for i = 1, #points
    prevIntercept = points[i-1]["y"] - slope * points[i-1]["x"]
    y1 = slope * x1 + prevIntercept
    y2 = slope * x2 + prevIntercept
    currIntercept = points[i]["y"] - slope * points[i]["x"]
    y4 = slope * x1 + currIntercept
    y3 = slope * x2 + currIntercept

    -- Create overlap in the clip
    if gradientDirection == "up"
      y3 -= 0.75
      y4 -= 0.75
    elseif gradientDirection == "down"
      y1 -= 0.75
      y2 -= 0.75

    clip[i] = ASS\createTag "clip_vect", m(x1, y1), l(x2, y2), l(x2, y3), l(x1, y4)
  return clip


-- If any clip falls outside the text or shape, it'll skew the gradient. So remove them.
removeInvisibleClip = (lines, klip) ->
  newClip = {}
  for i = 1, #klip
    newLine = Line lines[1], lines
    data = ASS\parse newLine
    data\replaceTags klip[i]
    bound = data\getLineBounds!
    table.insert newClip, klip[i] if bound.h != 0
  return newClip


-- Interpolate tags between two lines by a factor
interpolate = (first_line, last_line, tag, factor) ->
  local finalValue
  switch tag
    when "1c", "3c", "4c"
      finalValue = first_line[tag]\copy!
      b1, g1, r1 = first_line[tag]\getTagParams!
      b2, g2, r2 = last_line[tag]\getTagParams!
      finalValue.r.value, finalValue.g.value, finalValue.b.value  = util.extract_color(util.interpolate_color factor, util.ass_color(r1, g1, b1), util.ass_color(r2, g2, b2))
    else
      finalValue = first_line[tag]\lerp last_line[tag], factor
  return finalValue


main = (sub, sel) ->
  res = create_dialog!
  clip, tagState, bounds = prepare_line sub, sel, res
  x, y = intersect_perpendicular(clip)
  x1, y1, x2, y2, x3, y3 = unpack clip
  gradientDirection = "down"
  gradientDirection = "up" if tonumber(y) > tonumber(y3)
  points = divide(x, y, x3, y3 , res.strip)
  slope = (y2-y1)/(x2-x1)
  klip = clipCreator(points, bounds, slope, gradientDirection)

  lines = LineCollection sub, sel
  klip = removeInvisibleClip lines, klip

  -- Stores how many frames between each key line
  frames_per, prev_end_frame = {}, 0
  avg_frame_cnt = #klip/(#lines.lines-1)
  for i = 1, #lines.lines-1
    curr_end_frame = math.ceil i*avg_frame_cnt
    frames_per[i] = curr_end_frame - prev_end_frame
    prev_end_frame = curr_end_frame

  toDelete, count = {}, 1
  lines\runCallback ((lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    toDelete[#toDelete+1] = line
    if i != 1
      first_line = tagState[i-1]
      last_line = tagState[i]
      -- For the number of lines indicated by the frames_per table, create a gradient
      for j = 1, frames_per[i-1]
        factor = frames_per[i-1] < 2 and 1 or (j-1)^res.accel/(frames_per[i-1]-1)^res.accel
        newLine = Line line, lines
        newData = ASS\parse newLine
        newData\replaceTags klip[count]
        count += 1
        for tag in *tags_flat
          newData\replaceTags interpolate(first_line, last_line, tag, factor) if res[tag]
        newData\commit!
        lines\addLine newLine
  ), true
  lines\insertLines!
  lines\deleteLines toDelete
  return [sel[1]+i for i = 0, #klip-1]       -- Return selection of all newly added lines

depctrl\registerMacro main
