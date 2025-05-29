export script_name = "svg2ass"
export script_description = "Script that uses svg2ass to convert svg files to ass lines"
export script_version = "1.2.5"
export script_author = "PhosCity"
export script_namespace = "phos.svg2ass"

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
{:list, :string} = Functional

defaultConfig =
  svgOpt: ""
  svgPath: "svg2ass"
  userTags: "\\bord0\\shad0"

-- Modify config
config = depctrl\getConfigHandler defaultConfig
configSetup = ->
  dialog = {
		{x: 0, y: 0,  width: 5,  height: 1, class: "label", label: "Absoulute path of svg2ass executable:"}
		{x: 0, y: 1,  width: 20, height: 3, class: "edit",  name: "svgPath",  value: config.c.svgPath}
		{x: 0, y: 4,  width: 5,  height: 1, class: "label", label: "svg2ass options:"}
		{x: 0, y: 5,  width: 5,  height: 1, class: "label", label: "Default options already used: -S, -E, -T "}
		{x: 0, y: 6,  width: 10, height: 1, class: "label", label: "No processing of options below will be done. Garbage in, Garbage out."}
		{x: 0, y: 7,  width: 20, height: 3, class: "edit",  name: "svgOpt",   value: config.c.svgOpt}
		{x: 0, y: 10, width: 5,  height: 1, class: "label", label: "Custom ASS Tags:"}
		{x: 0, y: 11, width: 10, height: 1, class: "label", label: "Default tags added automatically: \\an7\\pos(0,0)\\p1"}
		{x: 0, y: 12, width: 10, height: 1, class: "label", label: "No processing of tags below will be done. Garbage in, Garbage out."}
		{x: 0, y: 13, width: 20, height: 3, class: "edit",  name: "userTags", value: config.c.userTags}
  }
  btn, res = aegisub.dialog.display dialog, { "Save", "Reset", "Cancel" }
  aegisub.cancel! if btn == "Cancel"
  opt = config.c
  saveSource = res
  saveSource = defaultConfig if btn == "Reset"
  with saveSource
    opt.svgPath = .svgPath
    opt.svgOpt = .svgOpt
    opt.userTags = .userTags
  config\write!


createGUI = ->
  dialog = {
    {x: 0, y: 0, width: 7, height: 5, class: "textbox",  name: "txtbox",    text: "have ass, will typeset"},
    {x: 0, y: 6, width: 1, height: 1, class: "checkbox", name: "drawing",   label: "drawing          ",      value: true, hint: "Convert svg to drawing"},
    {x: 1, y: 6, width: 1, height: 1, class: "checkbox", name: "clip",      label: "clip          ",         hint: "Convert svg to clip"},
    {x: 2, y: 6, width: 1, height: 1, class: "checkbox", name: "iclip",     label: "iclip          ",        hint: "Convert svg to iclip"},
		{x: 3, y: 6, width: 1, height: 1, class: "checkbox", name: "pasteover", label: "pasteover",              hint: "Convert svg but paste shape date over selected lines" },
  }
  btn, res = aegisub.dialog.display(dialog, {"Import", "Textbox", "Cancel"})
  aegisub.cancel! if btn == "Cancel"
  if btn == "Import"
    return res, false
  return res, true


