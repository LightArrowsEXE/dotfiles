export script_name = "Timing Assistant"
export script_description = "A second brain for timers."
export script_version = "2.0.0"
export script_author = "PhosCity"
export script_namespace = "phos.TimingAssistant"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"
    {
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    }
}
AegiGUI = depctrl\requireModules!
logger = depctrl\getLogger!

getTime, getFrame = aegisub.ms_from_frame, aegisub.frame_from_ms

defaultConfig =
    startLeadIn: 120
    startKeysnapBefore: 350
    startKeysnapAfter: 100
    startLink: 620
    endLeadOut: 400
    endKeysnapBefore: 300
    endKeysnapAfter: 900
    debug: false
    automove: false
    gap: 0

config = depctrl\getConfigHandler {
    presets: {
        Default: {}
    }
    currentPreset: "Default"
}
config\write! unless config\load!


savePreset = (preset, res) ->
    preset\import res, nil, true
    if res.__class != DependencyControl.ConfigHandler
        for key, value in pairs res
            continue if key == "presetModify" or key == "presetSelect"
            preset.c[key] = value
    preset\write!


createNewPreset = (settings) ->
    msg = "Enter name of the preset:"
    while true
        guiString = "| label,msg                             |            |
                     | label, Preset Name                    | edit, name |
                     | check, setCurrent,Set as Current Name |            |"

        guiString = guiString\gsub "msg", msg

        btn, res = AegiGUI.open guiString
        aegisub.cancel! unless btn

        presetName = res.name
        if presetName == ""
            msg = "You left the name empty!"
        elseif presetName == "Default"
            msg = "Default preset already exists."
        elseif config.c.presets[presetName]
            msg = "There is already another preset of same name."
        else
            if res.setCurrent
                config.c.currentPreset = presetName
                config\write!
            preset = config\getSectionHandler {"presets", presetName}, defaultConfig
            savePreset preset, settings
            return presetName


configSetup = (presetName)->
    config\load!
    if type(presetName) != "string"
        presetName = config.c.currentPreset
    presetNames = [key for key, _ in pairs config.c.presets]
    table.sort presetNames
    dropPreset = table.concat(presetNames, "::")..","..presetName

    preset = config\getSectionHandler {"presets", presetName}, defaultConfig

    guiStringLeft = "
| label, Current Preset: #{config.c.currentPreset}       |                                                                                        |
| label, -- Start -----                                  |                                                                                        |
| label, Lead in amount from exact start                 |                                                                                        |
| label, Lead in                                         | int, startLeadIn, #{preset.c.startLeadIn},,,Recommended value: 100-150 ms              |
| label, Time to snap to keyframe before the exact start |                                                                                        |
| label, Key Snap Before                                 | int, startKeysnapBefore, #{preset.c.startKeysnapBefore},,,Recommended value: ~3*leadin |
| label, Time to snap to keyframe after the exact start  |                                                                                        |
| label, Key Snap After                                  | int, startKeysnapAfter, #{preset.c.startKeysnapAfter},,,Recommended value: 0-100 ms    |
| label, Time from exact start of current line to end-time of previous line to link                                                              ||
| label, Line Link                                       | int, startLink, #{preset.c.startLink},,,Recommended value: ~500+leadin                 |
|                                                        |                                                                                        |
| label, -- Gap -----                                    |                                                                                        |
| label, Gap between lines                               | int, gap, #{preset.c.gap},,,Recommended value: 0 ms                                    |
|                                                        |                                                                                        |
| check, automove, Auto-move to next line after making changes,#{preset.c.automove}                                                              ||
| label, Preset |drop,presetSelect,#{dropPreset}| "

    guiStringRight = "
