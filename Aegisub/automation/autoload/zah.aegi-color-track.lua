local tr = aegisub.gettext

script_name = tr"Aegisub-Color-Tracking"
script_description = tr"Tracking the color from a given pixel or tracking data"
script_author = "Zahuczky, garret"
script_version = "2.1.0"
script_namespace = "zah.aegi-color-track"

-- Conditional depctrl support. Will work without depctrl.
local haveDepCtrl, DependencyControl, depCtrl = pcall(require, "l0.DependencyControl")
local ConfigHandler, config, petzku, util
if haveDepCtrl then
    depCtrl = DependencyControl {
        feed="https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json",
        {
            {"petzku.util", version="0.3.0", url="https://github.com/petzku/Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"},
            {"a-mo.ConfigHandler", version= "1.1.4", url= "https://github.com/TypesettingTools/Aegisub-Motion",
             feed= "https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
            "aegisub.util"
        }
    }
    petzku, ConfigHandler, util = depCtrl:requireModules()
else
    petzku = require 'petzku.util'
    ConfigHandler = require 'a-mo.ConfigHandler'
    util = require 'aegisub.util'
end


local GUI = {
    main= {
      mode_label = {class= "label",  x= 0, y= 0, width= 1, height= 1, label= "Color mode"},
      data_label = {class= "label",  x= 0, y= 1, width= 1, height= 1, label= "Tracking data"},
      data = {class= "textbox", name="data",  x= 0, y= 2, width= 2, height= 3},
      pixel_label = {class= "label",  x= 0, y= 5, width= 1, height= 1, label= "Defined pixel to track:"},
      pixX = {class= "intedit", config=true,  x= 0, y= 6, width= 1, height= 1, value= 0},
      pixY = {class= "intedit", config=true,  x= 0, y= 7, width= 1, height= 1, value= 0},
      posx_label = {class= "label",  x= 1, y= 6, width= 1, height= 1, label= "Position X"},
      posy_label = {class= "label",  x= 1, y= 7, width= 1, height= 1, label= "Position Y"},
      c = {class= "checkbox", x= 0, y= 8, width= 1, config=true, height= 1, label= "\\c (fill)", value= true},
      c2 = {class= "checkbox", x= 1, y= 8, width= 1, config=true, height= 1, label= "\\2c (secondary)", value= false},
      c3 = {class= "checkbox", x= 0, y= 9, width= 1, config=true, height= 1, label= "\\3c (border)", value= false},
      c4 = {class= "checkbox", x= 1, y= 9, width= 1, config=true, height= 1, label= "\\4c (shadow)", value= false},
      setting = {class= "dropdown",  x= 0, y= 10, width= 2, height= 1, config=true, items= {"Defined pixels","Tracking Data"}, value= "Defined pixels"}
      },

      alpha = {
        mode_label = {class= "label",  x= 0, y= 0, width= 1, height= 1, label= "Alpha mode"},
        data_label = {class= "label",  x= 0, y= 1, width= 1, height= 1, label= "Tracking data"},
        data = {class= "textbox", name="data",  x= 0, y= 2, width= 2, height= 3},
        pixel_label = {class= "label",  x= 0, y= 5, width= 1, height= 1, label= "Defined pixel to track:"},
        pixX = {class= "intedit", config=true,  x= 0, y= 6, width= 1, height= 1, value= 0},
        pixY = {class= "intedit", config=true,  x= 0, y= 7, width= 1, height= 1, value= 0},
        posx_label = {class= "label",  x= 1, y= 6, width= 1, height= 1, label= "Position X"},
        posy_label = {class= "label",  x= 1, y= 7, width= 1, height= 1, label= "Position Y"},
        opaque_label = {class= "label",  x= 0, y= 8, width= 1, height= 1, label= "Sign color"},
        startc = {class= "color", config=true,  x= 1, y= 8, width= 1, height= 1},
        transparent_label = {class= "label",  x= 0, y= 9, width= 1, height= 1, label= "Background color"},
        endc = {class= "color", config=true,  x= 1, y= 9, width= 1, height= 1},
        all = {class= "checkbox", x= 0, y= 10, width= 1, config=true, height= 1, label= "\\alpha (all)", value= true},
        a = {class= "checkbox", x= 0, y= 11, width= 1, config=true, height= 1, label= "\\1a (fill)", value= true},
        a2 = {class= "checkbox", x= 1, y= 11, width= 1, config=true, height= 1, label= "\\2a (secondary)", value= false},
        a3 = {class= "checkbox", x= 0, y= 12, width= 1, config=true, height= 1, label= "\\3a (border)", value= false},
        a4 = {class= "checkbox", x= 1, y= 12, width= 1, config=true, height= 1, label= "\\4a (shadow)", value= false},
        setting = {class= "dropdown",  x= 0, y= 13, width= 2, height= 1, config=true, items= {"Defined pixels","Tracking Data"}, value= "Defined pixels"}
      }

}



-- GUI inicialization with config
local function showDialog(macro)
  local options = ConfigHandler(GUI, depCtrl.configFile, false, script_version, depCtrl.configDir)
  options:read()
  options:updateInterface(macro)
  if macro == "main" then
    buttons = {tr"OK", tr"Cancel", "Alpha"}
  else
    buttons = {tr"OK", tr"Cancel", "Color"}
  end
  local btn, res = aegisub.dialog.display(GUI[macro], buttons)
  if btn then
    options:updateConfiguration(res, macro)
    options:write()
    return btn, res
  end
end

local function getFrames(line)
  local startFrame = aegisub.frame_from_ms(line.start_time)
  local endFrame = aegisub.frame_from_ms(line.end_time)

  local numOfFrames = endFrame - startFrame

  return startFrame, endFrame, numOfFrames
end

local function formatTimesFfmpeg(startMS, endMS)
  local startS = math.floor(startMS / 1000)
  local startM = math.floor(startS / 60)
  local startH = math.floor(startM / 60)

  startS = startS % 60
  startM = startM % 60

  local startRem = startMS - (1000 * (startS + 60 * (startM + 60 * startH)))

  local fmtStart = string.format("%d:%02d:%02d.%03d", startH, startM, startS, startRem)
  -- in case we get a "negative" timestamp
  if startMS <= 0 then fmtStart = "0:00:00" end

  local endS = math.floor(endMS / 1000)
  local endM = math.floor(endS / 60)
  local endH = math.floor(endM / 60)

  endS = endS % 60
  endM = endM % 60

  local endRem = endMS - (1000 * (endS + 60 * (endM + 60 * endH)))

  local fmtEnd = string.format("%d:%02d:%02d.%03d", endH, endM, endS, endRem)

  return fmtStart, fmtEnd
end

-- XPixels and YPixels are either one single value (tracking fixed pixel) or an array of values
local function getColors(startFrame, endFrame, numOfFrames, XPixels, YPixels)

  -- built-in aegisub API for getting frame data. not necessarily present, fall back to ffmpeg if necessary
  if aegisub.get_frame then
    local colors={}

    -- if we got a single pair of coordinates, coerce them into arrays (of the repeated value) instead
    if type(XPixels) ~= "table" and type(YPixels) ~= "table" then
      local XPixArray = {}
      local YPixArray = {}
      for i=1, numOfFrames do
        XPixArray[i]=XPixels
        YPixArray[i]=YPixels
      end
      XPixels, YPixels = XPixArray, YPixArray
    end

    for i=1, numOfFrames do
      local frame = aegisub.get_frame((startFrame + i-1), false)
      colors[i]=frame:getPixelFormatted(XPixels[i], YPixels[i])
      aegisub.progress.set((i/numOfFrames)*100)
      aegisub.progress.task(string.format("Getting colors from frame %d/%d", i, numOfFrames))
    end
    return colors
  else
    local ffmpegStart, ffmpegEnd = formatTimesFfmpeg(aegisub.ms_from_frame(startFrame), aegisub.ms_from_frame(endFrame))
    local filter = ""
    if type(XPixels) ~= "table" and type(YPixels) ~= "table" then
      filter = 'crop=2:2:' .. XPixels .. ":" .. YPixels
    else
      -- https://video.stackexchange.com/a/29182
      for frame = 1, numOfFrames do -- can definitely be made more efficient by only having one enable=between if the coords are the same, but I can't be bothered.
        filter = filter .. "swaprect=2:2:0:0:" .. XPixels[frame] .. ":" .. YPixels[frame] .. ":enable='between(n," .. frame - 1 .. "," .. frame - 1 .. ")',"
      end
      filter = filter .. "crop=2:2:0:0"
    end

    local pixpath = aegisub.decode_path("?temp/" .. script_namespace ..".pixels")

    local incantation = 'ffmpeg -i "' .. aegisub.project_properties().video_file .. '" -ss ' .. ffmpegStart .. " -to " .. ffmpegEnd .. ' -filter:v "' .. filter .. '" -f rawvideo -pix_fmt rgb24 "'.. pixpath .. '"'
    aegisub.log(4, "incantation: ".. incantation.."\n")
    petzku.io.run_cmd(incantation, true)
    aegisub.log(4, "ran\n")
    local pixfile = io.open(pixpath, "rb")
    local pixels = pixfile:read("*a") -- this motherfucker
    -- not including *a was the root of all the problems with file io
    aegisub.log(4, "pixels len: "..#pixels.."\n")
    pixfile:close()
    local colors = {}
    for i = 0, numOfFrames - 1 do
      local offset = i * 12
      aegisub.log(5, "offset: "..offset.."\n")
      local r = pixels:byte(1 + offset)
      aegisub.log(5, "r pos: "..1 + offset.."\n")
      aegisub.log(5, "r: "..r.."\n")
      local g = pixels:byte(2 + offset)
      aegisub.log(5, "g pos: "..2 + offset.."\n")
      aegisub.log(5, "g: "..g.."\n")
      local b = pixels:byte(3 + offset)
      aegisub.log(5, "b pos: "..3 + offset.."\n")
      aegisub.log(5, "b: "..b.."\n")
      table.insert(colors, util.ass_color(r, g, b))
    end
    os.remove(pixpath) -- will stay there if it failed, might be useful for debugging
    return colors
  end
end

-- convert "color" (html style) to R G B values
local function hexToRGB(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

-- calculate perceived brightness of an RGB color
local function perceivedBrightness(r, g, b)
  return 0.299 * r + 0.587 * g + 0.114 * b
end

-- calculate alpha value
local function calculateAlpha(signColor, backgroundColor, currentColor)
  -- Convert hex colors to RGB
  local sr, sg, sb = hexToRGB(signColor)
  local br, bg, bb = hexToRGB(backgroundColor)
  local cr, cg, cb = hexToRGB(currentColor)
  
  -- Calculate perceived brightness
  local signBrightness = perceivedBrightness(sr, sg, sb)
  local backgroundBrightness = perceivedBrightness(br, bg, bb)
  local currentBrightness = perceivedBrightness(cr, cg, cb)
  
  -- Calculate alpha value
  if currentBrightness == signBrightness then
      return 0
  elseif currentBrightness == backgroundBrightness then
      return 255
  else
      local alpha = 255 * (backgroundBrightness - currentBrightness) / (backgroundBrightness - signBrightness)
      alpha = 255 - math.max(0, math.min(255, alpha))
      return string.format("%02X", alpha)
  end
end

local function assToHtmlColor(assColor)
  -- Remove the "&H" prefix and the trailing "&"
  assColor = assColor:gsub("&H", ""):gsub("&", "")
  
  -- Extract the BB, GG, and RR components
  local bb = assColor:sub(1, 2)
  local gg = assColor:sub(3, 4)
  local rr = assColor:sub(5, 6)
  
  -- Construct the HTML color code
  local htmlColor = "#" .. rr .. gg .. bb
  return htmlColor
end

-- Main function
function colortrack(subtitles, selected_lines, active_line)
  local MODE = "Color"
  -- Assume the whole selection is the same length
  local line = subtitles[selected_lines[1]]
  -- Start gui
  local pressed, res = showDialog("main")
  
  while pressed == "Alpha" or pressed == "Color" do
    if pressed == "Alpha" then
      MODE = "Alpha"
      pressed, res = showDialog("alpha")
    elseif pressed == "Color" then
      MODE = "Color"
      pressed, res = showDialog("main")
    end
  end

  if pressed == "Cancel" then
    return aegisub.cancel()
  end
  
  if not res then
    return aegisub.cancel()
  end

  -- Calculate frame perfect times for trimming
  local startFrame, endFrame, numOfFrames = getFrames(line)

  -- Settings
  local XPixels, YPixels
  if res.setting == "Tracking Data" then
    local dataArray = { }
    XPixels = { }
    YPixels = { }
    local j = 1
    for i in string.gmatch(res.data, "([^\n]*)\n?") do
      dataArray[j] = i
      j = j + 1
    end
    if res.data == "" then
      aegisub.debug.out("You forgot to give me any data, so I quit.\n\n")
      return aegisub.cancel()
    elseif dataArray[9] ~= "Position" and dataArray[9] ~= "Anchor Point" then
      aegisub.debug.out("I have no idea what kind of data you pasted in, but I'm sure it's not what I wanted.\n\nI need After Effects Transform data.\n\nThe same thing you use for Aegisub-Motion.\n\n")
      return aegisub.cancel()
    end

    -- Parsing tracking data
    local posPin = 11
    local dataLength = numOfFrames + 11
    local p = 1
    local helpArray = { }
    for l = posPin, dataLength do
      local o = 1
      for token in string.gmatch(dataArray[l], "%S+") do
        helpArray[o] = token
        o = o + 1
      end
      XPixels[p] = math.floor(helpArray[2])
      YPixels[p] = math.floor(helpArray[3])
      p = p + 1
    end
  elseif res.setting == "Defined pixels" then
    XPixels = res.pixX
    YPixels = res.pixY
  end

  -- if res.setting == "Middle of Rect. Clip" then
  --   if line.text:match("clip") and not line.text:match("clip(m") then
  --     for topX, topY, botX, botY in line.text:gmatch("([-%d.]+).([-%d.]+)") end
  --     for i=1, numOfFrames do
  --       XPixArray[i] = (botX-topX)/2
  --       XPixArray[i] = (botY-topY)/2
  --     end

  --   else
  --     aegisub.debug.out("You don't have a rectangular clip in your line, so I quit.")
  --     aegisub.cancel()
  --   end
  -- end



  --aegisub.debug.out("\n\n\n\nvideo path: "..aegisub.decode_path("?video").."\n\n\n\n"..aegisub.project_properties().video_file.."\n\n\n"..aegisub.decode_path("?temp").."\n\n\n")
  local colors = getColors(startFrame, endFrame, numOfFrames, XPixels, YPixels)

  local function calcTransformTime(i)
    -- Getting accurate times for the \t transform. Thx petzku. :*
    local t_start_frame = aegisub.frame_from_ms(line.start_time)
    local t_start_time = aegisub.ms_from_frame(t_start_frame)
    local ft = aegisub.ms_from_frame(t_start_frame + i) - t_start_time --frame time
    return ft
  end

  local function makeTransformTimes(i)
    local t = calcTransformTime(i)
    return t..","..t..","
  end

  -- Creating a single string from the colors
  local transform = ""
  -- stylua: ignore start
  if MODE == "Color" then
    if colors[1] then
      if res.c then transform = transform.."\\c"..colors[1] end
      if res.c2 then transform = transform.."\\2c"..colors[1] end
      if res.c3 then transform = transform.."\\3c"..colors[1] end
      if res.c4 then transform = transform.."\\4c"..colors[1] end
    end
    for i=2, numOfFrames do
      local color = colors[i]
      -- color could be nil if the tracking point is outside video frame
      if color then
      transform = transform.."\\t("..makeTransformTimes(i-1)
        if res.c then transform = transform.."\\c"..color end
        if res.c2 then transform = transform.."\\2c"..color end
        if res.c3 then transform = transform.."\\3c"..color end
        if res.c4 then transform = transform.."\\4c"..color end
      transform = transform .. ")"
      end
    end
  end
  if MODE == "Alpha" then
    if res.all then
      res.a = false
      res.a2 = false
      res.a3 = false
      res.a4 = false
    end
    if colors[1] then
      alpha = calculateAlpha(res.startc, res.endc, assToHtmlColor(colors[1]))
      if res.all then transform = transform.."\\alpha&H"..alpha.."&" end
      if res.a then transform = transform.."\\1a&H"..alpha.."&" end
      if res.a2 then transform = transform.."\\2a&H"..alpha.."&" end
      if res.a3 then transform = transform.."\\3a&H"..alpha.."&" end
      if res.a4 then transform = transform.."\\4a&H"..alpha.."&" end
    end
    for i=2, numOfFrames do
      local color = colors[i]
      -- color could be nil if the tracking point is outside video frame
      if color then
        alpha = calculateAlpha(res.startc, res.endc, assToHtmlColor(color))
        transform = transform.."\\t("..makeTransformTimes(i-1)
        if res.all then transform = transform.."\\alpha&H"..alpha.."&" end
        if res.a then transform = transform.."\\1a&H"..alpha.."&" end
        if res.a2 then transform = transform.."\\2a&H"..alpha.."&" end
        if res.a3 then transform = transform.."\\3a&H"..alpha.."&" end
        if res.a4 then transform = transform.."\\4a&H"..alpha.."&" end
      transform = transform .. ")"
      end
    end
  end

  -- Put the string in the lines
  for _, si in ipairs(selected_lines) do
    local l = subtitles[si]
    if l.text:match("\\pos") then
      l.text = l.text:gsub("\\pos", transform.."\\pos")
    elseif l.text:match("\\move") then
      l.text = l.text:gsub("\\move", transform.."\\move")
    else
      l.text = l.text:gsub("}", transform.."}", 1)
    end
    subtitles[si] = l
  end

  -- aegisub.debug.out("-----Test-----")
  -- if (testVal.width ~= img.width) then
    -- error("Test failed: width")
  -- elseif (testVal.height ~= img.height) then
    -- error("Test failed: height")
  -- elseif (testVal.depth ~= img.depth) then
    -- error("Test failed: depth")
  -- elseif (testVal.pixelColor ~= getPixelStr(pixel)) then
    -- error("Test failed: color")
  -- else
    -- aegisub.debug.out("Tests passed!")
  -- end



  -- aegisub.debug.out("it works!  R:"..mypixel1.."\n G:"..mypixel2.."\n B:"..mypixel3)
  -- aegisub.debug.out("\n\nstart time: "..starttime.."\n end time: "..endtime)
  -- aegisub.debug.out("\n\nstart frame: "..startframe.."\n end frame: "..endframe)
  -- aegisub.debug.out("\n\nlengthframe: "..endframe-startframe)

  -- os.remove("C:\\Users\\zozic\\AppData\\Roaming\\Aegisub\\log\\frame0001.png")


  -- for i=1, numOfFrames do
  --   runTests(trackedImg, i)
  -- end

  -- aegisub.debug.out("first: "..reds[1].." - "..greens[1].." - "..blues[1])
  -- aegisub.debug.out("\n\nsecond: "..reds[2].." - "..greens[2].." - "..blues[2])
  -- aegisub.debug.out("first: "..fillHexTable[1])
  -- aegisub.debug.out("\nsecond: "..fillHexTable[2])
  -- aegisub.debug.out("works: \n"..transform)

  -- I don't remember what it does and might not even be needed anymore but whatever I'm lazy to test it.
  aegisub.set_undo_point(script_name)
end



-- Register the macro, with depctrl if you have, regularly if you don't.
if haveDepCtrl then
  return depCtrl:registerMacro(colortrack)
else
  return aegisub.register_macro(script_name, script_description, colortrack)
end
