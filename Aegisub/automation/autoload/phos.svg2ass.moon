export script_name = "svg2ass"
export script_description = "Script that uses ink2ass to convert svg files to ass lines"
export script_version = "2.0.0"
export script_author = "PhosCity"
export script_namespace = "phos.svg2ass"

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
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    },
}
LineCollection, ASS, Functional, AegiGui = depctrl\requireModules!
logger = depctrl\getLogger!
{:list, :string} = Functional

defaultConfig =
    ink2assPath: ""

config = depctrl\getConfigHandler defaultConfig

print_and_exit = (message) ->
    logger\log message
    aegisub.cancel!

select_file = (file_name, file_type) ->
    pathsep = package.config\sub(1, 1)
    filename = aegisub.dialog.open("Select #{file_name} file", "", aegisub.decode_path("?script")..pathsep, "#{file_type} files (.#{file_type})|*.#{file_type}", false, true)
    aegisub.cancel! unless filename
    return filename


configSetup = ->
    config.c.ink2assPath = select_file("Python","py")
    config\write!


createGUI = ->
    dialog_str = "
    | drop, result_type, drawing::clip::iclip, drawing ||
    | check, pasteover, Pasteover, false, Convert svg but paste shape date over selected lines | pad, 50 |
    "

    dialog, button, buttonID = AegiGui.create dialog_str, "Import:ok, Cancel:cancel"
    btn, res = aegisub.dialog.display(dialog, button, buttonID)
    aegisub.cancel! if btn == "Cancel"
    return res


-- Surveys the selected lines. Returns the least starting time, max end time and a style among them
reconnaissance = (sub, sel) ->
    startTime, endTime, styleList = math.huge, 0, {}
    for i in *sel
        startTime = math.min(startTime, sub[i].start_time)
        endTime = math.max(endTime, sub[i].end_time)
        styleList[#styleList + 1] = sub[i].style
    styleList = list.uniq styleList

    local style
    if #styleList < 2
        style = styleList[1]
    else
        dialog_str = "
        | label, Your selection has multiple styles. Please select one: |
        | drop, stl, #{table.concat(styleList,"::")}, #{styleList[1]}   |
        "

        dialog, button, buttonID = AegiGui.create dialog_str, "Ok:ok, Cancel:cancel"
        btn, res = aegisub.dialog.display(dialog, button, buttonID)
        aegisub.cancel! if btn == "Cancel"
        style = res.stl
    return startTime, endTime, style


sanitize_result = (result, res) ->
    match_string = ""
    if res.pasteover
        match_string = "m [%d%.%a%s%-]+"
    elseif res.clip
        match_string = "\\clip%(m [%d%.%a%s%-]+"
    elseif res.iclip
        match_string = "\\iclip%(m [%d%.%a%s%-]+"
    else
        match_string = "Dialogue: %d+,[^,]+,[^,]+,[^,]+,,%d+,%d+,%d+,,.+"

    result = string.split(result, "\n")
    sanitized_result, isInvalid = {}, false
    for line in *result
        continue if line == ""
        if line\match match_string
            table.insert sanitized_result, line
            continue
        logger\log "Invalid line: #{line}"
        isInvalid = true

    aegisub.cancel! if isInvalid
    return sanitized_result


-- Check if svg2ass exists in the path given in config
checkInk2assExists = (path) ->
    handle = io.open(path, "r")
    if handle
        io.close!
        return
    print_and_exit "ink2ass file not found. Please install it and try again."


-- Execute the command
runCommand = (command) ->
    handle = io.popen(command)
    output = handle\read("*a")
    success = handle\close!
    unless success
        print_and_exit "The program did not run successfully.\nHere's what you can do: Run the python code in commandline.\nOr send svg file to Phos in discord to check."
    return output


main = (sub, sel) ->

    config\load!
    opt = config.c
    res = createGUI!
    startTime, endTime, style = reconnaissance(sub, sel)

    checkInk2assExists opt.ink2assPath
    filename = select_file("SVG", "svg")

    output_type = res.pasteover and "drawing" or res.clip and "clip" or res.iclip and "iclip" or "line"
    command = "python \"#{opt.ink2assPath}\" \"#{filename}\" --output_format=\"#{output_type}\""
    result = runCommand(command)

    result = sanitize_result result, res

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    -- Pastes the shape data over the selected lines while keeping the original tags
    if res.pasteover
        if #lines.lines ~= #result
            print_and_exit "Number of selected lines (#{#lines.lines}) is not equal to number of output lines (#{#result}). Pasteover failed."

        lines\runCallback ((lines, line, i) ->
            if res.drawing
                line.text = result[i]
            else
                data = ASS\parse line
                shape = result[i]\match "{[^}]+}(.+)"
                drawing = ASS.Draw.DrawingBase{str: shape}

                if res.clip
                    data\replaceTags {ASS\createTag "clip_vect", drawing}
                elseif res.iclip
                    data\replaceTags {ASS\createTag "iclip_vect", drawing}

                data\commit!
        ), true
        lines\replaceLines!
        return lines\getSelection!
    else
        -- Add shapes as new lines
        for ln in *(list.reverse result)
            if res.clip or res.iclip
                ln = "Dialogue: 0,0:00:00.00,0:00:05.00,Default,,0,0,0,,{#{ln}}"

            newLine = ASS\createLine {
                ln
                lines
                start_time: startTime
                end_time: endTime
                style: style
            }
            lines\addLine newLine, nil, true, sel[1]
        lines\insertLines!
        return [x for index, x in ipairs lines\getSelection! when index > #sel]


depctrl\registerMacros({
  {"Run", "Run the script", main},
  {"Config", "Configuration for e script", configSetup}
})