|    |                                                      |                                                                                     |
|null| label, -- End -----                                  |                                                                                     |
|null| label, Lead out amount from exact end                |                                                                                     |
|null| label, Lead out                                      | int, endLeadOut, #{preset.c.endLeadOut},,,Recommended value: 350-450 ms             |
|null| label, Time to snap to keyframe before the exact end |                                                                                     |
|null| label, Key Snap Before                               | int, endKeysnapBefore, #{preset.c.endKeysnapBefore},,,Recommended value: 100-300 ms |
|null| label, Time to snap to keyframe after the exact end  |                                                                                     |
|null| label, Key Snap After                                | int, endKeysnapAfter, #{preset.c.endKeysnapAfter},,,Recommended value: 800-1000 ms  |
|null|                                                      |                                                                                     |
|null|                                                      |                                                                                     |
|    |                                                      |                                                                                     |
|    |                                                      |                                                                                     |
|null|                                                      |                                                                                     |
|    |                                                      |                                                                                     |
|    | check, debug, Debug, #{preset.c.debug}               |                                                                                     |
|    | drop, presetModify, Load::Modify::Delete::Rename::Set Current,Load |                                                                       |
"
    btn, res = AegiGUI.merge guiStringLeft, guiStringRight, "Modify Preset, Create Preset, Close:cancel", 2, 0, true
    aegisub.cancel! unless btn

    if btn == "Create Preset"
        createNewPreset res
        configSetup!
    elseif btn == "Modify Preset"
        if presetName != res.presetSelect
            preset = config\getSectionHandler {"presets", res.presetSelect}, defaultConfig
            presetName = res.presetSelect

        switch res.presetModify
            when "Load"
                configSetup presetName
            when "Set Current"
                config.c.currentPreset = presetName
                config\write!
                return

        logger\assert res.presetSelect != "Default", "You probably should not modify default preset. Create a new custom preset instead."
        switch res.presetModify
            when "Delete"
                config.c.currentPreset = "Default"
                config\write!
                preset\delete!
            when "Modify"
                savePreset preset, res
            when "Rename"
                presetName = createNewPreset preset.userConfig
                preset\delete!
        configSetup!


debugMsg = (opt, msg) -> logger\log msg if opt.debug


isKeyframe = (time) ->
    keyframe = aegisub.keyframes!
    currFrame = getFrame time
    for kf in *keyframe
        return true if currFrame == kf
    false


calculateCPS = (line) ->
    text = line.text
    duration = (line.end_time - line.start_time)/1000
    char = text\gsub("%b{}", "")\gsub("\\[Nnh]", "*")\gsub("%s?%*+%s?", " ")\gsub("[%s%p]", "")
    math.ceil(char\len!/duration)


findAdjacentKeyframes = (time) ->
    keyframe = aegisub.keyframes!
    local previousKeyframe, nextKeyframe
    currFrame = getFrame time
    for k, kf in ipairs keyframe
        previousKeyframe = keyframe[k] if kf < currFrame
        nextKeyframe = keyframe[k] if kf > currFrame
        break if nextKeyframe
    return previousKeyframe, nextKeyframe


timeStart = (sub, sel, opt) ->
    for i in *sel
        continue unless sub[i].class == "dialogue"
        line = sub[i]
        local snap, link, previousLine, endTimePrevious
        startTime, endTime = aegisub.get_audio_selection!

        debugMsg opt, "Start:"

        -- Determine if start time of current line is already snapped to keyframe and exit if it is
        if isKeyframe(startTime)
            debugMsg opt, "Line start was already snapped to keyframe"
            return

        -- Determine the previous non-commented line.
        j = 1
        while true
            previousLine = sub[i - j]
            break if previousLine.comment == false or i - j <= 1
            j += 1

        -- Determine the end time of previous line
        endTimePrevious = previousLine.end_time

        -- Keyframe Snapping
        previousKeyframe, nextKeyframe = findAdjacentKeyframes startTime
        if math.abs(getTime(previousKeyframe) - startTime) < opt.startKeysnapBefore
            line.start_time = getTime previousKeyframe
            snap = true
            debugMsg opt, "Keyframe snap behind"
        if math.abs(getTime(nextKeyframe) - startTime) < opt.startKeysnapAfter and not snap
            line.start_time = getTime nextKeyframe
            snap = true
            debugMsg opt, "Keyframe snap ahead"

        -- Line Linking
        if endTimePrevious and math.abs(endTimePrevious - startTime) < opt.startLink and not isKeyframe(endTimePrevious)
            previousKeyframe, nextKeyframe = findAdjacentKeyframes endTimePrevious
            keyframePlus500ms = getTime(previousKeyframe) + 500

            if startTime < endTimePrevious and endTimePrevious < keyframePlus500ms
                line.start_time = startTime - opt.startLeadIn unless snap
                previousLine.end_time = getTime previousKeyframe
                debugMsg opt, "Link lines failed because a keyframe is close. Snap end of last line. Add lead in to current line."

            elseif (startTime - opt.startLeadIn) > (getTime(nextKeyframe) - 500)
                line.start_time = getTime(nextKeyframe) - 500 unless snap
                previousLine.end_time = line.start_time - opt.gap
                debugMsg opt, "Link lines by ensuring that start time is 500 ms away from next keyframe."

            else
                line.start_time = startTime - math.min(opt.startLeadIn, startTime - keyframePlus500ms) unless snap
                previousLine.end_time = line.start_time - opt.gap
                debugMsg opt, "Link lines by adding appropriate lead in to current line."

            sub[i - j] = previousLine
            link = true

        -- lead in
        unless snap or link
            line.start_time = startTime - opt.startLeadIn
            debugMsg opt, "Lead In"

        line.end_time = endTime
        sub[i] = line


