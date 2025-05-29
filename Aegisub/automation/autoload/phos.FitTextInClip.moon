export script_name = "Fit Text in Clip"
export script_description = "Fit the text inside the rectangular clip"
export script_version = "0.0.4"
export script_author = "PhosCity"
export script_namespace = "phos.FitTextInClip"

-- Readings
-- https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap
-- https://xxyxyz.org/line-breaking/
-- https://the-algorithms.com/es/algorithm/text-justification
-- https://leetcode.com/problems/text-justification/solutions/24891/concise-python-solution-10-lines/

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
  }
}
LineCollection, ASS, Functional = depctrl\requireModules!
logger = depctrl\getLogger!
{ :string } = Functional

--- Justify the text
---@param words table list of words to Justify
---@param maxWidth number width to limit the length of line
---@param fontObj table font object created by Yutils given a set of values of tags
---@return string a text seperated by line breakers
textJustification = (words, maxWidth, fontObj) ->
  --- Find the width of the text
  ---@param text string text whose width must be calculated
  ---@return number? width of the text
  textWidth = (text) ->
    extents = fontObj.text_extents text
    tonumber(extents.width)

  result, currentLine, width = {}, {}, 0
  spaceWidth = textWidth(" ")
  for word in *words
    if width + textWidth(word) > maxWidth
      for i = 0, math.floor((maxWidth - width)/spaceWidth) - 1
        position = i % ( math.max(1, #currentLine - 1) )
        currentLine[position + 1] ..= " "
      table.insert result, table.concat(currentLine, " ")
      currentLine, width = {}, 0
    table.insert currentLine, word
    currText = table.concat(currentLine, " ")
    width = textWidth(currText)
  table.insert result, table.concat(currentLine, " ")

  return table.concat(result, "\\N")


--- Main processing function
---@param sub table subtitle object
---@param sel table selected lines
main = (sub, sel) ->
  lines = LineCollection sub, sel
  return if #lines.lines == 0
  
  lines\runCallback (_, line) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    data = ASS\parse line

    if data\getSectionCount(ASS.Section.Tag) > 1 or data\getSectionCount(ASS.Section.Drawing) > 0 or data\getSectionCount(ASS.Section.Text) == 0
      logger\warn "There must be a single text block in the line. Exiting."
      return

    clip = data\getTags "clip_rect"
    if #clip == 0
      logger\warn "Add a rectangular clip in the line fist!"
      return
    x1, _, x2, _ = clip[1]\getTagParams!
    clipWidth = x2 - x1

    effTags = (data\getEffectiveTags -1, true, true, false).tags
    if effTags.align\getTagParams! != 7
      logger\warn "Please use \\an7 in the line."
      return

    data\callback ((section) ->
      fontObj = section\getYutilsFont!
      text = section\replace("\\N", " ")\replace("%s+", " ")\getString!
      words = string.split text, " "
      result = textJustification(words, clipWidth, fontObj)
      section\set result
    ), ASS.Section.Text
    data\removeTags "clip_rect"
    data\commit!
  lines\replaceLines!

depctrl\registerMacro main
