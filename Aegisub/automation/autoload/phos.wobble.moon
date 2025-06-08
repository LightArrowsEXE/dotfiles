export script_name = "Wobble"
export script_description = "Adds wobbling to text and shape"
export script_version = "2.0.6"
export script_author = "PhosCity"
export script_namespace = "phos.wobble"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"Yutils"}
  },
}
LineCollection, ASS, Yutils = depctrl\requireModules!
logger = depctrl\getLogger!


configTemplate = {
  { class: "label",     x: 0, y: 0, label: "Wobble frequency: " },
  { class: "floatedit", x: 1, y: 0, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5,  name: "wobbleFrequencyX" },
  { class: "floatedit", x: 2, y: 0, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5,  name: "wobbleFrequencyY" },
  { class: "label",     x: 0, y: 1, label: "Wobble strength: " },
  { class: "floatedit", x: 1, y: 1, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthX" },
  { class: "floatedit", x: 2, y: 1, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthY" },
}

animateTemplate = {
  { class: "label",     x: 1, y: 0, label: "Start Value" },
  { class: "label",     x: 2, y: 0, label: "End Value"   },
  { class: "label",     x: 3, y: 0, label: "Accel"       },
  { class: "label",     x: 0, y: 1, label: "Frequency x" },
  { class: "floatedit", x: 1, y: 1, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5, name: "freqXStart" },
  { class: "floatedit", x: 2, y: 1, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5, name: "freqXEnd" },
  { class: "floatedit", x: 3, y: 1, hint: "Accel for frequency x",                    value: 1, name: "freqXAccel" },
  { class: "label",     x: 0, y: 2, label: "Frequency y" },
  { class: "floatedit", x: 1, y: 2, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5, name: "freqYStart" },
  { class: "floatedit", x: 2, y: 2, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5, name: "freqYEnd" },
  { class: "floatedit", x: 3, y: 2, hint: "Accel for frequency y",                    value: 1, name: "freqYAccel" },

  { class: "label",     x: 0, y: 3, label: "Strength x" },
  { class: "floatedit", x: 1, y: 3, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "strengthXStart" },
  { class: "floatedit", x: 2, y: 3, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "strengthXEnd" },
  { class: "floatedit", x: 3, y: 3, hint: "Accel for strength x",                     value: 1, name: "strengthXAccel" },
  { class: "label",     x: 0, y: 4, label: "Strength y" },
  { class: "floatedit", x: 1, y: 4, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "strengthYStart" },
  { class: "floatedit", x: 2, y: 4, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "strengthYEnd" },
  { class: "floatedit", x: 3, y: 4, hint: "Accel for strength y",                     value: 1, name: "strengthYAccel" },
}

waveTemplate = {
  { class: "label",     x: 0, y: 0, label: "Wobble frequency: " },
  { class: "floatedit", x: 1, y: 0, hint: "Horizontal wobbling frequency in percent", value: 0, min: 0, max: 100, step: 0.5, name: "wobbleFrequencyX" },
  { class: "floatedit", x: 2, y: 0, hint: "Vertical wobbling frequency in percent",   value: 0, min: 0, max: 100, step: 0.5, name: "wobbleFrequencyY" },
  { class: "label",     x: 0, y: 1, label: "Wobble strength: " },
  { class: "floatedit", x: 1, y: 1, hint: "Horizontal wobbling strength in pixels",   value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthX" },
  { class: "floatedit", x: 2, y: 1, hint: "Vertical wobbling strength in pixels",     value: 0, min: 0, max: 100, step: 0.01, name: "wobbleStrengthY" },
  { class: "label",     x: 0, y: 2, label: "Wave" },
  { class: "floatedit", x: 1, y: 2, hint: "Waving speed. (Values between 1-5)",       value: 0, min: 0, max: 5,   step: 0.1, name: "wavingSpeed" },
}

warpTemplate = {
  { class: "dropdown",  x: 0, y: 0, value: "Field Warp", name: "warpType", items: { "Field Warp", "Radial Warp" } },
  { class: "label",     x: 0, y: 1, label: "Magnitude: " },
  { class: "floatedit", x: 1, y: 1, hint: "", value: 30, min: 0, max: 100, name: "warpMagnitude" },
  { class: "label",     x: 0, y: 2, label: "Frequency: " },
  { class: "floatedit", x: 1, y: 2, hint: "", value: 3, min: 0, max: 100, name: "warpFrequency" },
}

createGUI = (guiType) ->
  dialog = switch guiType
    when "Static" then configTemplate
    when "Animate" then animateTemplate
    when "Wave" then waveTemplate
    when "Warp" then warpTemplate

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
  res.wavingSpeed = 0 unless guiType == "Wave"
  res


-- When percentage_value is 1, it returns ~0.0001 and for 100, it returns ~2.5
frequencyValue = (percentage_value) ->
  if percentage_value < 50
    return 0.0000825 * 1.212 ^ percentage_value
  else
    return (1.25 * percentage_value) / 50


interpolate = (startValue, endValue, accel, lineCnt, i) ->
  factor = (i - 1) ^ accel / (lineCnt - 1) ^ accel
  if factor <= 0
    return startValue
  elseif factor >= 1
    return endValue
  else
    return factor * (endValue - startValue) + startValue


wobble = (shape, res) ->
  frequencyX = frequencyValue res.wobbleFrequencyX
  frequencyY = frequencyValue res.wobbleFrequencyY
  if (frequencyX > 0 and res.wobbleStrengthX > 0) or (frequencyY > 0 and res.wobbleStrengthY > 0)
    shape = Yutils.shape.filter(Yutils.shape.split(shape, 1), (x, y) ->
      return x + math.sin(y * frequencyX * math.pi * 2 + res.wavingSpeed) * res.wobbleStrengthX, y + math.sin(x * frequencyY * math.pi * 2 + res.wavingSpeed) * res.wobbleStrengthY
    )
  shape


perlinNoise = (x, y, freq, depth, seed = 2000) ->
  perlinHash = {
    208, 34,  231, 213, 32,  248, 233, 56,  161, 78,  24,  140, 71,  48,  140, 254, 245, 255
    247, 247, 40,  185, 248, 251, 245, 28,  124, 204, 204, 76,  36,  1,   107, 28,  234, 163
    202, 224, 245, 128, 167, 204, 9,   92,  217, 54,  239, 174, 173, 102, 193, 189, 190, 121
    100, 108, 167, 44,  43,  77,  180, 204, 8,   81,  70,  223, 11,  38,  24,  254, 210, 210, 177
    32,  81,  195, 243, 125, 8,   169, 112, 32,  97,  53,  195, 13,  203, 9,   47,  104, 125, 117
    114, 124, 165, 203, 181, 235, 193, 206, 70,  180, 174, 0,   167, 181, 41,  164, 30,  116
    127, 198, 245, 146, 87,  224, 149, 206, 57,  4,   192, 210, 65,  210, 129, 240, 178, 105
    228, 108, 245, 148, 140, 40,  35,  195, 38,  58,  65,  207, 215, 253, 65,  85,  208, 76,  62
    3,   237, 55,  89,  232, 50,  217, 64,  244, 157, 199, 121, 252, 90,  17,  212, 203, 149, 152
    140, 187, 234, 177, 73,  174, 193, 100, 192, 143, 97,  53,  145, 135, 19,  103, 13,  90
    135, 151, 199, 91,  239, 247, 33,  39,  145, 101, 120, 99,  3,   186, 86,  99,  41,  237, 203
    111, 79,  220, 135, 158, 42,  30,  154, 120, 67,  87,  167, 135, 176, 183, 191, 253, 115
    184, 21,  233, 58,  129, 233, 142, 39,  128, 211, 118, 137, 139, 255, 114, 20,  218, 113
    154, 27,  127, 246, 250, 1,   8,   198, 250, 209, 92,  222, 173, 21,  88,  102, 219
  }

  -- linear interpolation in the range of 0 and 1
  lerp = (t, a, b) ->
    t = math.min math.max(t, 0), 1
    return (1 - t) * a + t * b 

  noise = (x, y) ->
    yindex = (y + seed) % 256
    yindex += yindex < 0 and 256 or 0
    xindex = (perlinHash[1 + yindex] + x) % 256
    xindex += xindex < 0 and 256 or 0
    return perlinHash[1 + xindex]
  smooth = (x, y, s) -> lerp s * s * (3 - 2 * s), x, y
  noise2D = (x, y) ->
    x_int = math.floor x
    y_int = math.floor y
    x_frac = x - x_int
    y_frac = y - y_int
    s = noise x_int, y_int
    t = noise x_int + 1, y_int
    u = noise x_int, y_int + 1
    v = noise x_int + 1, y_int + 1
    low = smooth s, t, x_frac
    high = smooth u, v, x_frac
    return smooth low, high, y_frac
  xa = x * freq
  ya = y * freq
  amp, fin, div = 1, 0, 0
  for i = 0, depth - 1
    div += 256 * amp
    fin += noise2D(xa, ya) * amp
    amp /= 2
    xa *= 2
    ya *= 2
  return fin / div


main = (wobbleType) ->
  (sub, sel) ->
    res = createGUI wobbleType

    lines = LineCollection sub, sel
    lineCnt = #lines.lines
    return if lineCnt == 0

    local speedIncrement
    alignMsgShown = false
    lines\runCallback ((lines, line, i) ->
      aegisub.cancel! if aegisub.progress.is_cancelled!
      aegisub.progress.task "Processing line %d of %d lines..."\format i, lineCnt if i%10==0
      aegisub.progress.set 100*i/lineCnt

      data = ASS\parse line
      local shape
      if data\getSectionCount(ASS.Section.Drawing) > 0
        data\callback ((section) -> shape = section\toString!), ASS.Section.Drawing
      elseif data\getSectionCount(ASS.Section.Text) > 0
        effTags = (data\getEffectiveTags -1, true, true, false).tags
        if alignMsgShown == false and not effTags.align\equal 7
          alignMsgShown = true
          logger\log "The resulting line may have different position because the alignment is not 7."
          logger\log "The script will proceed the operation but if position matters to you, please use '\\an7' in the line."

        data\callback ((section) ->
          -- TODO: Text.getShape does not work currently. Use that after Arch's PR gets added.
          _, _, shape = section\getTextMetrics true
          shape = shape\gsub " c", ""
        ), ASS.Section.Text
      else
        logger\log "No text or drawing in the line."
        aegisub.cancel!

      if wobbleType == "Wave"
        speedIncrement or= res.wavingSpeed
        res.wavingSpeed += speedIncrement
      elseif wobbleType == "Animate"
        if (res.freqXStart >= 0 and res.strengthXStart >= 0) or (res.freqYStart >= 0 and res.strengthYStart >= 0)
          res.wobbleFrequencyX = interpolate(res.freqXStart, res.freqXEnd, res.freqXAccel, lineCnt, i)
          res.wobbleFrequencyY = interpolate(res.freqYStart, res.freqYEnd, res.freqYAccel, lineCnt, i)
          res.wobbleStrengthX = interpolate(res.strengthXStart, res.strengthXEnd, res.strengthXAccel, lineCnt, i)
          res.wobbleStrengthY = interpolate(res.strengthYStart, res.strengthYEnd, res.strengthYAccel, lineCnt, i)
      elseif wobbleType == "Warp"
        if res.warpType == "Radial Warp"
          logger\log "Coming Soon"
          aegisub.cancel!
        if lineCnt == 1
          logger\log "You can only run this in line2fbf lines."
          aegisub.cancel!
        time = (i - 1) / (lineCnt - 1)
        magnitude = res.warpMagnitude
        noiseScale = 1
        noiseFreq = res.warpFrequency
        noiseDepth = 4
        noiseSeed = 1985
        scale = noiseScale * 500
        shape = Yutils.shape.filter(Yutils.shape.split(shape, 5), (x, y) ->
          dx = perlinNoise(x / scale, y / scale + time, noiseFreq, noiseDepth, noiseSeed) - 0.5
          dy = perlinNoise(x / scale + 101 + time, y / (scale + (101 + time)), noiseFreq, noiseDepth, noiseSeed) - 0.5
          return x + (dx * magnitude * 2), y + (dy * magnitude * 2)
        )

      shape = wobble(shape, res) unless wobbleType == "Warp"
      drawing = ASS.Draw.DrawingBase{str: shape}
      data\removeSections 2, #data.sections
      data\insertSections ASS.Section.Drawing {drawing}
      data\removeTags {"fontname", "fontsize", "italic", "bold", "underline", "strikeout", "spacing"}
      data\replaceTags {ASS\createTag 'scale_x', 100}
      data\replaceTags {ASS\createTag 'scale_y', 100}
      data\commit!
    ), true
    lines\replaceLines!


depctrl\registerMacros({
  {"Static", "Get distorted text or shape in a line", main "Static"},
  {"Animate", "Animate from one value of distortion to another", main "Animate"},
  {"Wave", "Create wave effect", main "Wave"},
  {"Warp", "Create wapring effect", main "Warp"},
})