timeEnd = (sub, sel, opt) ->
    for i in *sel
        continue unless sub[i].class == "dialogue"
        line = sub[i]
        _, endTime = aegisub.get_audio_selection!
        local snap

        debugMsg opt, "\nEnd:"

        -- Determine if end time of current line is already snapped to keyframe and exit if it is
        if isKeyframe(endTime)
            debugMsg opt, "Line end was already snapped to keyframe"
            return

        -- Find the previous and next keyframe for end time
        previousKeyframe, nextKeyframe = findAdjacentKeyframes endTime

        -- If the keyframe is after 850 ms and before the limit you set, check the cps
        -- If cps is less than 15, then add normal lead out or make the end time 500 ms far from keyframe whichever is lesser
        -- If cps is more than 15, then snap to keyframe
        nextKfDistance = math.abs(getTime(nextKeyframe) - endTime)
        previousKfDistance = math.abs(getTime(previousKeyframe) - endTime)
        if opt.endKeysnapAfter >= 850 and nextKfDistance >= 850 and nextKfDistance <= opt.endKeysnapAfter and previousKfDistance > opt.endKeysnapBefore
            cps = calculateCPS(line)
            if cps <= 15
                line.end_time = endTime + math.min(opt.endLeadOut, nextKfDistance  - 500)
                debugMsg opt, "cps is less than 15.\nAdjusting end time so that it's 500 ms away from keyframe or adding lead out whichever is lesser." 
            else
                line.end_time = getTime nextKeyframe
                debugMsg opt, "cps is more than 15.\nSnapping to keyframe more than 850 ms away."
        else
            -- Keyframe Snapping
            if previousKfDistance < opt.endKeysnapBefore
                line.end_time = getTime previousKeyframe
                snap = true
                debugMsg opt, "Keyframe snap behind"
            if nextKfDistance < opt.endKeysnapAfter and not isKeyframe(line.end_time)
                line.end_time = getTime nextKeyframe
                snap = true
                debugMsg opt, "Keyframe snap ahead"

            -- Lead out
            unless snap
                line.end_time = endTime + opt.endLeadOut
                debugMsg opt, "Lead Out"
        sub[i] = line


timeBoth = (sub, sel) ->
    logger\assert #sel == 1, "You must select exactly one line\nThis is not a TPP replacement."
    config\load!
    preset = config\getSectionHandler {"presets", config.c.currentPreset}, defaultConfig
    timeStart sub, sel, preset.c
    timeEnd sub, sel, preset.c

    if preset.c.automove and sel[1] + 1 <= #sub
        return { sel[1] + 1}

depctrl\registerMacros({
  { "Time", "Time the line after exact timing", timeBoth },
  { "Config", "Configuration for the script", configSetup }
})
