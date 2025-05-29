export script_name = "Nudge"
export script_description = "Provides configurable and hotkeyable tag/line modification macros."
export script_version = "0.5.0"
export script_author = "line0"
export script_namespace = "l0.Nudge"

DependencyControl = require "l0.DependencyControl"
depCtrl = DependencyControl {
  feed: "https://raw.githubusercontent.com/TypesettingTools/line0-Aegisub-Scripts/master/DependencyControl.json",
  {
    "aegisub.clipboard", "json",
    {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion"},
    {"l0.ASSFoundation", version: "0.4.0", url: "https://github.com/TypesettingTools/ASSFoundation",
      feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"l0.Functional", version: "0.5.0", url: "https://github.com/TypesettingTools/Functional",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
  }
}

clipboard, json, LineCollection, ASS, Functional = depCtrl\requireModules!
{:list, :math, :string, :table, :unicode, :util, :re } = Functional
logger = depCtrl\getLogger!

--------  Nudger Class -------------------

cmnOps = {"Add", "Multiply", "Power", "Cycle", "Set", "Set Default", "Remove", "Copy", "Paste Over", "Paste Into"}
colorOps = list.join cmnOps, {"Add HSV"}
stringOps = {"Append", "Prepend", "Replace", "Cycle", "Set", "Set Default", "Remove"}
drawingOps = {"Add", "Multiply", "Power", "Remove", "Copy", "Paste Over", "Paste Into", "Expand", "Convert To Clip"}
clipOpsVect = list.join drawingOps, {"Invert Clip", "Convert To Drawing", "Set Default"}
clipOptsRect = list.join cmnOps, {"Invert Clip", "Convert To Drawing"}

msgs = {
  configuation: {
    load: {
      unsupportedConfigFileVersion: "Your configuration file version (%s) is incompatible with %s %s.
Please delete %s and reload your scripts."
    }
  }
}

class Nudger
  @operations = list.makeSet {
    "Align Up", "Align Down", "Align Left", "Align Right", "Set Default", "Cycle", "Remove", "Convert To Drawing",
    "Set Comment", "Unset Comment", "Toggle Comment", "Copy", "Paste Over", "Paste Into", "Expand", "Convert To Clip"
  }, {
    Add: "add", Multiply: "mul", Power: "pow", Set: "set", Toggle: "toggle", Replace: "replace"
    Append: "append", Prepend: "prepend", ["Auto Cycle"]: "cycle", ["Add HSV"]: "addHSV",
    ["Invert Clip"]: "toggleInverse"
  }, nil, false

  @targets = {
    tags: {
      position: cmnOps,
      blur_edges: cmnOps,
      scale_x: cmnOps, scale_y: cmnOps,
      align: {"Align Up", "Align Down", "Align Left", "Align Right", "Auto Cycle", "Set", "Set Default", "Cycle"},
      angle: cmnOps, angle_y: cmnOps, angle_x: cmnOps,
      outline: cmnOps, outline_x: cmnOps, outline_y: cmnOps,
      shadow: cmnOps, shadow_x: cmnOps, shadow_y: cmnOps,
      alpha: cmnOps, alpha1: cmnOps, alpha2: cmnOps, alpha3: cmnOps, alpha4: cmnOps, ["Alphas"]: cmnOps,
      color1: colorOps, color2: colorOps, color3: colorOps, color4: colorOps,
      ["Colors"]: colorOps, ["Primary Color"]: colorOps
      blur: cmnOps,
      shear_x: cmnOps, shear_y: cmnOps,
      bold: list.join(cmnOps,{"Toggle"}),
      underline: {"Toggle","Set", "Set Default"},
      spacing: cmnOps,
      fontsize: cmnOps,
      k_fill: cmnOps, k_sweep_alt: cmnOps, k_sweep: cmnOps, k_bord: cmnOps,
      move: cmnOps, move_simple: cmnOps,
      origin: cmnOps,
      wrapstyle: {"Auto Cycle","Cycle", "Set", "Set Default"},
      fade_simple: cmnOps, fade: cmnOps, ["Fades"]: cmnOps,
      italic: {"Toggle","Set", "Set Default"},
      reset: stringOps,
      fontname: stringOps,
      clip_vect: clipOpsVect, iclip_vect: clipOpsVect, clip_rect: clipOptsRect, iclip_rect: clipOptsRect,
      ["Clips (Vect)"]: clipOpsVect, ["Clips (Rect)"]: clipOptsRect, Clips: clipOpsVect,
      unknown: {"Remove"}, junk: {"Remove"}, Comment: {"Remove"}, ["Comments/Junk"]: {"Remove"}
      ["Any Tag"]: {"Remove", "Copy", "Paste Over", "Paste Into"},
    },
    line: {
      Line: {"Set Comment", "Unset Comment", "Toggle Comment"},
      Text: {"Convert To Drawing", "Expand", "Convert To Clip"},
      Drawing: drawingOps,
      Contents: {"Convert To Drawing", "Expand"}
    }
  }

  @compoundTargets = {
      Colors: {"color1","color2","color3","color4"},
      Alphas: {"alpha", "alpha1", "alpha2", "alpha3", "alpha4"},
      Fades: {"fade_simple", "fade"},
      Clips: {"clip_vect", "clip_rect", "iclip_vect", "iclip_rect"},
      ["Clips (Vect)"]: {"clip_vect", "iclip_vect"},
      ["Clips (Rect)"]: {"clip_rect", "iclip_rect"},
      ["\\move"]: {"move", "move_simple"},
      ["Any Tag"]: ASS.tagNames.all,
      Contents: {"Text", "Drawing"}
  }

  @targetList = list.join table.keys(@@targets.line),
    [ASS.toFriendlyName[name] or name for name, _ in pairs @@targets.tags]

  new: (params = {}) =>
    @name = params.name or "Unnamed Nudger"
    @tag = params.tag or "position"
    @operation = params.operation or "Add"
    @value = params.value or {}
    @id = params.id or util.uuid!
    @noDefault = params.noDefault or false
    @keepEmptySections = params.keepEmptySections == nil and true or params.keepEmptySections
    @targetValue = params.targetValue or 0
    @targetName = params.targetName or "Tag Section"
    @validate!

  validate: =>
    -- do we need to check the other values?
    ops = @@targets.tags[@tag] or @@targets.line[@tag]
    logger\assert list.indexOf(ops, @operation),
      "Operation %s not supported for tag or section %s.", @operation, @tag

  nudgeTags: (lineData, lines, line, targets) =>
    tagSect = @targetValue != 0 and tonumber(@targetValue) or nil
    relative = @targetName == "Matched Tag"
    builtinOp = @@operations[@operation]

    foundTags = lineData\getTags targets, tagSect, tagSect, relative
    foundCnt = #foundTags

    -- insert default tags if no matching tags are present
    if foundCnt == 0 and not @noDefault and not relative and @operation != "Remove"
      lineData\insertDefaultTags targets, tagSect

    if builtinOp
      lineData\modTags targets,
        (tag) -> tag[builtinOp] tag, unpack @value,
        tagSect, tagSect, relative
      return

    switch @operation
      when "Copy"
        tagStr = {}
        lineData\modTags targets,
          (tag) -> tagStr[#tagStr+1] = tag\getTagString!,
          tagSect, tagSect, relative
        clipboard.set table.concat tagStr

      when "Paste Over"
        pasteTags = ASS.TagList(ASS.Section.Tag(clipboard.get!))\filterTags targets
        lineData\replaceTags pasteTags, tagSect, tagSect, relative

      when "Paste Into"
        pasteTags = ASS.TagList ASS.Section.Tag clipboard.get!
        global, normal = pasteTags\filterTags targets, global: true
        lineData\insertTags normal, tagSect, -1, not relative
        lineData\replaceTags global

      when "Cycle"
        edField = "l0.Nudge.cycleState"
        ed = line\getExtraData edField
        if type(ed) == "table"
          ed[@id] = ed[@id] and ed[@id] < #@value and ed[@id] + 1 or 1
        else ed = {[@id]: 1}
        line\setExtraData edField, ed

        lineData\modTags targets,
          (tag) -> tag\set unpack @value[ed[@id]],
          tagSect, tagSect, relative

      when foundCnt > 0 and "Set Default"
        defaults = lineData\getStyleDefaultTags!
        lineData\modTags targets, (tag) ->
          tag\set defaults.tags[tag.__tag.name]\get!,
          tagSect, tagSect, relative

        lineData\cleanTags 1, false

      when "Expand"
        lineData\modTags targets,
          (tag) -> tag\expand @value[1], @value[2],
          tagSect, tagSect, relative

      when "Convert To Drawing"
        keepPos, drawing, pos = not @value[2]
        lineData\modTags targets, (tag) ->
            drawing, pos = tag\getDrawing(keepPos)
            return @value[1] == true,
          tagSect, tagSect, relative

        lineData\insertSections drawing
        lineData\replaceTags pos if pos

      when "Remove"
        lineData\removeTags targets, tagSect, tagSect, relative

      else
        opAlign = re.match @operation, "Align (Up|Down|Left|Right)"
        if opAlign
          pos, align, org = lineData\getPosition!
          newAlign = align\copy!
          newAlign[string.lower(opAlign[2].str)] newAlign

          if @value[1] == true
            haveDrawings, haveRotation, w, h = false, false
            lineData\callback (section,sections,i) -> haveDrawings = true,
              ASS.Section.Drawing

            -- While text uses type metrics for positioning and alignment
            -- vector drawings use a straight bounding box
            -- TODO: make this work for lines that have both drawings AND text
            if haveDrawings
              bounds = lineData\getLineBounds!
              w, h = bounds.w, bounds.h
            else
              metrics = lineData\getTextMetrics true
              w, h = metrics.width, metrics.height

            pos\add newAlign\getPositionOffset w, h, align

            -- add origin if any rotation is applied to the line
            effTags = lineData\getEffectiveTags -1, true, true, false
            trans, tags = effTags\checkTransformed!, effTags.tags
            if tags.angle\modEq(0, 360) and tags.angle_x\modEq(0, 360) and tags.angle_y\modEq(0, 360) and not (trans.angle or trans.angle_x or trans.angle_y)
              lineData\replaceTags {newAlign, pos}
            else lineData\replaceTags {newAlign, org, pos}

          else lineData\replaceTags {newAlign}

  nudgeLines: (lineData, lines, line, targets) =>
    op = @operation
    relative = @targetName == "Matched Tag"
    tagSect = @targetValue != 0 and @targetValue or nil

    if targets["Line"]
      line.comment = switch op
        when "Unset Comment" then false
        when "Set Comment" then true
        when "Toggle Comment" then not line.comment

    if targets["Text"]
      if op == "Convert To Clip"
        local toConvert
        lineData\callback (sect) ->
            toConvert = sect\convertToDrawing!
            return false,
          ASS.Section.Text, 1, 1, true
        if toConvert
          lineData\replaceTags toConvert\getClip!
      else
        lineData\callback (sect) ->
            switch op
              when "Convert To Drawing" then sect\convertToDrawing!
              when "Expand" then sect\expand(@value[1], @value[2]),
          ASS.Section.Text, tagSect, tagSect, relative

    if targets["Drawing"] or targets["Text"]
      targetSections = {targets["Drawing"] and ASS.Section.Drawing, targets["Text"] and ASS.Section.Text}
      switch op
        when "Copy"
          sectStr = {}
          lineData\callback (sect) -> sectStr[#sectStr+1] = sect\getString!,
            targetSections, tagSect, tagSect, relative
          clipboard.set table.concat sect
        when "Paste Over"
          sectStr = clipboard.get!
          lineData\callback (sect) ->
              if sect.class == ASS.Section.Text
                sect.value = sectStr
              else return ASS.Section.Drawing str: sectStr,
            targetSections, tagSect, tagSect, relative
        when "Paste Into"
          sectStr = clipboard\get!
          if targets["Drawing"] and sectStr:match("m%s+[%-%d%.]+%s+[%-%d%.]+")
            lineData\insertSections ASS.Section.Drawing str: sectStr
          elseif targets["Text"]
            lineData\insertSections ASS.Section.Text sectStr
        when "Convert To Clip"
          local clip
          lineData\callback (sect) ->
              if clip
                clip\insertContours sect\getClip!
              else
                clip = sect\getClip!
              return false,
            ASS.Section.Drawing, tagSect, tagSect, relative
          if clip then
            lineData\replaceTags clip

      if targets["Drawing"]
        builtinOp = @@operations[@operation]
        lineData\callback (sect) ->
            if builtinOp
              sect[builtinOp] sect, unpack @value
            elseif op == "Expand"
              sect\expand @value[1], @value[2],
          ASS.Section.Drawing, tagSect, tagSect, relative

    if targets["Comments/Junk"] and op == "Remove"
      lineData\stripComments!
      lineData\removeTags "junk", tagSect, tagSect, relative

    elseif targets["Comment"] and op == "Remove"
      lineData\stripComments!

  nudge: (sub, sel) =>
    targets, tagTargets, lineTargets = @@compoundTargets[@tag], {}, {}
    if targets
      for i = 1, #targets
        if ASS.tagMap[targets[i]]
          tagTargets[#tagTargets+1] = targets[i]
        else
          lineTargets[#lineTargets+1] = targets[i]
          lineTargets[targets[i]] = true
    elseif ASS.tagMap[@tag]
        tagTargets[1] = @tag
    else
      lineTargets[1], lineTargets[@tag] = @tag, true

    lines = LineCollection sub, sel, () -> true
    lines\runCallback (lines, line) ->
      lineData = ASS\parse line
      if #tagTargets > 0
        @nudgeTags lineData, lines, line, tagTargets
      if #lineTargets > 0
        @nudgeLines lineData, lines, line, lineTargets

      lineData\commit nil, @keepEmptySections
    lines\replaceLines!
table.sort Nudger.targetList


encodeDlgResName = (id, name) -> "#{id}.#{name}"
decodeDlgResName = (un) -> un\match "([^%.]+)%.(.+)"

class Configuration
  @default = {
    __version: script_version,
    nudgers: {
      {operation: "Add", value: {1,0}, id: "d0dad24e-515e-40ab-a120-7b8d24ecbad0", name: "Position Right (+1)", tag: "position"},
      {operation: "Add", value: {-1,0}, id: "0c6ff644-ef9c-405a-bb12-032694d432c0", name: "Position Left (-1)", tag: "position"},
      {operation: "Add", value: {0,-1}, id: "cb2ec6c1-a8c1-48b8-8a13-cafadf55ffdd", name: "Position Up (-1)", tag: "position"},
      {operation: "Add", value: {0,1}, id: "cb9c1a5b-6910-4fb2-b457-a9c72a392d90", name: "Position Down (+1)", tag: "position"},
      {operation: "Cycle", value: {{0.6},{0.8},{1},{1.2},{1.5},{2},{3},{4},{5},{8}}, id: "c900ef51-88dd-413d-8380-cebb7a59c793", name: "Cycle Blur", tag: "blur"},
      {operation: "Cycle", value: {{255},{0},{16},{48},{96},{128},{160},{192},{224}}, id: "d338cbca-1575-4795-9b80-3680130cce62", name: "Cycle Alpha", tag: "alpha"},
      {operation: "Toggle", value: {}, id: "974c3af9-ef51-45f5-a992-4850cb006743", name: "Toggle Bold", tag: "bold"},
      {operation: "Auto Cycle", value: {}, id: "aa74461a-477b-47de-bbf4-16ef1ee568f5", name: "Cycle Wrap Styles", tag: "wrapstyle"},
      {operation: "Align Up", value: {true}, id: "254bf380-22bc-457b-abb7-3d1f85b90eef", name: "Align Up", tag: "align"},
      {operation: "Align Down", value: {true}, id: "260318dc-5bdd-4975-9feb-8c95b41e7b5b", name: "Align Down", tag: "align"},
      {operation: "Align Left", value: {true}, id: "e6aeca35-d4e0-4ff4-81ac-8d3a853d5a9c", name: "Align Left", tag: "align"},
      {operation: "Align Right", value: {true}, id: "dd80e1c5-7c07-478c-bc90-7c473c3abe49", name: "Align Right", tag: "align"},
      {operation: "Set", value: {1}, id: "18a27245-5306-4990-865c-ae7f0062083a", name: "Add Edgeblur", tag: "blur_edges"},
      {operation: "Set Default", value: {1}, id: "bb4967a7-fb8a-4907-b5e8-395ea67c0a52", name: "Default Origin", tag: "origin"},
      {operation: "Add HSV", value: {0,0,0.1}, id: "015cd09b-3c2b-458e-a65a-80b80bb951b1", name: "Brightness Up", tag: "Colors"},
      {operation: "Add HSV", value: {0,0,-0.1}, id: "93f07885-c3f7-41bb-b319-0542e6fd52d7", name: "Brightness Down", tag: "Colors"},
      {operation: "Invert Clip", value: {}, id: "e719120a-e45a-44d4-b76a-62943f47d2c5", name: "Invert First Clip", tag: "Clips",
        noDefault: true, targetName: "Matched Tag", targetValue: "1"},
      {operation: "Remove", value: {}, id: "4dfc33fd-3090-498b-8922-7e1eb4515257", name: "Remove Comments & Junk", tag: "Comments/Junk", noDefault: true},
      {operation: "Remove", value: {}, id: "bc642b90-8ebf-45e8-a160-98b4658721bd", name: "Strip Tags", tag: "Any Tag", noDefault: true, keepEmptySections: false},
      {operation: "Convert To Drawing", value: {false, false}, id: "9cf44e64-9ce9-402e-8097-9e189014c9c1", name: "Clips -> Drawing", tag: "Clips", noDefault: true},
    }
  }

  new: (fileName) =>
    @fileName = aegisub.decode_path(fileName)
    @nudgers = {}
    @load!

  load: =>
    fileHandle = io.open @fileName
    local data
    if fileHandle
      data = json.decode fileHandle\read '*a'
      fileHandle\close!
    else
      data = @@default

    -- version checking
    logger\assert tonumber(data.__version\sub(3,3)) >= 3,
      msgs.configuation.load.unsupportedConfigFileVersion, data.__version, script_name, script_version, @fileName

    @nudgers = [Nudger nudgerConfig for nudgerConfig in *data.nudgers]
    @save! unless fileHandle

  save: =>
    data = json.encode {nudgers: @nudgers, __version: script_version}
    fileHandle = io.open @fileName, 'w'
    fileHandle\write data
    fileHandle\close!

  addNudger: (params) =>
    @nudgers[#@nudgers+1] = Nudger params

  removeNudger: (id) =>
    @nudgers = list.filter @nudgers, (nudger) -> nudger.id != id

  getNudger: (id) => list.find @nudgers, (nudger) -> nudger.id == id

  getDialog: =>
    dialog = {
      {class: "label", label: "Macro Name", x: 0, y: 0, width: 1, height: 1},
      {class: "label", label: "Override Tag", x: 1, y: 0, width: 1, height: 1},
      {class: "label", label: "Action", x: 2, y: 0, width: 1, height: 1},
      {class: "label", label: "Value", x: 3, y: 0, width: 1, height: 1},
      {class: "label", label: "Target", x: 4, y: 0, width: 1, height: 1},
      {class: "label", label: "Target #", x: 5, y: 0, width: 1, height: 1},
      {class: "label", label: "No Default", x: 6, y: 0, width: 1, height: 1},
      {class: "label", label: "Keep Empty", x: 7, y: 0, width: 1, height: 1},
      {class: "label", label: "Remove", x: 8, y: 0, width: 1, height: 1},
    }

    getUnwrappedJson = (arr) ->
      jsonString = json.encode arr
      return jsonString\sub 2, jsonString\len!-1

    tags, operations = Nudger.targetList, table.keys Nudger.operations
    table.sort operations

    for i, nu in ipairs @nudgers
      dialog = list.join dialog, {
        {class: "edit", name: encodeDlgResName(nu.id, "name"), value: nu.name, x: 0, y: i, width: 1, height: 1},
        {class: "dropdown", name: encodeDlgResName(nu.id, "tag"), items: tags, value: ASS.toFriendlyName[nu.tag] or nu.tag,
          x: 1, y: i, width: 1, height: 1},
        {class: "dropdown", name: encodeDlgResName(nu.id, "operation"), items: operations, value: nu.operation, x: 2, y: i, width: 1, height: 1},
        {class: "edit", name: encodeDlgResName(nu.id, "value"), value: getUnwrappedJson(nu.value), step: 0.5, x: 3, y: i, width: 1, height: 1},
        {class: "dropdown", name: encodeDlgResName(nu.id, "targetName"), items: {"Tag Section", "Matched Tag"}, value: nu.targetName, x: 4, y: i, width: 1, height: 1},
        {class: "intedit", name: encodeDlgResName(nu.id, "targetValue"), value: nu.targetValue, x: 5, y: i, width: 1, height: 1},
        {class: "checkbox", name: encodeDlgResName(nu.id, "noDefault"), value: nu.noDefault, x: 6, y: i, width: 1, height: 1},
        {class: "checkbox", name: encodeDlgResName(nu.id, "keepEmptySections"), value: nu.keepEmptySections, x: 7, y: i, width: 1, height: 1},
        {class: "checkbox", name: encodeDlgResName(nu.id, "remove"), value: false, x: 8, y: i, width: 1, height: 1}
      }

    return dialog

  update: (res) =>
    for k, v in pairs res
      id, name = decodeDlgResName k
      v = switch name
        when "value" then json.decode "[#{v}]"
        when "tag" then ASS.toTagName[v] or v
        else v

      if name == "remove" and v == true
        @removeNudger id
      elseif nudger = @getNudger(id)
        nudger[name] = v

    nudger\validate! for nudger in *@nudgers
    @registerMacros!

  registerMacros: =>
    for nudger in *@nudgers
      aegisub.register_macro "#{script_name}/#{nudger.name}", script_description,
        (sub, sel) -> nudger\nudge sub, sel

  run: (noReload) =>
    @load! unless noReload
    btn, res = aegisub.dialog.display @getDialog!,
      {"Save", "Cancel", "Add Nudger"},
      {save: "Save", cancel: "Cancel", close: "Save"}

    switch btn
      when "Add Nudger"
        @addNudger!
        @run true
      when "Save"
        @update res
        @save!
      else @load!

config = Configuration depCtrl\getConfigFileName!
aegisub.register_macro "#{script_name}/Configure Nudge", script_description, () -> config\run!
config\registerMacros!
