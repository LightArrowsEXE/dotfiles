export script_name = "KFX"
export script_description = "0x Template Assistant"
export script_author = "PhosCity"
export script_namespace = "phos.kfx"
export script_version = "1.0.0"

haveDepCtrl, DependencyControl = pcall(require, "l0.DependencyControl")
local depctrl
local fun
if haveDepCtrl
  depctrl = DependencyControl({
    feed: "",
    {
      {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
        feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
    }
  })
  fun = depctrl\requireModules!
require("karaskel")

newLine = {}
defaultLine = { actor: "", class: "dialogue", comment: true,  effect: "", start_time: 0, end_time: 0, layer: 0, margin_l: 0, margin_r: 0, margin_t: 0, section: "[Events]", style: "Default", text: ""}
kontinue = true
proceed = true

table_contains = (tbl, x) ->
	for item in *tbl
		return true if item == x
	return false

-- Collect some info like variable, function names and actor of all template lines.
reconnaissance = (subs) ->
  info = {
    func: {},
    vars: {},
    actor: {},
  }
  for i = 1, #subs
    continue unless subs[i].class == "dialogue"
    line  = subs[i]
    effect = line.effect
    continue unless effect\match("^code") or effect\match("^template") or effect\match("^mixin") or effect\match("^kara")
    s = line.text
    if effect\match "^code"
      for key in string.gmatch(s, "function ([%w%._]+)")
        table.insert(info.func, key) unless table_contains(info.func, key)
      for key in string.gmatch(s, "(%w+%.%w+) = function")
        table.insert(info.func, key) unless table_contains(info.func, key)
      s = s\gsub("if.-end", "")\gsub("for.-end", "")\gsub("function%s+%(%)", "")\gsub("(function[^)]+%)).-end", "%1")
      for key in string.gmatch(s, "([%w_%.%[%]]-[^=~%(%)])%s=.[^func]")
        if key ~= "]"
          table.insert(info.vars, key) unless table_contains(info.vars, key)
      for key in string.gmatch(s, "([%w_%.%[%]]+[^=~%(%)%s])=.[^func]")
          table.insert(info.vars, key) unless table_contains(info.vars, key)
    if line.actor != ""
      table.insert(info.actor, line.actor) unless table_contains(info.actor, line.actor)
  return info

-- Formats the multiline lua code to single code
formatLines = (line) ->
  lineTable = fun.string.split line, "\n"
  finalLine = ""
  for line in *lineTable
    continue if line == "" or line == nil
    line = line\gsub "^[%s]+", ""
    finalLine ..= "; #{line}"
  return finalLine\gsub("(function[^)]+%));", "%1")\gsub("do;", "do")\gsub("then;", "then")\gsub("else;", "else")\gsub("^;%s?", "")

-- Modify template lines
modify = (subs, sel, act) ->
  line = subs[act]
  text = line.text
  effect = line.effect
  return unless effect\match("^code") or effect\match("^template") or effect\match("^mixin")
  local current_line
  if effect\match("^code")
    spc, current_line = "", ""
    count = 0
    text = text\gsub("(function[^)]+%))", "%1;")\gsub("do", "do;")\gsub("then", "then;")\gsub("else%s", "else;")\gsub("%send", ";end;")
    text_tbl = fun.string.split text, ";"
    for item in *text_tbl
      item = item\gsub "^[%s]+", ""
      continue if item == "" or item == nil
      spc = string.rep(" ", count*6)
      if item\match("function") or item\match("^if%s") or item\match("for%s")
        count += 1
      if item\match("else")
        count -= 1
        spc = string.rep(" ", count*6)
        count += 1
      if item\match("end")
        count -= 1
        spc = string.rep(" ", count*6)
      current_line ..= spc..item.."\n"
  else
    current_line = text\gsub("{([^\\])", "{\n%1")\gsub("}", "\n}")\gsub("\\", "\n\\")\gsub("(\\t%b())", "\n%1\n")\gsub("^\n", "")\gsub("\n\n\n", "\n\n")

  _, lineHeight = current_line\gsub("\n", "\n")
  dlg = {
    { x: 0, y: 0, class: "label", label: "Modify your lines below:" },
    { x: 0, y: 1, class: "textbox", value: current_line, name: "code", width: 35, height: math.max(lineHeight*0.7, 10) },
  }
  btn, res = aegisub.dialog.display(dlg, {"Modify", "Cancel"}, {"ok": "Modify", "Cancel": "Cancel"})
  if btn
    if effect\match("^code")
      line.text = formatLines(res["code"])
    else
      line.text = res["code"]\gsub("^ *", "")\gsub(" *$", "")\gsub(" *\n", "")\gsub("{}", "")
    subs[act] = line


-- Select line markers
windowOne = () ->
  codeItems = {"once", "line", "syl", "char", "word"}
  templateItems = {"line", "syl", "char", "word"}
  proceed = true
  dlg = {
    { x: 0, y: 0, class: "checkbox", name: "code", label: "code", hint: "excutes this as a lua code", },
    { x: 1, y: 0, class: "dropdown", name: "code_opt", value: "", items:codeItems, width: 10 },
    { x: 0, y: 1, class: "checkbox", name: "template", label: "template", hint: "template for new effects", },
    { x: 1, y: 1, class: "dropdown", name: "template_opt", value: "", items:templateItems, width: 10 },
    { x: 0, y: 2, class: "checkbox", name: "mixin", label: "mixin", hint: "modify the output of template", },
    { x: 1, y: 2, class: "dropdown", name: "mixin_opt", value: "", items:templateItems, width: 10 },
  }
  buttons = { "Next", "Insert", "Replace", "Modify", "Cancel" }
  btn, res = aegisub.dialog.display(dlg, buttons)
  if btn == "Cancel"
    aegisub.cancel!
  if btn != "Modify"
    if res.code
      newLine.effect = "code #{res.code_opt}"
    elseif res.template
      newLine.effect = "template #{res.template_opt}"
    elseif res.mixin
      newLine.effect = "mixin #{res.mixin_opt}"
    else
      aegisub.log "You should check one option.\n"
      proceed = false
    if res.code_opt == "" and res.template_opt == "" and res.mixin_opt == ""
      aegisub.log "You should choose an option in the dropdown menu.\n"
      proceed = false
  return btn

-- Select modifiers
windowTwo = (info) ->
  globalModifier = { "style", "anystyle", "actor", "noactor", "if", "unless", "loop", "noblank" }
  mixinModifier = { "t_actor", "no_t_actor", "layer", "prefix" }
  templateModifier = { "keepspace", "nomerge" }
  editableModifier = { "style", "actor", "if", "unless", "loop", "t_actor", "layer", "prefix" }

  lineType = newLine.effect\match "^([%w]+)"
  tbl = globalModifier
  switch lineType
    when "mixin"
      tbl = fun.list.join tbl, mixinModifier
    when "template"
      tbl = fun.list.join tbl, templateModifier

  dlg ={{ x: 0, y: 0, class: "label", width: 10, label: "You can proceed without selecting any modifier." }}

  for item in *tbl
    row = dlg[#dlg].y + 1
    dlg[#dlg+1] = { x: 0, y: row, class: "checkbox", label: item, name: item }
    if table_contains(editableModifier, item)
      dlg[#dlg+1] = { x: 1, y: row, class: "edit", name: item.."edit", value: "", width: 10 }

  -- For anything extra that user might want to input
  row = dlg[#dlg].y + 1
  dlg[#dlg+1] = { x: 0, y: row, class: "checkbox", label: "Extra parameters", name: "extra" }
  dlg[#dlg+1] = { x: 1, y: row, class: "edit", name: "extraedit", value: "", width: 10 }

  buttons = { "Next", "Insert", "Replace", "Cancel" }
  btn, res = aegisub.dialog.display(dlg, buttons)
  if btn == "Cancel"
    aegisub.cancel!
  for item in *tbl
    if res[item]
      mod = " "..item
      if table_contains(editableModifier, item)
        if res[item.."edit"] == ""
          aegisub.log "You need to add more info to the textbox of the modifier"
          aegisub.cancel!
        mod ..= " "..res[item.."edit"]
      newLine.effect ..= mod
  if res.extra and res["extraedit"]
    newLine.effect ..= " "..res["extraedit"]

  return btn

-- Write actual template
windowThree = (info) ->
  proceed = true
  lineType = newLine.effect\match "^([%w]+)"
  local btn
  if lineType == "code"
    dlg = {
      { x: 0, y: 0, class: "label", label: "Write your code in the textbox", width: 5  },
      { x: 0, y: 1, class: "label", label: "If you're writing variables, you can write one variable per line", width: 10  },
      { x: 0, y: 2, class: "label", label: "If you're writing a function, you can format it as you'd in your IDE", width: 10  },
      { x: 0, y: 3, class: "label", label: "You can indent with tabs (or spaces) if you like that visually.", width: 5  },
      { x: 0, y: 4, class: "textbox", value: "", width: 14, height: 10, name: "code"  },
      { x: 11, y: 0, class: "label", label: "Color Picker", width: 2},
      { x: 11, y: 1, class: "label", label: "For Copying Purpose only", width: 3},
      { x: 13, y: 0, class: "color" },
    }
    buttons = { "Insert", "Replace", "Cancel" }
    btn, res = aegisub.dialog.display(dlg, buttons)
    aegisub.cancel! if btn == "Cancel"
    finalLine = formatLines(res["code"])
    newLine.text = finalLine
  else
    tagGroup = { "r", "c", "3c", "4c", "alpha", "1a", "3a", "4a", "bord", "shad", "fs", "fsp", "blur", "be", "fscx", "fscy", "xbord", "ybord", "xshad", "yshad", "fax", "frx", "fry", "frz",  "an", "i", "b" }
    tagChunk = fun.list.chunk tagGroup, 8
    dlg1 = {}
    col = 0
    for group in *tagChunk
      row = 0
      for tag in *group
        dlg1[#dlg1+1] = { x: col, y: row, class: "checkbox", label: tag, name: tag }
        if tag != "r"
          dlg1[#dlg1+1] = { x: col+1, y: row, class: "edit", name: tag.."value", width: 2, value: "" }
        row += 1
      col += 3
    row = 8
    inline = {"orgline.layer", "orgline.start_time", "orgline.end_time", "orgline.duration", "orgline.style", "orgline.actor",
    "orgline.eff_margin_l", "orgline.eff_margin_r", "orgline.eff_margin_t", "orgline.eff_margin_b", "orgline.eff_margin_v", "#orgline.syls", "orgline.li/$li", "orgline.left",
    "orgline.center", "orgline.right", "orgline.top", "orgline.middle", "orgline.bottom", "orgline.width", "orgline.height", "syl.start_time", "syl.end_time",
    "syl.duration", "syl.width", "syl.height"}
    funcvars = { "==FUNCTIONS==" }
    for item in *info.func
      table.insert(funcvars, item)
    table.insert(funcvars, "==VARIABLES==")
    for item in *info.vars
      table.insert(funcvars, item)
    table.insert(funcvars, "==ACTORS==")
    for item in *info.actor
      table.insert(funcvars, item)
    dlg2 = {
      { x: 9, y: 3, class: "label", label: "For reference and copying only", width: 4 },
      { x: 9, y: 4, class: "label", label: "Color Picker" },
      { x: 10, y: 4, class: "color", width: 2 },
      { x: 9, y: 5, class: "label", label: "Alpha" },
      { x: 10, y: 5, class: "dropdown", items: { "&H00&", "&H10&", "&H20&", "&H30&", "&H40&", "&H50&", "&H60&", "&H70&", "&H80&", "&H90&", "&HA0&", "&HB0&", "&HC0&", "&HD0&", "&HE0&", "&HF0&", "&HF8&", "&HFF&" }, value: "&H00&", width: 2 },
      { x: 9, y: 6, class: "label", label: "Func/Vars" },
      { x: 10, y: 6, class: "dropdown", items: funcvars, value: "", width: 2 },
      { x: 9, y: 7, class: "dropdown", items: inline, value: inline[1], width: 3 },
      { x: 0, y: row, class: "checkbox", label: "Additional:", name: "extra"},
      { x: 1, y: row, class: "edit", name: "extravalue", width: 11},
      { x: 0, y: row+1, class: "checkbox", label: "fad", name: "fad"},
      { x: 1, y: row+1, class: "floatedit", name: "fadx", width: 2 },
      { x: 3, y: row+1, class: "floatedit", name: "fady", width: 3 },
      { x: 6, y: row+1, class: "checkbox", label: "relayer", name: "relayer" },
      { x: 7, y: row+1, class: "edit", name: "relayervalue", width: 5 },
      { x: 0, y: row+2, class: "checkbox", label: "retime", name: "retime" },
      { x: 1, y: row+2, class: "dropdown", name: "retimemode", width: 2, items: {"syl", "presyl", "postsyl", "line", "preline", "postline", "start2syl", "syl2end", "presyl2postline", "preline2postsyl", "delta", "set"}, value: "" },
      { x: 3, y: row+2, class: "edit", name: "retimestart", width: 4 },
      { x: 7, y: row+2, class: "edit", name: "retimeend", width: 5 },
      { x: 0, y: row+3, class: "checkbox", label: "pos", name: "pos"},
      { x: 1, y: row+3, class: "edit", name: "posx", width: 5 },
      { x: 6, y: row+3, class: "edit", name: "posy", width: 6 },
      { x: 0, y: row+4, class: "checkbox", label: "move", name: "move"},
      { x: 1, y: row+4, class: "edit", name: "movex1", width: 2 },
      { x: 3, y: row+4, class: "edit", name: "movey1", width: 1 },
      { x: 4, y: row+4, class: "edit", name: "movex2", width: 2 },
      { x: 6, y: row+4, class: "edit", name: "movey2", width: 1 },
      { x: 7, y: row+4, class: "edit", name: "movet1", width: 2 },
      { x: 9, y: row+4, class: "edit", name: "movet2", width: 1 },
      { x: 0, y: row+5, class: "label", label: "If you tick transform, current lines will be saved and dialog will be reloaded for new values", width: 9 },
      { x: 0, y: row+6, class: "checkbox", label: "t", name: "transform" },
      { x: 1, y: row+6, class: "edit", name: "transformt1", width: 5 },
      { x: 6, y: row+6, class: "edit", name: "transformt2", width: 5 },
      { x: 11, y: row+6, class: "floatedit", name: "transformaccel", value: 1 },
      { x: 0, y: row+7, class: "label", label: "You can view use the following to get info as well as edit if you notice any mistake.", width: 9 },
      { x: 0, y: row+8, class: "label", label: "Effect" },
      { x: 1, y: row+8, class: "edit", name: "effect", width: 5, value: newLine.effect },
      { x: 6, y: row+8, class: "label", label: "Actor" },
      { x: 7, y: row+8, class: "edit", name: "actor", width: 5, value: newLine.actor },
      { x: 0, y: row+9, class: "label", label: "Text" },
      { x: 1, y: row+9, class: "textbox", name: "text", width: 11, height: 3, value: newLine.text\gsub("TransformPlaceHolder", "") },
    }

    dlg = fun.list.join dlg1, dlg2
    buttons = { "Next", "Insert", "Replace", "Cancel" }
    btn, res = aegisub.dialog.display(dlg, buttons)
    aegisub.cancel! if btn == "Cancel"
    taglist, trns = "{", ""
    for tag in *tagGroup
      if tag == "r"
        taglist ..= "\\#{tag}" if res[tag]
      else
        taglist ..= "\\#{tag}#{res[tag.."value"]}" if res[tag]
    if res["relayer"]
      taglist = "!relayer(#{res["relayervalue"]})!#{taglist}"
    if res["retime"]
      taglist = "!retime(#{res["retimemode"]},#{res["retimestart"]},#{res["retimeend"]})!#{taglist}"
    if res["fad"]
      taglist ..= "\\fad(#{res["fadx"]},#{res["fady"]})"
    if res["pos"]
      taglist ..= "\\pos(#{res["posx"]},#{res["posy"]})"
    if res["move"]
      taglist ..= "\\move(#{res["movex1"]},#{res["movey1"]},#{res["movex2"]},#{res["movey2"]},#{res["movet1"]},#{res["movet2"]})"
    if res["extra"]
      taglist ..= "#{res["extravalue"]}"
    if res["transform"]
      proceed = false
      if res["transformt1"] != "" and res["transformt2"] != ""
        trns = "\\t(#{res["transformt1"]},#{res["transformt2"]},#{res["transformaccel"]},TransformPlaceHolder)"
      else
        trns = "\\t(TransformPlaceHolder)"
    else
      btn = "Insert" if btn == "Next"

    taglist ..= "}"

    newLine.effect = res["effect"]
    newLine.actor = res["actor"]
    if newLine.text\match("TransformPlaceHolder")
      taglist = taglist\gsub("^{", "")\gsub("}$", "")
      newLine.text = newLine.text\gsub("TransformPlaceHolder", taglist)
      newLine.text = newLine.text\gsub("}$", trns.."}") if trns != ""
    elseif trns != ""
      newLine.text ..= taglist\gsub("}$", trns.."}")
    else
      newLine.text ..= taglist
  return btn

decide = (btn, subs, act) ->
  switch btn
    when "Insert"
      line = subs[act]
      subs.insert(act, newLine)
      kontinue = false
    when "Replace"
      subs[act] = newLine
      kontinue = false

main = (subs, sel, act) ->
  newLine = defaultLine
  newLine.text = ""
  kontinue = true
  local btn
  for index, item in ipairs sel
    if index > 1
      aegisub.log("You must select exactly one line")
      return
    line = subs[item]
    newLine.style = line.style
  info = reconnaissance(subs)

  while true
    btn = windowOne!
    break if proceed == true
  if btn == "Modify"
    modify(subs, sel, act)
    return
  decide(btn, subs, act)
  return unless kontinue

  btn = windowTwo(info)
  decide(btn, subs, act)
  return unless kontinue

  while true
    btn = windowThree(info)
    break if proceed == true
  decide(btn, subs, act)

if haveDepCtrl
  depctrl\registerMacro(main)
else
  aegisub.register_macro(script_name, script_description, main)
