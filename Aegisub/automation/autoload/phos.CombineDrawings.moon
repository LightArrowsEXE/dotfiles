export script_name = "Combine Drawings"
export script_description = [[Combine drawings that have same primary color in a selection.
 Maintains positioning and converts scale as well as alignment.]]
export script_version = "0.1.1"
export script_author = "PhosCity"
export script_namespace = "l0.CombineDrawings"

DependencyControl = require "l0.DependencyControl"

rec = DependencyControl{
  feed: "",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https://github.com/TypesettingTools/Aegisub-Motion",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.4.0", url: "https://github.com/TypesettingTools/ASSFoundation",
      feed: "https://raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"l0.Functional", version: "0.3.0", url: "https://github.com/TypesettingTools/Functional",
     feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
  }
}

LineCollection, ASS, Functional = rec\requireModules!
import util from Functional
logger = rec\getLogger!

table_contains = (tbl, x) ->
  for item in *tbl
    return true if item == x
  return false

tableLength = (tbl) ->
  count = 0
  for _ in pairs(tbl) do count = count + 1
  count

combineDrawings = (sub, sel) ->
  lines = LineCollection sub, sel
  lineCnt = #lines.lines
  return if lineCnt == 0

  colorTable, mergedLines, targetSection = {}, {}, {}
  targetScaleX, targetScaleY = 1, 1
  target = {name, ASS\createTag(name, value) for name, value in pairs {"align": 7, "scale_x": 100, "scale_y": 100}}
  local targetLine

  col = (lines, line, i) ->
    data = ASS\parse line
    tags = (data\getEffectiveTags -1, true, true, false).tags
    b, g, r =  tags.color1\getTagParams!
    color = util.ass_color(r, g, b)
    colorTable[color] or= {}
    table.insert colorTable[color], i
  lines\runCallback col, true
  colLength = tableLength(colorTable)

  count = 1
  for key, value in pairs colorTable
    aegisub.progress.task "Merging lines with color %d out of %d..."\format count, colLength
    aegisub.progress.set 100*count/colLength
    count += 1
    lineCb = (lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!
      if table_contains value, i
        data = ASS\parse line
        pos, align = data\getPosition!
        tags = (data\getEffectiveTags -1, true, true, false).tags
        targetLine = data if i == value[1]
        local haveTextSection

        data\callback (section) ->
          if section.class == ASS.Section.Drawing
            -- determine target drawing section to merge drawings into
            targetSection = section if i == value[1]
            -- get a copy of the position tag which needs to be
            -- applied as an offset to the drawing
            off = pos.class == ASS.Tag.Move and pos.startPos\copy! or pos\copy!

            -- determine the top/left bounds of the drawing in order to make
            -- the drawing start at the coordinate origin
            bounds = section\getBounds!
            -- trim drawing in order to scale shapes without causing them to move
            section\sub bounds[1]
            -- add the scaled bounds to our offset
            scaleX, scaleY = tags.scale_x.value/100, tags.scale_y.value/100
            off\add bounds[1]\mul scaleX, scaleY
            facX, facY = scaleX / targetScaleX, scaleY / targetScaleY
            unless facX == 1 and facY == 1
              section\mul facX, facY
            -- now apply the position offset scaled by the target fscx/fscy values
            section\add off\div targetScaleX, targetScaleY

            -- set intermediate point of origin alignment
            unless align\equal 7
              ex = section\getExtremePoints true
              srcOff = align\getPositionOffset ex.w, ex.h
              section\sub srcOff

            if i != value[1]
              -- insert contours into first line, create a drawing section if none exists
              targetSection or= (targetLine\insertSections ASS.Section.Drawing!)[1]
              targetSection\insertContours section
              return false

          elseif section.class == ASS.Section.Text
            haveTextSection or= true

        if i != value[1]
          -- remove drawings from original lines and mark empty lines for deletion
          if haveTextSection then data\commit!
          else mergedLines[#mergedLines+1] = line


    -- process all selected lines
    lines\runCallback lineCb, true

    -- update tags and aligment
    targetLine\replaceTags [tag for _,tag in pairs target]
    unless target.align\equal 7
      ex = targetSection\getExtremePoints true
      off = target.align\getPositionOffset ex.w, ex.h
      targetSection\add off

    pos, align = targetLine\getPosition!
    bounds = targetSection\getBounds!
    targetSection\sub bounds[1]
    if pos.class == ASS.Tag.Move
      pos.endPos\sub pos.startPos
      pos.endPos\add bounds[1]
      pos.startPos\set bounds[1].x, bounds[1].y
    else
      targetLine\replaceTags{ASS\createTag "position", bounds[1]}

    targetLine\commit!
    lines\replaceLines!
    lines\deleteLines mergedLines


rec\registerMacro combineDrawings
