export script_name = "terrain"
export script_description = "Interpolate between two vectorial clips with same number of points."
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.terrain"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    },
}
LineCollection, ASS, AegiGui = depctrl\requireModules!
logger = depctrl\getLogger!


print_and_exit = (message) ->
    logger\log message
    aegisub.cancel!


createGUI = ->
    dialog_str = "
    | int, points, _, 1 |
    "

    dialog, button, buttonID = AegiGui.create dialog_str, "Create Terrain, Add Intermediate Points, Cancel:cancel"
    btn, res = aegisub.dialog.display(dialog, button, buttonID)
    aegisub.cancel! if btn == "Cancel"
    return res, btn


lerp = (a, b, t) ->
    a + (b - a) * t


interpolate_points = (p1, p2, n) ->
    points = {}

    for i = 1, n
        t = i / (n + 1)
        points[#points + 1] = lerp(p1.x, p2.x, t)
        points[#points + 1] = lerp(p1.y, p2.y, t)

    points


interpolate_tables = (t1, t2, steps) ->
    results = {}

    for step = 0, steps
        alpha = step / steps
        frame = {}

        for i = 1, #t1
            p1 = t1[i]
            p2 = t2[i]

            frame[i] = {
                lerp p1[1], p2[1], alpha
                lerp p1[2], p2[2], alpha
            }

        results[#results + 1] = frame

    results


append_reverse = (t) ->
    n = #t
    for i = n - 1, 1, -1
        table.insert t, t[i]


main = (sub, sel) ->
    res, btn = createGUI!

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    if btn == "Add Intermediate Points"
        lines\runCallback (lines, line, i) ->
            data = ASS\parse line
            clipTable = data\getTags "clip_vect"
            if #clipTable == 0
                print_and_exit "No vectorial clip found."

            start_point = {}
            end_point = {}
            for index, cnt in ipairs clipTable[1].contours[1].commands          -- Is this the best way to loop through co-ordinate?
                x, y = cnt\get!
                if index == 1
                    start_point["x"] = x
                    start_point["y"] = y
                elseif index == 2
                    end_point["x"] = x
                    end_point["y"] = y
                else
                    print_and_exit "Found a vectorial clip with more than two points.\nI don't know what to do with it."

            middle_points = interpolate_points start_point, end_point, res.points

            shape_str = table.concat {
                "m #{start_point["x"]} #{start_point["y"]}"
                "l"
                table.concat middle_points, " "
                "#{end_point["x"]} #{end_point["y"]}"
            }, " "


            drawing = ASS.Draw.DrawingBase {str: shape_str}

            data\replaceTags {ASS\createTag 'clip_vect', drawing}
            data\commit!
        lines\replaceLines!
    else
        if #lines.lines != 2
            print_and_exit "Only select two lines that has vectorial clip"

        table_1 = {}
        table_2 = {}
        local startTime, endTime, style
        lines\runCallback (lines, line, i) ->
            data = ASS\parse line
            startTime = line.start_time
            endTime = line.end_time
            style = line.style
            clipTable = data\getTags "clip_vect"
            -- line.comment = true
            if #clipTable == 0
                print_and_exit "No vectorial clip found."

            for index, cnt in ipairs clipTable[1].contours[1].commands          -- Is this the best way to loop through co-ordinate?
                x, y = cnt\get!
                if i == 1
                    table.insert table_1, {x, y}
                else
                    table.insert table_2, {x, y}

        if #table_1 != #table_2
            print_and_exit "Unequal number of points in clips"

        append_reverse table_1
        append_reverse table_2

        frames = interpolate_tables table_1, table_2, res.points
        shape_tbl = {}
        for line in *frames
            for i, coord in ipairs line
                if i == 1
                    shape_tbl[#shape_tbl + 1] = "m #{coord[1]} #{coord[2]} l"
                else
                    shape_tbl[#shape_tbl + 1] = "#{coord[1]} #{coord[2]}"
        shape_str = table.concat shape_tbl, " "

        ln = "Dialogue: 0,0:00:00.00,0:00:05.00,Default,,0,0,0,,{\\an7\\pos(0,0)\\p1\\bord1\\shad0\\alpha&H80&}#{shape_str}"

        newLine = ASS\createLine {
            ln
            lines
            start_time: startTime
            end_time: endTime
            style: style
        }
        lines\addLine newLine, nil, true, sel[1]
        lines\insertLines!


depctrl\registerMacro main
