export script_name = "Move Along Path"
export script_description = "Moves text along a path specified in a \\clip. Currently only works on fbf lines."
export script_version = "0.2.1"
export script_author = "line0"
export script_namespace = "l0.MoveAlongPath"

DependencyControl = require "l0.DependencyControl"
version = DependencyControl {
  feed: "https://raw.githubusercontent.com/TypesettingTools/line0-Aegisub-Scripts/master/DependencyControl.json",
  {
    "aegisub.util",
    {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"a-mo.Line", version: "1.5.3", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.4.0", url: "https://github.com/TypesettingTools/ASSFoundation",
      feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"l0.Functional", version: "0.5.0", url: "https://github.com/TypesettingTools/Functional",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
    "Yutils"
  }
}
util, LineCollection, Line, ASS, Functional, Yutils = version\requireModules!
{:list, :math, :string, :table, :unicode, :util, :re } = Functional
logger = version\getLogger!

getLengthWithinBox = (w, h, angle) ->  -- currently unused because only horizontal metrics are being used
  return 0 if w == 0 or h == 0
  angle %= 180
  return w if angle == 0
  return h if angle == 90

  angle = math.rad angle > 90 and 180-angle or angle
  A = math.atan2 h, w
  a, b = w, h

  if angle < A
    b =  w * math.tan angle
  elseif angle > A
    a = h
    b = h / math.tan angle

  return Yutils.math.distance a,b

process = (sub,sel,res) ->
  aegisub.progress.task("Processing...")

  lines = LineCollection sub,sel
  id = util.uuid!

  -- get total duration of the fbf lines
  totalDuration = -lines.lines[1].duration
  lines\runCallback (lines, line) ->
    totalDuration += line.duration

  startDist, metricsCache, path, posOff, angleOff, totalLength = 0, {}
  linesToDelete, lineCnt, finalLineCnt, firstLineNum = {}, #lines.lines, 0
  alignOffset = {
    (w, a) -> w   * math.cos math.rad a,  -- right
    -> 0,                                 -- left
    (w, a) -> w/2 * math.cos math.rad a,  -- center
  }

  lineCb = (lines, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!

    linesToDelete[i], orgText = line, line.text
    ass = ASS\parse line
    if i == 1 -- get path ass and relative position/angle from first line
      path = ass\removeTags({"clip_vect","iclip_vect"})[1]
      logger\assert path, "Error: couldn't find \\clip containing path in first line, aborting."
      angleOff = path\getAngleAtLength 0
      posOff = path.contours[1].commands[1]\get!
      totalLength = path\getLength!
      firstLineNum = line.number

    ass\reverse! if res.reverseLine

    -- split line by characters
    charOff, charLines = 0, ass\splitAtIntervals 1, 4, false
    for j = 1, #charLines
      charAss, length = charLines[j].ASS, startDist + charOff
      -- get font metrics
      w = charAss\getTextExtents!
      -- calculate new position and angle
      targetPos = path\getPositionAtLength length, true
      angle = path\getAngleAtLength(length + w/2, true) or path\getAngleAtLength length, true
      -- stop processing this frame if he have reached the end of the path
      break unless targetPos
      -- get tags effective as of the first section (we know there won't be any tags after that)
      effTags = charAss.sections[1]\getEffectiveTags(true, true, false).tags

      -- calculate final rotation and write tags
      if res.aniFrz
        angle\add 180 if res.flipFrz
        charAss\replaceTags angle

      -- calculate how much "space" the character takes up on the line
      -- and determine the distance offset for the next character
      -- this currently only uses horizontal metrics so it breaks if you disable rotation animation
      charOff += w

      if res.aniPos
        an = effTags.align\get!
        targetPos\add alignOffset[an%3 + 1](w, angle.value), alignOffset[an%3 + 1](w, angle.value+90)

        if res.relPos
          targetPos\sub posOff
          targetPos\add effTags.position

        charAss\replaceTags targetPos

      charAss\commit!

      if charAss\getLineBounds(true).w != 0
        charLines[j]\setExtraData version.namespace, {settings: res, :id, orgLine: j==1 and orgText or nil}
        lines\addLine charLines[j], nil, true, firstLineNum + finalLineCnt
        finalLineCnt += 1

    framePct = res.cfrMode and 1 or lineCnt * line.duration / totalDuration
    time = (i^res.accel) / (lineCnt^res.accel)
    startDist = util.interpolate time*framePct, 0, totalLength
    aegisub.progress.set i * 100 / lineCnt

  lines\runCallback lineCb, true
  lines\deleteLines linesToDelete
  lines\insertLines!

hasClip = (sub, sel, active) ->
  return false if #sel == 0
  firstLine = Line sub[sel[1]]
  ass = ASS\parse firstLine
  if 0 == #ass\getTags {"clip_vect","iclip_vect"}
    return false, "No \\clip or \\iclip containing the path found in first line of the selection."

  return true

getExtraData = (line) ->
  if line.extra and line.extra[script_namespace]
    extra = json.decode line.extra[script_namespace]
    return extra if extra.id

hasUndoData = (sub, sel, active) ->
  for i = 1, #sel
    return true if sel[i] and getExtraData sub[sel[i]]
  return false

undo = (sub, sel) ->
  ids, toDelete, j = {}, {}, 1
  for i = 1, #sel
    extra = getExtraData sub[sel[i]]
    if extra
      ids[extra.id] = true

  sel = {}
  for i, line in ipairs sub
    extra = getExtraData line
    if extra and ids[extra.id]
      if extra.orgLine
        sel[j], j = i, j+1
      else toDelete[#toDelete+1] = i

  lines = LineCollection sub,sel
  lines\runCallback (lines, line) ->
    line.text = line\getExtraData(script_namespace).orgLine
    line.extra[script_namespace] = nil

  lines\replaceLines!
  sub.delete toDelete

showDialog = (sub, sel) ->
  dlg = {
    {
      class: "label", label: "Select which tags are to be animated along the path specified as a \\clip:",
      x: 0, y: 0, width: 8, height: 1,
    },
    {
      class: "checkbox", name: "aniPos", label: "Animate Position:",
      x: 0, y: 1, width: 4, height: 1, value: true
    },
    {
      class: "label", label: "Acceleration:",
      x: 4, y: 1, width: 3, height: 1,
    },
    {
      class: "floatedit", name: "accel",
      x: 7, y: 1, width: 1, height: 1, value: 1.0, step: 0.1
    },
    {
      class: "checkbox", name: "relPos", label: "Offset existing position",
      x: 4, y: 2, width: 4, height: 1, value: false
    },
    {
      class: "checkbox", name: "cfrMode", label: "CFR mode (ignores frame timings)",
      x: 4, y: 3, width: 4, height: 1, value: true
    },
    {
      class: "checkbox",
      name: "aniFrz", label: "Animate Rotation",
      x: 0, y: 5, width: 4, height: 1, value: true
    },
    {
      class: "checkbox",
      name: "flipFrz", label: "Rotate final lines by 180°",
      x: 4, y: 5, width: 4, height: 1, value: false
    },
    {
      class: "label", label: "Options:",
      x: 0, y: 7, width: 4, height: 1, value: false
    },
    {
      class: "checkbox", name: "reverseLine", label: "Reverse Line Contents",
      x: 4, y: 7, width: 4, height: 1, value: false
    }
  }

  btn, res = aegisub.dialog.display dlg
  process sub,sel,res if btn

version\registerMacros {
  {script_name, nil, showDialog, hasClip},
  {"Undo", nil, undo, hasUndoData}
}
