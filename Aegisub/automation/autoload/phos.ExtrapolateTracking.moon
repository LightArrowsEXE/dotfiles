export script_name = "Extrapolate Tracking"
export script_description = "Extrapolate the tag values where mocha can't reach"
export script_version = "1.0.2"
export script_author = "PhosCity"
export script_namespace = "phos.ExtrapolateTracking"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
  feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
  {
    {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"a-mo.DataWrapper", version: "1.0.2", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"a-mo.MotionHandler", version: "1.1.8", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
      feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
    {"arch.Math", version: "0.1.8", url: "https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts",
      feed: "https://raw.githubusercontent.com/TypesettingTools/arch1t3cht-Aegisub-Scripts/main/DependencyControl.json"},
  },
}
LineCollection, DataWrapper, MotionHandler, ASS, Math = depctrl\requireModules!
logger = depctrl\getLogger!
{:Matrix} = Math


crossValidation = (originalData) ->
  leastSquare = (degree, data) ->
    X, Y = {}, {}
    for row in *data
      table.insert(X, { 1 })
      for i = 1, degree
        table.insert(X[#X], row[1] ^ i)
      table.insert(Y, { row[2] })

    -- Solve for the coefficients using the least squares method
    X, Y = Matrix(X), Matrix(Y)
    XT = X\transpose!
    A = XT * X
    B = XT * Y
    coeffs = A\preim B
    coeffs

  fit_polynomial = (degree, data) ->
    coeffs = leastSquare degree, data
    return (x) ->
      y = coeffs[1][1]
      for i = 1, degree
        y += coeffs[i + 1][1] * x ^ i
      y

  meanSquaredError = (actual, predicted) ->
    sumSquaredError = 0
    for i = 1, #actual
      error = actual[i] - predicted[i]
      sumSquaredError = sumSquaredError + error ^ 2
    sumSquaredError / #actual

  kFold = (data, k, degree) ->
    n = #data
    foldSize = math.floor(n / k)
    rmses = {}
    for i = 1, k
      testStart = (i - 1) * foldSize + 1
      testEnd = i * foldSize
      trainData, testData = {}, {}
      for j = 1, n
        if j >= testStart and j <= testEnd
          table.insert(testData, data[j])
        else
          table.insert(trainData, data[j])

      predict = fit_polynomial(degree, trainData)

      actual, predicted = {}, {}
      for row in *testData
        table.insert(actual, row[2])
        table.insert(predicted, predict(row[1]))

      rmse = math.sqrt(meanSquaredError(actual, predicted))
      table.insert(rmses, rmse)
    avg_rmse = 0
    for rmse in *rmses
      avg_rmse = avg_rmse + rmse
    avg_rmse / k

  if type(originalData[1]) == "number"
    originalData = [{index, item} for index, item in ipairs originalData]

  kValue = math.floor(#originalData * 0.8)

  -- Test different degrees of polynomial fit using cross-validation
  minRmse, finalDegree = math.huge
  for deg = 1, 3 do
    rmse = kFold(originalData, kValue, deg)
    if rmse < minRmse
      logger\log "Degree #{deg}: RMSE = #{rmse}"
      finalDegree = deg
      minRmse = rmse
    if rmse < 0.01
      break

  coeffs = leastSquare finalDegree, originalData
  coeffs, finalDegree, minRmse


-- assert condition and show message before exiting
windowAssertError = ( condition, errorMessage ) ->
  if not condition
    logger\log errorMessage
    aegisub.cancel!


-- For a table with data, cross validate and find extrapolated value
findNewValues = (data, res, name) ->
  aegisub.cancel! if aegisub.progress.is_cancelled!
  logger\log "Fitting for #{name}"
  local coeffs, degree, rmse
  count = 0
  -- It tries to find a proper degree and coefficients of fitted curve for all data but everytime it cannot fit curve properly, it reduces the data size by half and tries again.
  while true
    count += 1
    logger\log "Trial ##{count}"
    coeffs, degree, rmse = crossValidation(data)
    if rmse < 0.003 or #data * 2 < 15
      break
    if res.extrapolateLocation == "Start"
      data = [item for index, item in ipairs data when index < #data / 2]
    else
      data = [item for index, item in ipairs data when index > #data / 2]

  -- If even at the end it cannot fit curve properly, show these warning message.
  if rmse > 5
    logger\log "VERY LOW CONFIDENCE"
  elseif rmse > 0.2
    logger\log "LOW CONFIDENCE"
  logger\log " "

  -- This returns a dependent variable y for an independent varable x using coefficients of curve
  constructValue = (x) ->
    result = 0
    for j = 1, degree + 1
      result += coeffs[j][1] * x ^ (j - 1)
    result

  newData = {}
  if res.extrapolateLocation == "Start"
    for i = 1 - res.frameNumber, 0
      table.insert newData, constructValue(i)
    table.insert newData, data[1]
  else
    table.insert newData, data[#data]
    for i = #data + 1,  #data + res.frameNumber
      table.insert newData, constructValue(i)
  newData


dialog = {
  {x: 0, y: 0, width: 1, height: 1, class: "label", label: "Extrapolate at"},
  {x: 1, y: 0, width: 1, height: 1, class: "dropdown", name: "extrapolateLocation", value: "Start", items: {"Start", "End"} },
  {x: 0, y: 1, width: 1, height: 1, class: "label", label: "Number of frames"},
  {x: 1, y: 1, width: 1, height: 1, class: "intedit", min: 1, value: 1, name: "frameNumber"},
  {x: 0, y: 2, width: 1, height: 1, class: "checkbox", value: true, label: "Origin", name: "origin"},
}
createGUI = ->
  btn, res = aegisub.dialog.display dialog, {"Apply", "Cancel"}, {"ok": "Apply", "cancel": "Cancel"}
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
  res


main = (sub, sel) ->
  -- Collect, position, scale and rotation of all selected lines
  positions, scales, rotations = {x: {}, y: {}}, {x: {}, y: {}}, {}
  lines = LineCollection sub, sel
  return if #lines.lines < 2
  local prevEndTime, prevLayer, prevText
  lines\runCallback ((_, line, i) ->
    aegisub.cancel! if aegisub.progress.is_cancelled!
    data = ASS\parse line

    -- Selection validation
    currText = ""
    data\callback (section) -> currText ..= section\getString! if section.class == ASS.Section.Text or section.class == ASS.Section.Drawing
    if i > 1
      windowAssertError line.start_time == prevEndTime and line.layer == prevLayer and currText == prevText, "Your selected lines are not fbf lines."
    windowAssertError not data\isAnimated!, "Your selected lines are not fbf lines."
    prevEndTime = line.end_time
    prevLayer = line.layer
    prevText = currText

    effTags = (data\getEffectiveTags 1, true, true, false).tags
    table.insert positions.x, effTags.position.x
    table.insert positions.y, effTags.position.y
    table.insert scales.x, effTags.scale_x.value
    table.insert scales.y, effTags.scale_y.value
    table.insert rotations, effTags.angle.value
  ), true

  -- GUI
  res = createGUI!

  -- Add time to first or last line so that they include time for additional lines to be added
  if res.extrapolateLocation == "Start"
    ln = sub[sel[1]]
    lnFrame = aegisub.frame_from_ms ln.start_time
    newFrame = lnFrame - res.frameNumber
    windowAssertError newFrame > 0, "Going back #{res.frameNumber} from first line causes negative time. Exiting."
    ln.start_time = aegisub.ms_from_frame newFrame
    sub[sel[1]] = ln
  else
    ln = sub[sel[#sel]]
    lnFrame = aegisub.frame_from_ms ln.end_time
    newFrame = lnFrame + res.frameNumber
    ln.end_time = aegisub.ms_from_frame newFrame
    sub[sel[#sel]] = ln

  -- Find extrapolated position, scale and rotation
  newPositions = {x: {}, y: {}}
  newScales = {x: {}, y: {}}
  newRotations = {}

  newPositions.x = findNewValues(positions.x, res, "pos_x")
  newPositions.y = findNewValues(positions.y, res, "pox_y")
  newScales.x = findNewValues(scales.x, res, "scale_x")
  newScales.y = findNewValues(scales.y, res, "scale_y")
  newRotations = findNewValues(rotations, res, "rotation")

  -- Find framerate of the video
  local framerate
  if aegisub.project_properties!.video_file == ""
    framerate = 23.379
  else
    ref_ms = 100000000                          -- 10^8 ms ~~ 27.7h
    ref_frame = aegisub.frame_from_ms(ref_ms)
    framerate = ref_frame * 1000 / ref_ms

  -- Generate the motion tracking data
  trackingData = "Adobe After Effects 6.0 Keyframe Data

	Units Per Second	{framerate}
	Source Width	{res_x}
	Source Height	{res_y}
	Source Pixel Aspect Ratio	1
	Comp Pixel Aspect Ratio	1

Position
	Frame	X pixels	Y pixels	Z pixels

Scale
	Frame	X percent	Y percent	Z percent

Rotation
	Frame Degrees

End of Keyframe Data
"
  trackingData = trackingData\gsub("{res_x}", lines.meta.PlayResX)\gsub("{res_y}", lines.meta.PlayResY)\gsub("{framerate}", framerate)
  for i = #newPositions.x, 1, -1
    trackingData = trackingData\gsub "(Z pixels\n)", "%1\t#{i}\t#{newPositions.x[i]}\t#{newPositions.y[i]}\t0\n"
  for i = #newScales.x, 1, -1
    trackingData = trackingData\gsub "(Z percent\n)", "%1\t#{i}\t#{newScales.x[i]}\t#{newScales.y[i]}\t0\n"
  for i = #newRotations, 1, -1
    trackingData = trackingData\gsub "(Degrees\n)", "%1\t#{i}\t#{-newRotations[i]}\n"

  -- Apply tracking data
  mainData = DataWrapper!
  config = { clip: {}, main: {
    absPos: false
    linear: false
    killTrans: true
    xScale: true
    border: true
    shadow: true
    blur: true
    vectClip: true
    blurScale: 1
    xPosition: true
    zRotation: true
    rectClip: true
    yPosition: true
    startFrame: 1
    writeConf: true
    origin: true
    clipOnly: false
    relative: true
    rcToVc: false
  }}
  unless res.origin
    config.main.origin = false

  if res.extrapolateLocation == "Start"
    lines = LineCollection sub, {sel[1]}
    config.main.startFrame = res.frameNumber + 1
  else
    lines = LineCollection sub, {sel[#sel]}
  lines\deleteLines!

  parsed = mainData\bestEffortParsingAttempt trackingData, lines.meta.PlayResX, lines.meta.PlayResY

  windowAssertError parsed, "Something went horribly wrong while generating motion tracking data."
  windowAssertError mainData.dataObject\checkLength lines.totalFrames, "The length of generated tracking data does not match line duration."

  mainData.dataObject\addReferenceFrame config.main.startFrame
  mainData.dataObject\stripFields config.main
  rectClipData, vectClipData = mainData, mainData
  lines.options = config
  motionHandler = MotionHandler lines, mainData, rectClipData, vectClipData
  newLines = motionHandler\applyMotion!
  newLines\replaceLines!

  -- Debugging
  debug = false
  return if not debug
  generateData = (original, new) ->
    aegi_x = table.concat([i for i = 1, #original], ", ")
    aegi_y = table.concat([item for item in *original], ", ")
    local extra_x, extra_y
    if res.extrapolateLocation == "Start"
      extra_x = table.concat([ i for i = 1,  1 - res.frameNumber, -1], ", ")
      extra_y = table.concat([new[i] for i = #new, 1, -1], ", ")
    else
      extra_x = table.concat([ i for i = #original, #original + res.frameNumber], ", ")
      extra_y = table.concat([item for item in *new], ", ")
    return "[#{aegi_x}], [#{aegi_y}], [#{extra_x}], [#{extra_y}]"

  pathsep = package.config\sub 1,1
  pyfile = aegisub.decode_path('?temp' .. pathsep .. 'extrapolate.py')
  pycode = "from matplotlib import pyplot as plt
pos_x_aegi_x, pos_x_aegi_y, pos_x_extra_x, pos_x_extra_y = #{generateData(positions.x, newPositions.x)}
pos_y_aegi_x, pos_y_aegi_y, pos_y_extra_x, pos_y_extra_y = #{generateData(positions.y, newPositions.y)}
scale_x_aegi_x, scale_x_aegi_y, scale_x_extra_x, scale_x_extra_y = #{generateData(scales.x, newScales.x)}
scale_y_aegi_x, scale_y_aegi_y, scale_y_extra_x, scale_y_extra_y = #{generateData(scales.y, newScales.y)}
rot_aegi_x, rot_aegi_y, rot_extra_x, rot_extra_y = #{generateData(rotations, newRotations)}

fig, ax = plt.subplots(2,3)
ax[0,0].plot(pos_x_aegi_x, pos_x_aegi_y, label=\"Original\")
ax[0,1].plot(pos_y_aegi_x, pos_y_aegi_y, label=\"Original\")
ax[1,0].plot(scale_x_aegi_x, scale_x_aegi_y, label=\"Original\")
ax[1,1].plot(scale_y_aegi_x, scale_y_aegi_y, label=\"Original\")
ax[0,2].plot(rot_aegi_x, rot_aegi_y, label=\"Original\")
ax[0,0].plot(pos_x_extra_x, pos_x_extra_y, label=\"Extrapolated\")
ax[0,1].plot(pos_y_extra_x, pos_y_extra_y, label=\"Extrapolated\")
ax[1,0].plot(scale_x_extra_x, scale_x_extra_y, label=\"Extrapolated\")
ax[1,1].plot(scale_y_extra_x, scale_y_extra_y, label=\"Extrapolated\")
ax[0,2].plot(rot_extra_x, rot_extra_y, label=\"Extrapolated\")
ax[0,0].legend()
ax[0,1].legend()
ax[1,0].legend()
ax[1,1].legend()
ax[0,2].legend()
ax[0,0].title.set_text(\"Position X\")
ax[0,1].title.set_text(\"Position Y\")
ax[1,0].title.set_text(\"Scale X\")
ax[1,1].title.set_text(\"Scale Y\")
ax[0,2].title.set_text(\"Rotation\")
plt.show()
"
  f = io.open pyfile, 'w'
  f\write pycode
  f\close!
  os.execute "python #{pyfile}"

depctrl\registerMacro main
