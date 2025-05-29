export script_name = "Auto Fade"
export script_description = "Automatically determine fade in and fade out"
export script_version = "1.1.2"
export script_author = "PhosCity"
export script_namespace = "phos.AutoFade"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"a-mo.DataWrapper", version: "1.0.2", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    "aegisub.clipboard"
  },
}
LineCollection, DataWrapper, ASS, clipboard = depctrl\requireModules!
logger = depctrl\getLogger!


windowAssertError = ( condition, errorMessage ) ->
  if not condition
    logger\log errorMessage
    aegisub.cancel!


createGUI = (coordinateValue, dataLabel, data, processType) ->
  dialog = {
    {x: 0, y: 0, width: 25, height: 1, class: "label",    label: dataLabel or "Paste data or enter a filepath."},
		{x: 0, y: 1, width: 25, height: 5, class: "textbox",  hint: "Paste data or the path to a file containing it. No quotes or escapes.", name: "data",                 value: data or "" }
    {x: 0, y: 6, width: 25, height: 1, class: "dropdown", name: "processType", value: processType or "Single Co-ordinate", items: {"Single Co-ordinate", "Tracking Data"} },
    {x: 0, y: 7, width: 1,  height: 1, class: "label",    label: "Co-ordinate"},
    {x: 1, y: 7, width: 24, height: 1, class: "edit",     name: "coordinate", value: coordinateValue},
  }
  btn, res = aegisub.dialog.display dialog, {"Fade &in", "Fade &out", "&Both", "&Cancel"}
  if btn == nil or btn == "&Cancel"
    aegisub.cancel!
  else
    return res, btn


getColor = (curFrame, x, y) ->
  frame = aegisub.get_frame(curFrame, false)
  color = frame\getPixelFormatted(x, y)
  color


extractRGB = (color) ->
  b, g, r = color\match "&H(..)(..)(..)&"
  tonumber(b, 16), tonumber(g, 16), tonumber(r, 16)


euclideanDistance = (color1, color2) ->
  b1, g1, r1 = extractRGB(color1)
  b2, g2, r2 = extractRGB(color2)
  math.sqrt((b1-b2)^2 + (g1-g2)^2 + (r1-r2)^2)


determineFadeTime = (fadeType, startFrame, endFrame, targetColor, pos) ->
  local fadeTime
  for i = startFrame, endFrame
    color = getColor(i, pos["x"][i], pos["y"][i])
    dist = euclideanDistance(color, targetColor)
    if fadeType == "Fade in" and dist < 5
      fadeTime = math.floor((aegisub.ms_from_frame(i+1)+ aegisub.ms_from_frame(i))/2)
      break
    elseif fadeType == "Fade out" and dist > 5
      fadeTime = math.floor((aegisub.ms_from_frame(i-1)+ aegisub.ms_from_frame(i))/2)
      break
  windowAssertError fadeTime, "#{fadeType} time could not be determined."
  fadeTime


