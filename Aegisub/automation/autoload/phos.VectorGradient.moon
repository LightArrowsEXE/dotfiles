export script_name = "Vector Gradient"
export script_description = "Magic triangles + blur gradients"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.VectorGradient"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
  },
}
LineCollection, ASS, Functional = depctrl\requireModules!
logger = depctrl\getLogger!
{ :math } = Functional

createGUI = ->
  dialog = {
    {x: 0, y: 0, width: 1, height: 1, class: "checkbox", name: "wedge", label: "Wedge"},
    {x: 0, y: 1, width: 1, height: 1, class: "checkbox", name: "ring", label: "Ring"},
    {x: 0, y: 2, width: 1, height: 1, class: "checkbox", name: "star", label: "star"},
  }
  btn, res = aegisub.dialog.display dialog, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  aegisub.cancel! unless btn
  res


wedge = (data, clip) ->
  -- For 3 points, determine the point of intersection of line passing through first 2 points and a line perpendicular to it passing through 3rd point
  x1, y1, x2, y2, x3, y3 = unpack clip
  k = ((x3 - x1) * (x2 - x1) + (y3 - y1) * (y2 - y1)) / ((x2 - x1)^2 + (y2 - y1)^2)
  x = x1 + k * (x2 - x1)
  y = y1 + k * (y2 - y1)

  length = math.vector2.distance x1, y1, x2, y2
  height = math.vector2.distance x3, y3, x, y
  wedgeBase = 0.09009 * height
  shape = "m 0 0 l 0 #{wedgeBase} "
  local prev
  for i = 0, length + 10, 10
    if i == 0
      prev = i
      continue

    current = i
    wedgeCorner = (prev + i)/2
    current = length if i > length
    wedgeCorner = length if wedgeCorner > length
    prev = i

    shape ..= "#{wedgeCorner} #{height} #{current} #{wedgeBase} "
  shape ..= "#{length} 0 0 0"

  angle = math.atan2(y2-y1, x2-x1)
  angle = math.degrees(-angle)
  drawing = ASS.Draw.DrawingBase{str: shape}

  data\removeSections 2, #data.sections
  data\insertSections ASS.Section.Drawing {drawing}
  data\removeTags { "outline_x", "outline_y", "shadow_x", "shadow_y", "shear_x", "shear_y", "angle_x", "angle_y", "clip_vect"}
  data\replaceTags {ASS\createTag 'position', x1, y1}
  data\replaceTags {ASS\createTag 'origin', x1, y1}
  data\replaceTags {ASS\createTag 'scale_x', 100}
  data\replaceTags {ASS\createTag 'scale_y', 100}
  data\replaceTags {ASS\createTag 'outline', 0}
  data\replaceTags {ASS\createTag 'shadow', 0}
  data\replaceTags {ASS\createTag 'align', 7}
  data\replaceTags {ASS\createTag 'angle', angle}
  data


radial = (data, clip, shape, width) ->
  -- Determing the upper left corner of the bounding box
  x1, y1, x2, y2 = unpack clip
  centerX, centerY = (x1 + x2)/2, (y1 + y2)/2
  diameter = math.vector2.distance x1, y1, x2, y2
  x = centerX - (diameter/2)
  y = centerY - (diameter/2)

  drawing = ASS.Draw.DrawingBase{str: shape}

  data\removeSections 2, #data.sections
  data\insertSections ASS.Section.Drawing {drawing}
  data\removeTags { "origin" ,"outline_x", "outline_y", "shadow_x", "shadow_y", "shear_x", "shear_y", "angle_x", "angle_y", "clip_vect"}
  data\replaceTags {ASS\createTag 'position', x, y}
  data\replaceTags {ASS\createTag 'scale_x', diameter*100/width}
  data\replaceTags {ASS\createTag 'scale_y', diameter*100/width}
  data\replaceTags {ASS\createTag 'outline', 0}
  data\replaceTags {ASS\createTag 'shadow', 0}
  data\replaceTags {ASS\createTag 'align', 7}
  data\replaceTags {ASS\createTag 'angle', 0}
  data


