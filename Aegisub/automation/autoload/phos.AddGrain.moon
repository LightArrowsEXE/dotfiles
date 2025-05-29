export script_name = "Add Grain"
export script_description = "Add static and dynamic grain"
export script_version = "1.1.4"
export script_author = "PhosCity"
export script_namespace = "phos.AddGrain"

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
    "Yutils"
  }
}
LineCollection, ASS, Functional, Yutils = depctrl\requireModules!
logger = depctrl\getLogger!
{:list, :util} = Functional

dialog = {
  {x: 0, y: 0, class: "label", label: "Grain Intensity", hint: "Higher the number, greater the intensity"}
  {x: 1, y: 0, class: "intedit", min: 1, value: 1, name: "intensity"}
  {x: 0, y: 1, class: "label", label: "Color of grain:"}
  {x: 0, y: 2, class: "label", label: "Layer 1"}
  {x: 1, y: 2, class: "color", value: "&HFFFFFF&", name: "color1"}
  {x: 0, y: 3, class: "label", label: "Layer 2"}
  {x: 1, y: 3, class: "color", value:  "&H000000&", name: "color2"}
}

--- Checks if the grain font is installed and informs the user
isGrainInstalled = ->
  message = "It seems you have not installed grain font.
The script will proceed but will not look as intended unless you install the font.
You can install it from following link:
https://cdn.discordapp.com/attachments/425357202963038208/708726507173838958/grain.ttf"

  for font in *Yutils.decode.list_fonts!
    return if font.name == "Grain" and font.longname == "Grain Regular"
  logger\log message


--- Randomize a character by returning any character among 0-9a-zA-z!"',.:;?
---@return string or integer
randomize = ->
  ascii = list.join [x for x = 48, 57], [x for x = 65, 90], [x for x = 97, 122], {33, 34, 39, 44, 46, 58, 59, 63}
  string.char ascii[math.random(1, #ascii)]

createGui = ->
  btn, res = aegisub.dialog.display dialog, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  aegisub.cancel! unless btn

  -- Save GUI configuration
  local configEntry
  for key, value in pairs res
    for i = 1, #dialog
      configEntry = dialog[i]
      continue unless configEntry.name == key
      if configEntry.value
        configEntry.value = value
      elseif configEntry.text
        configEntry.text = value
      break
  return res

--- Main processing function
---@param mode string "dense" or "normal"
---@param sub table subtitle object
---@param sel table selected lines
main = (useGui, mode) ->
  (sub, sel) ->
    isGrainInstalled!

    --- Create an ASSFoundation color tag object
    ---@param colorString string or table ass color string or a table with {b, g, r} values
    ---@param colorType string color tagname as understood by ASSFoundation
    ---@return table ASSFoundation color tag object
    createColor = (colorString, colorType) ->
      local r, g, b
      if type(colorString) == "string"
        r, g, b = util.extract_color(colorString)
      elseif type(colorString) == "table"
        b, g, r = unpack colorString
      return ASS\createTag colorType, b, g, r

    toDelete, toAdd = {}, {}
    local intensity, firstColor, secondColor
    if useGui
      res = createGui!
      intensity = res.intensity
      firstColor = createColor res.color1, "color1"
      secondColor = createColor res.color2, "color1"
    intensity = intensity or 1
    firstColor = firstColor or createColor {255, 255, 255}, "color1"
    secondColor = secondColor or createColor {0, 0, 0}, "color1"

    lines = LineCollection sub, sel
    return if #lines.lines == 0
    cb = (lines, line, i) ->
      data = ASS\parse line
      table.insert toDelete, line

      -- Pure white layer
      data\callback ((section) -> section\replace "!!", randomize), ASS.Section.Text
      data\removeTags {"fontname", "outline", "shadow", "color1"}

      data\insertTags {
        ASS\createTag 'fontname', "Grain"
        ASS\createTag 'outline', 0
        ASS\createTag 'shadow', 0
        ASS\createTag 'bold', 0
        firstColor
      }
      if mode == "dense"
        data\removeTags {"color3", "color4", "alpha1", "alpha3", "shadow", "shadow_x", "shadow_y"}
        data\insertTags {
          createColor {255, 255, 255}, "color3"
          createColor {255, 255, 255}, "color4"
          ASS\createTag 'alpha1', 0xFE
          ASS\createTag 'alpha3', 0xFF
          ASS\createTag 'shadow', 0.01
        }
      data\cleanTags!
      table.insert toAdd, ASS\createLine { line }

      -- Pure black layer
      data\callback ((section) -> section\replace "[^\\N]", randomize), ASS.Section.Text
      data\replaceTags secondColor
      if mode == "dense"
        data\replaceTags {
          createColor {0, 0, 0}, "color3"
          createColor {0, 0, 0}, "color4"
        }
      table.insert toAdd, ASS\createLine { line }

    -- Start iteration
    for i = 1, intensity
      aegisub.cancel! if aegisub.progress.is_cancelled!
      aegisub.progress.task "Completed #{i} of #{intensity} iteration..."
      aegisub.progress.set 100*i/intensity
      lines\runCallback cb, true

    -- Add lines
    for ln in *toAdd
      lines\addLine ln

    lines\insertLines!
    lines\deleteLines toDelete


-- Register macros
depctrl\registerMacros({
  { "Add grain", "Add grain", main false, "normal" },
  { "Add dense grain", "Add dense grain", main false, "dense" },
  { "GUI", "Gui for Add Grain script", main true },
})