main = (sub, sel) ->
  windowAssertError aegisub.get_frame, "You are using unsupported Aegisub.\nPlease use arch1t3cht's Aegisub for this script."
  windowAssertError aegisub.project_properties!.video_file != "", "No video open. Exiting."
  fadeLimit = (aegisub.ms_from_frame(2)-aegisub.ms_from_frame(1))/2  -- Fade time below this can be negleted.
  trackingData = DataWrapper!

  lines = LineCollection sub, sel
  windowAssertError #lines.lines == 1, "Because of how this script works, it can only be run in one line at a time."
  lines\runCallback (_, line) ->
    local removeClip, fadein, fadeout, btn, dataLabel, processType
    totalFrames = line.endFrame - line.startFrame
    pos = {x: {}, y: {}}

    currentFrame = aegisub.project_properties!.video_position
    windowAssertError currentFrame >= line.startFrame, "Your current video position is before the start time of the line."
    windowAssertError currentFrame <= line.endFrame, "Your current video position is after the end time of the line."

    -- Try to see if there is a single point clip in the line
    xCord, yCord = line.text\match "\\i?clip%(m ([%d.]+) ([%d.]+)%s*%)"
    if xCord
      removeClip = true
    else -- Since there is no single point clip, try to see if there is coordinate in clipboard
      xCord, yCord = (clipboard.get! or "")\match "([%d.]+),([%d.]+)"

    -- GUI, Tracking Data, Relative Frames
    while true
      rawInputData = clipboard.get! or ""
      parsed = trackingData\bestEffortParsingAttempt rawInputData, lines.meta.PlayResX, lines.meta.PlayResY
      res, btn = createGUI (xCord and "#{xCord},#{yCord}" or ""), dataLabel, (parsed and rawInputData or nil), processType

      -- Co-ordinate validation
      xCord, yCord = res.coordinate\match "([%d.]+),([%d.]+)"
      if not xCord and not yCord
        windowAssertError false, "Invalid co-ordinate. The format of the co-ordinate is x,y"

      -- Bail out early if we don't need to deal with tracking data
      if res.processType == "Single Co-ordinate"
        pos["x"] = {i, xCord for i = line.startFrame, line.endFrame - 1}
        pos["y"] = {i, yCord for i = line.startFrame, line.endFrame - 1}
        break
      else
        processType = res.processType

      if res.data == ""
        dataLabel = "As far as I can tell, you've forgotten to give me any motion data."
        continue

      unless trackingData\bestEffortParsingAttempt res.data, lines.meta.PlayResX, lines.meta.PlayResY
        dataLabel = "You put something in the data box\nbut it is wrong in ways I can't imagine."
        continue

      unless trackingData.dataObject\checkLength totalFrames
        dataLabel = "The length of your data (#{trackingData.dataObject.length} frames) doesn't match\nthe length of your lines (#{totalFrames} frames)."
        continue

      -- Add the current frame as reference frame to get relative positions
      trackingData.dataObject\addReferenceFrame currentFrame - lines.startFrame + 1
      with trackingData.dataObject
        count = 1
        for i = line.startFrame, line.endFrame - 1
          pos["x"][i] = xCord + (.xPosition[count] - .xStartPosition)
          pos["y"][i] = yCord + (.yPosition[count] - .yStartPosition)
          count += 1
      break

    targetColor = getColor(currentFrame, xCord, yCord)
    if btn == "Fade &in" or btn == "&Both"
      fadeinTime = determineFadeTime("Fade in", line.startFrame, currentFrame, targetColor, pos)
      fadein = fadeinTime - line.start_time
      fadein = 0 if fadein < fadeLimit

    if btn == "Fade &out" or btn == "&Both"
      -- Speed up calculation of fade out by skipping having to step through each frame
      while true
        fr = math.floor((currentFrame + line.endFrame) / 2)
        color = getColor(fr, pos["x"][fr], pos["y"][fr])
        if euclideanDistance(color, targetColor) < 5
          currentFrame = fr
        else
          break
        break if line.endFrame - currentFrame < 10
      fadeoutTime = determineFadeTime("Fade out", currentFrame, line.endFrame, targetColor, pos)
      fadeout = line.end_time - fadeoutTime
      fadeout = 0 if fadeout < fadeLimit

    data = ASS\parse line
    -- If the line already has fad tag and you only choose to determine fade in or fade out, the other time will remain unchanged.
    fad = data\getTags "fade_simple"
    if #fad != 0 and btn != "&Both"
      t1, t2 = fad[1]\getTagParams!
      fadein = t1 if btn == "Fade &out"
      fadeout = t2 if btn == "Fade &in"

    if fadein or fadeout
      fadein or= 0
      fadeout or= 0
      data\removeTags {"clip_vect", "iclip_vect"} if removeClip
      if fadein != 0 or fadeout != 0
        data\replaceTags {ASS\createTag "fade_simple", fadein, fadeout}
      data\commit!
    else
      windowAssertError false, "Neither fade in nor fade out could be determined."
  lines\replaceLines!

depctrl\registerMacro main