main = (sub, sel) ->
  res = createGUI!
  lines = LineCollection sub, sel
  return if #lines.lines == 0
  lines\runCallback (lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    data = ASS\parse line

    hasClip, clip = false, {}
    clipCount = res.wedge and 3 or 2
    clipTable = data\getTags "clip_vect"
    if #clipTable != 0
      hasClip = true
      for index, cnt in ipairs clipTable[1].contours[1].commands          -- Is this the best way to loop through co-ordinate?
        break if index == clipCount + 1
        x, y = cnt\get!
        table.insert clip, x
        table.insert clip, y
    if hasClip and #clip != 2 * clipCount
      logger\warn "Clip found in line #{line.humanizedNumber} but the clip has less than #{clipCount} points.\nSkipping this line."
      hasClip = false
    return unless hasClip

    if res.wedge
      data = wedge data, clip
    elseif res.ring
      shape = "m 93.7 0.4 b 42 0.4 0 42.4 0 94.1 0 145.9 42 187.9 93.7 187.9 145.5 187.9 187.5 145.9 187.5 94.1 187.5 42.4 145.5 0.4 93.7 0.4 m 93.7 1.4 b 145 1.4 186.5 42.9 186.5 94.1 186.5 145.3 145 186.9 93.7 186.9 42.5 186.9 1 145.3 1 94.1 1 42.9 42.5 1.4 93.7 1.4 m 93.7 9.7 b 47.1 9.7 9.3 47.5 9.3 94.1 9.3 140.7 47.1 178.5 93.7 178.5 140.3 178.5 178.1 140.7 178.1 94.1 178.1 47.5 140.3 9.7 93.7 9.7 m 93.7 11.7 b 139.3 11.7 176.2 48.6 176.2 94.1 176.2 139.7 139.3 176.6 93.7 176.6 48.2 176.6 11.3 139.7 11.3 94.1 11.3 48.6 48.2 11.7 93.7 11.7 m 93.7 19 b 52.3 19 18.6 52.7 18.6 94.1 18.6 135.6 52.3 169.2 93.7 169.2 135.2 169.2 168.8 135.6 168.8 94.1 168.8 52.7 135.2 19 93.7 19 m 93.7 22 b 133.6 22 165.9 54.3 165.9 94.1 165.9 134 133.6 166.3 93.7 166.3 53.9 166.3 21.6 134 21.6 94.1 21.6 54.3 53.9 22 93.7 22 m 93.7 28.4 b 57.4 28.4 28 57.8 28 94.1 28 130.4 57.4 159.9 93.7 159.9 130 159.9 159.5 130.4 159.5 94.1 159.5 57.8 130 28.4 93.7 28.4 m 93.7 32.3 b 127.9 32.3 155.6 59.9 155.6 94.1 155.6 128.3 127.9 156 93.7 156 59.5 156 31.9 128.3 31.9 94.1 31.9 59.9 59.5 32.3 93.7 32.3 m 93.7 37.7 b 62.6 37.7 37.3 63 37.3 94.1 37.3 125.3 62.6 150.6 93.7 150.6 124.9 150.6 150.2 125.3 150.2 94.1 150.2 63 124.9 37.7 93.7 37.7 m 93.7 42.6 b 122.2 42.6 145.3 65.6 145.3 94.1 145.3 122.6 122.2 145.6 93.7 145.6 65.2 145.6 42.2 122.6 42.2 94.1 42.2 65.6 65.2 42.6 93.7 42.6 m 93.7 47 b 67.7 47 46.6 68.1 46.6 94.1 46.6 120.1 67.7 141.2 93.7 141.2 119.7 141.2 140.8 120.1 140.8 94.1 140.8 68.1 119.7 47 93.7 47 m 93.7 52.9 b 116.5 52.9 134.9 71.3 134.9 94.1 134.9 116.9 116.5 135.3 93.7 135.3 70.9 135.3 52.5 116.9 52.5 94.1 52.5 71.3 70.9 52.9 93.7 52.9 m 93.7 56.4 b 72.9 56.4 56 73.3 56 94.1 56 114.9 72.9 131.9 93.7 131.9 114.5 131.9 131.5 114.9 131.5 94.1 131.5 73.3 114.5 56.4 93.7 56.4 m 93.7 63.2 b 110.8 63.2 124.6 77 124.6 94.1 124.6 111.2 110.8 125 93.7 125 76.6 125 62.8 111.2 62.8 94.1 62.8 77 76.6 63.2 93.7 63.2 m 93.7 65.7 b 78 65.7 65.3 78.4 65.3 94.1 65.3 109.8 78 122.6 93.7 122.6 109.4 122.6 122.2 109.8 122.2 94.1 122.2 78.4 109.4 65.7 93.7 65.7 m 93.7 73.5 b 105.2 73.5 114.3 82.7 114.3 94.1 114.3 105.5 105.2 114.7 93.7 114.7 82.3 114.7 73.1 105.5 73.1 94.1 73.1 82.7 82.3 73.5 93.7 73.5 m 93.7 75 b 83.2 75 74.6 83.6 74.6 94.1 74.6 104.6 83.2 113.3 93.7 113.3 104.2 113.3 112.9 104.6 112.9 94.1 112.9 83.6 104.2 75 93.7 75 m 93.7 83.8 b 99.5 83.8 104 88.4 104 94.1 104 99.9 99.5 104.4 93.7 104.4 88 104.4 83.4 99.9 83.4 94.1 83.4 88.4 88 83.8 93.7 83.8 m 93.7 84.3 l 93.7 84.3 89.8 85.1 86.6 87.4 84.5 90.8 83.9 94.1 83.9 94.1 84.7 98 87 101.3 90.4 103.3 93.7 103.9 93.7 103.9 97.6 103.1 100.9 100.9 102.9 97.5 103.5 94.1 103.5 94.1 102.7 90.2 100.5 87 97.1 84.9 93.7 84.3"
      data = radial data, clip, shape, 188
    elseif res.star
      shape = "m 89.2 -0.1 l 91.9 71 116.5 4.3 97.2 72.8 141.2 16.9 101.7 76 160.8 36.5 105 80.5 173.4 61.2 106.7 85.8 177.8 88.5 106.7 91.3 173.4 115.9 105 96.6 160.8 140.6 101.7 101.1 141.2 160.2 97.2 104.3 116.5 172.8 91.9 106 89.2 177.1 86.4 106 61.8 172.8 81.1 104.3 37.1 160.2 76.6 101.1 17.5 140.6 73.4 96.6 4.9 115.9 71.7 91.3 0.6 88.5 71.7 85.8 4.9 61.2 73.4 80.5 17.5 36.5 76.6 76 37.1 16.9 81.1 72.8 61.8 4.3 86.4 71 89.2 -0.1"
      data = radial data, clip, shape, 178
    data\commit!
  lines\replaceLines!

depctrl\registerMacro main
