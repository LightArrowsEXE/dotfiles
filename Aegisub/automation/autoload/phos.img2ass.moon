export script_name = "Phos-img2ass"
export script_description = "Img2ass that is optimized to not be img2ass"
export script_author = "PhosCity"
export script_version = "0.1.6"
export script_namespace = "phos.img2ass"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    { "ZF.main", url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts",
      feed: "https://raw.githubusercontent.com/TypesettingTools/zeref-Aegisub-Scripts/main/DependencyControl.json"},
    {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
      feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
  },
}
zf, Functional = depctrl\requireModules!
logger = depctrl\getLogger!
{:list} = Functional

createGUI = ->
  dlg = {
    {x: 0, y: 0, width: 1, height: 1, class: "label",   label: "Tolerance"},
    {x: 1, y: 0, width: 1, height: 1, class: "intedit", name: "tolerance", value: 5, min: 0, max: 254},
    {x: 0, y: 1, width: 1, height: 1, class: "label",   label: "0  : Too Many Lines, Max Quality"},
    {x: 0, y: 2, width: 1, height: 1, class: "label",   label: "5  : Lesser Lines, Decent Quality"},
    {x: 0, y: 3, width: 1, height: 1, class: "label",   label: "10 : Mid Sweet Spot"},
    {x: 0, y: 4, width: 1, height: 1, class: "label",   label: ">20: Fewer Lines, Low Quality"},
    {x: 0, y: 6, width: 1, height: 1, class: "label",   label: "Warn if number of line exceeds"},
    {x: 1, y: 6, width: 1, height: 1, class: "intedit", name: "linelimit", value: 700, min: 0},
  }

  btn, res = aegisub.dialog.display dlg, {"OK", "Cancel"}, {"ok": "OK", "cancel": "Cancel"}
  aegisub.cancel! unless btn
  res

data2hex = (data) ->
  return unless data
  {:b, :g, :r, :a} = data
  color = ("%02X%02X%02X")\format b, g, r
  alpha = ("%02X")\format 255 - a
  return color, alpha

main = (sub, selected, act) ->
  res = createGUI!

  exts = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;*.dib"
  filename = aegisub.dialog.open "Open Image File", "", "", "Image extents (#{exts})|#{exts};", false, true
  aegisub.cancel! unless filename

  dlg = zf.dialog sub, selected, active
  sel = selected[#selected]
  img = zf.img filename
  img\setInfos!
  {:width, :height, :data} = img

  logger\log "Make Image found #{width * height} pixels in your image."
  linesOfSameColor, lineCount = {}, 0
  for y = 0, height - 1
    for x = 0, width - 1
        index = y * width + x
        aegisub.cancel! if aegisub.progress.is_cancelled!
        color, alpha = data2hex data[index]
        if alpha != "FF"
          shape = "m #{x} #{y} l #{x+1} #{y} #{x+1} #{y+1} #{x} #{y+1}"
          unless linesOfSameColor[color]
            linesOfSameColor[color] = {}
            lineCount += 1
          table.insert linesOfSameColor[color], shape
  logger\log "But I reduced them to #{lineCount} chunks of same colors."

  img = nil
  filename = nil

  finalTable = {}
  if res.tolerance == 0
    finalTable = linesOfSameColor
  else
    extractRGB = (color) ->
      b, g, r = color\match "(..)(..)(..)"
      tonumber(b, 16), tonumber(g, 16), tonumber(r, 16)

    logger\log "Now, I'll try to group them into chunks of similar colors to reduce the line count even more."
    lineCount = 0
    for color, lines in pairs linesOfSameColor
      aegisub.cancel! if aegisub.progress.is_cancelled!
      b, g, r = extractRGB color
      minDiff = math.huge
      for col, _ in pairs finalTable
        b1, g1, r1 = extractRGB col
        bdiff, gdiff, rdiff = math.abs(b-b1), math.abs(g-g1), math.abs(r-r1)
        sumDiff = bdiff + gdiff + rdiff
        if bdiff < res.tolerance and gdiff < res.tolerance and rdiff < res.tolerance and minDiff > sumDiff
          minDiff = sumDiff
          color = col
      unless finalTable[color]
        finalTable[color] = {}
        lineCount += 1
      finalTable[color] = list.join finalTable[color], lines
    logger\log "I reduced it to #{lineCount} lines."

  if res.linelimit < lineCount
    btn = aegisub.dialog.display {
      {x: 0, y: 0, width: 1, height: 1, class: "label", label: "The number of lines to be inserted exceeds the limit you set."},
      {x: 0, y: 1, width: 1, height: 1, class: "label", label: "Number of Lines: #{lineCount}"},
      {x: 0, y: 2, width: 1, height: 1, class: "label", label: "Limit: #{res.linelimit}"},
      {x: 0, y: 3, width: 1, height: 1, class: "label", label: "Do you want to proceed to insert those lines?"},
    }, {"Yes", "No"}
    if btn == "No"
      logger\log "CANCELLED!"
      aegisub.cancel!
  logger\log "Now inserting those #{lineCount} lines."
  logger\log "This may take some time."

  linesOfSameColor = nil
  res = nil

  for color, shapeTable in pairs finalTable
    aegisub.cancel! if aegisub.progress.is_cancelled!
    shape = zf.clipper(table.concat shapeTable, " ")\simplify("even_odd")\build "line"
    line = sub[act]
    line.text = "{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord0\\shad0\\frz0\\c&H#{color}&\\alpha&H00&\\p1}" .. shape
    dlg\insertLine line, sel
  logger\log "FINISHED!"

depctrl\registerMacro main