-- Surveys the selected lines. Returns the least starting time, max end time and a style among them
reconnaissance = (sub, sel) ->
  startTime, endTime, styleList = math.huge, 0, {}
  for i in *sel
    startTime = math.min(startTime, sub[i].start_time)
    endTime = math.max(endTime, sub[i].end_time)
    styleList[#styleList + 1] = sub[i].style
  styleList = list.uniq styleList

  local style
  if #styleList < 2
    style = styleList[1]
  else
    dialog = {
      {x: 0, y: 0, width: 1, height: 1, class: "label", label: "Your selection has multiple styles. Please select one:"},
      {x: 0, y: 1, width: 1, height: 1, class: "dropdown", name: "stl", value: styleList[1], items: styleList}
    }
    btn, res = aegisub.dialog.display dialog, {"OK", "Cancel"}
    aegisub.cancel! if btn == "Cancel" or btn == nil
    style = res.stl
  return startTime, endTime, style


-- Check if svg2ass exists in the path given in config
checkSvg2assExists = (path) ->
  handle = io.open(path)
  if handle
    io.close!
    return
  logger\log "svg2ass executable not found. Please install it and try again."
  aegisub.cancel!


-- Execute the command
runCommand = (command) ->
  handle = io.popen(command)
  output = handle\read("*a")
  handle\close!
  return output


main = (sub, sel) ->
  config\load!
  opt = config.c

  res, useTextBox = createGUI!
  startTime, endTime, style = reconnaissance(sub, sel)

  local result
  if useTextBox
    --Grab whatever is in the textbox
    result = res.txtbox
    unless result\match "^Dialogue"
      logger\log "Please replace the textbox content with svg2ass output."
      aegisub.cancel!
  else
    -- Check if svg2ass exists
    checkSvg2assExists(opt.svgPath)

    -- Select svg file
    pathsep = package.config\sub(1, 1)
    filename = aegisub.dialog.open("Select svg file", "", aegisub.decode_path("?script")..pathsep, "Svg files (.svg)|*.svg", false, true)
    aegisub.cancel! unless filename

    -- Generate svg2ass command
    command = opt.svgPath
    if opt.svgOpt
      command ..= " #{opt.svgOpt}"
    command ..= ' "'..filename..'"'

    -- Execute the command and grab it's result
    result = runCommand(command)

  lines = LineCollection sub, sel
  return if #lines.lines == 0
  result = list.map string.split(result, "\n"), (value) -> value unless value == ""

  -- Pastes the shape data over the selected lines while keeping the original tags
  if res.pasteover
    if #lines.lines ~= #result
      logger\log "Number of selected lines is not equal to output lines. Pasteover failed."
      aegisub.cancel!

    result = [x\match "}([^{]+)" for x in *result]
    lines\runCallback ((lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!
      data = ASS\parse line

      shape = result[i]
      drawing = ASS.Draw.DrawingBase{str: shape}
      if res.drawing
        data\stripText!
        if (data\getSectionCount ASS.Section.Drawing) == 0
          data\replaceTags {ASS\createTag "align", 7}
          data\replaceTags {ASS\createTag "position", 0, 0}
        data\stripDrawings!
        data\insertSections ASS.Section.Drawing {drawing}
      elseif res.clip
        data\replaceTags {ASS\createTag "clip_vect", drawing}
      elseif res.iclip
        data\replaceTags {ASS\createTag "iclip_vect", drawing}
      data\commit!
    ), true
    lines\replaceLines!
    return lines\getSelection!
  else
    -- Add shapes as new lines
    for ln in *(list.reverse result)
      prefix, tags, text = ln\match "([^{]+)({[^}]+})(.*){\\p0}"
      primaryColor = tags\match("\\1c&H%x+&")\gsub("\\1c&", "\\c&")
      tags = "{\\an7\\pos(0,0)#{opt.userTags}#{primaryColor}\\p1}"

      -- Convert shape to clip
      if res.clip
        tags = tags\gsub "\\p1", "\\clip(#{text})\\p1"
        text = ""
      -- Convert shape to iclip
      elseif res.iclip
        tags = tags\gsub "\\p1", "\\iclip(#{text})\\p1"
        text = ""

      newLine = ASS\createLine {
        prefix..tags..text
        lines
        start_time: startTime
        end_time: endTime
        style: style
      }
      lines\addLine newLine, nil, true, sel[1]
    lines\insertLines!
    return [x for index, x in ipairs lines\getSelection! when index > #sel]


depctrl\registerMacros({
  {"Run", "Run the script", main},
  {"Config", "Configuration for e script", configSetup}
})
