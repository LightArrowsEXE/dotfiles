export script_name = "Vector Gradient"
export script_description = "Magic triangles + blur gradients"
export script_version = "1.0.0"
export script_author = "PhosCity"
export script_namespace = "phos.VectorGradient"

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


createGUI = ->
    dialog_str = "
    | label, -- Wedge -------- |                                            |                        |                                          |
    | label, Thickness         | float, wedgeThicknessRatio, 0.1, 1, 0, 0.1 | label, Spacing         | float, wedgeSpacing, 10, 0               |
    null
    | label, -- Box ---------- |                                            |                        |                                          |
    | label, Spacing           | float, boxSpacing, 20, 0                   |                        |                                          |
    null
    | label, -- Ring --------- |                                            |                        |                                          |
    | label, Spacing           | float, ringSpacing, 20, 0                  |                        |                                          |
    null
    | label, -- Star --------- |                                            |                        |                                          |
    | label, Spike Count       | float, spikeCount, 20, 0                   | label, Central Radius  | float, centralRadius, 0.22, 0.1, 1, 0.01 |
    "
    dialog, button, buttonID = AegiGui.create dialog_str, "Wedge, Box, Ring, Star, Cancel:cancel"
    btn, res = aegisub.dialog.display(dialog, button, buttonID)
    aegisub.cancel! if btn == "Cancel"
    return res, btn


process_three_point_clip = (clip) ->
    x1, y1, x2, y2, x3, y3 = unpack clip
    dx = x2 - x1
    dy = y2 - y1
    length = math.sqrt dx * dx + dy * dy

    -- prevent division by zero
    if length == 0
        logger\warn "Your wedge and box has no length."

    ux = dx / length      -- local X axis unit vector
    uy = dy / length

    -- perpendicular unit vector (local Y axis)
    px = -uy
    py = ux

    -- determine correct perpendicular direction toward point3
    dot = (x3-x1)*px + (y3-y1)*py
    if dot < 0
        px = -px
        py = -py

    height = math.abs(dot)
    return x1, y1, ux, uy, px, py, length, height


add_line = (data, shape) ->
    drawing = ASS.Draw.DrawingBase{str: shape}

    data\removeSections 2, #data.sections
    data\insertSections ASS.Section.Drawing {drawing}
    data\removeTags { "outline_x", "outline_y", "shadow_x", "shadow_y", "shear_x", "shear_y", "angle_x", "angle_y", "clip_vect"}
    data\replaceTags {
        ASS\createTag 'position', 0, 0
        ASS\createTag 'scale_x', 100
        ASS\createTag 'scale_y', 100
        ASS\createTag 'outline', 0
        ASS\createTag 'shadow', 0
        ASS\createTag 'align', 7
    }
    data


wedge = (data, clip, res) ->
    x1, y1, ux, uy, px, py, length, height = process_three_point_clip clip

    spacing = res.wedgeSpacing -- distance between spikes
    thickness = height * res.wedgeThicknessRatio

    -- generate the number of spikes based on the spacing
    count = math.floor(length / spacing)

    -- create shape in local coordainte
    points = {{0, 0}, {0, thickness}}
    for i=1,count
        t0 = (i-1)*spacing
        t1 = math.min i*spacing, length
        mid = (t0+t1)/2

        table.insert points, {mid, height}
        table.insert points, {t1, thickness}

    table.insert points, {length, 0}

    -- transform to global coordinate
    globalPoints = {}
    for p in *points
        lx, ly = unpack p

        gx = x1 + ux * lx + px * ly
        gy = y1 + uy * lx + py * ly

        table.insert globalPoints, {gx, gy}

    shape = "m #{globalPoints[1][1]} #{globalPoints[1][2]} "

    for i=2,#globalPoints
        shape ..= "l #{globalPoints[i][1]} #{globalPoints[i][2]} "

    data = add_line data, shape
    data


box = (data, clip, res) ->
    x1, y1, ux, uy, px, py, length, height = process_three_point_clip clip

    spacing = res.boxSpacing

    -- number of boxes
    N = math.max(1, math.ceil(height / spacing))

    boxes = [ (N - i + 1) for i = 1, N ]   -- N, N-1, ..., 1
    gaps = [ i for i = 1, N ]             -- 1, 2, ..., N

    s = N * (N + 1) / 2
    scale = (height / 2) / s

    boxes = [x * scale for x in *boxes]
    gaps  = [x * scale for x in *gaps]

    -- Generate boxes in local coordinate
    y = 0
    local_shape = {}
    for i = 1, N
        box_h = boxes[i]
        gap_h = gaps[i]

        start = y
        finish = y + box_h

        -- rectangle in LOCAL coords
        table.insert(local_shape, {
            0, start,
            length, start,
            length, finish,
            0, finish
        })

        y = finish + gap_h

    -- Transform boxes in global coordinate
    local_to_global = (lx, ly) ->
        gx = x1 + ux*lx + px*ly
        gy = y1 + uy*lx + py*ly
        gx, gy

    final_shape = ""
    for rect in *local_shape
        xA,yA = local_to_global rect[1], rect[2]
        xB,yB = local_to_global rect[3], rect[4]
        xC,yC = local_to_global rect[5], rect[6]
        xD,yD = local_to_global rect[7], rect[8]
        final_shape ..= "m #{xA} #{yA} l #{xB} #{yB} #{xC} #{yC} #{xD} #{yD} "

    data = add_line data, final_shape
    data


-- helper function to add cubic Bezier circle
bezier_circle = (cx, cy, r, reverse=false) ->
    -- constant factor for cubic Bezier circle approximation
    k = 0.5522847498

    c = r * k
    unless reverse
        return {
            "m",
            cx + r, cy, -- start at rightmost point
            "b",
            cx + r, cy - c, cx + c, cy - r, cx, cy - r, -- first quadrant
            cx - c, cy - r, cx - r, cy - c, cx - r, cy, -- second quadrant
            cx - r, cy + c, cx - c, cy + r, cx, cy + r, -- third quadrant
            cx + c, cy + r, cx + r, cy + c, cx + r, cy  -- fourth quadrant
        }
    else
        return {
            "m",
            cx + r, cy, -- start at rightmost point
            "b",
            cx + r, cy + c, cx + c, cy + r, cx, cy + r  -- fourth quadrant
            cx - c, cy + r, cx - r, cy + c, cx - r, cy, -- third quadrant
            cx - r, cy - c, cx - c, cy - r, cx, cy - r, -- second quadrant
            cx + c, cy - r, cx + r, cy - c, cx + r, cy, -- first quadrant
        }


rings = (data, clip, res) ->
    x1, y1, x2, y2 = unpack clip
    cx = (x1 + x2) / 2
    cy = (y1 + y2) / 2

    spacing = res.ringSpacing

    -- biggest radius = half distance between points
    dx = x2 - x1
    dy = y2 - y1
    radiusMax = math.sqrt(dx*dx + dy*dy) / 2

    -- number of rings based on spacing
    N = math.max(1, math.ceil(radiusMax / spacing))

    -- arithmetic progression for ring thickness
    boxes = [ (N - i + 1) for i = 1, N ]   -- N, N-1, ..., 1
    gaps = [ i for i = 1, N ]             -- 1, 2, ..., N

    s = N * (N + 1) / 2
    scale = (radiusMax / 2) / s

    boxes = [x * scale for x in *boxes]
    gaps  = [x * scale for x in *gaps]

    -- generate rings radii
    rInner = 0
    ringsList = {}
    for i = 1, N
        rOuter = rInner + boxes[i]
        table.insert ringsList, {rInner, rOuter}
        rInner = rOuter + gaps[i]

    finalShape = ""
    for ring in *ringsList
        -- outer circle
        finalShape ..= table.concat(bezier_circle(cx, cy, ring[2]), " ") .. " "

        -- inner circle (hole)
        finalShape ..= table.concat(bezier_circle(cx, cy, ring[1], true), " ") .. " "

    data = add_line data, finalShape
    data


star = (data, clip, res) ->
    x1, y1, x2, y2 = unpack clip
    cx = (x1 + x2) / 2
    cy = (y1 + y2) / 2

    spikeCount = res.spikeCount   -- number of spikes
    centerRatio = res.centralRadius  -- size of central circle (0.0 to 1.0)

    -- biggest radius = half distance between points
    radius = math.sqrt((x2-x1)^2 + (y2-y1)^2)/2
    effectiveRadius = radius * centerRatio

    step = 2*math.pi / spikeCount

    shape = {}
    for i = 0, spikeCount - 1
        a0 = i * step
        a1 = a0 + step / 2
        a2 = a0 + step

        -- inner point
        table.insert shape, cx + math.cos(a0) * effectiveRadius
        table.insert shape, cy + math.sin(a0) * effectiveRadius

        if i == 0
            table.insert shape, "l"

        -- outer point
        table.insert shape, cx + math.cos(a1) * radius
        table.insert shape, cy + math.sin(a1) * radius

        -- next inner point
        table.insert shape, cx + math.cos(a2) * effectiveRadius
        table.insert shape, cy + math.sin(a2) * effectiveRadius

    data = add_line data, "m " .. table.concat(shape, " ")
    data


main = (sub, sel) ->
    res, btn = createGUI!
    lines = LineCollection sub, sel
    return if #lines.lines == 0
    lines\runCallback (lines, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        data = ASS\parse line

        hasClip, clip = false, {}
        clipCount = btn == "Wedge" and 3 or btn == "Box" and 3 or 2
        clipTable = data\getTags "clip_vect"
        if #clipTable != 0
            hasClip = true
            for index, cnt in ipairs clipTable[1].contours[1].commands          -- Is this the best way to loop through co-ordinate?
                break if index == clipCount + 1
                x, y = cnt\get!
                table.insert clip, x
                table.insert clip, y
        if hasClip and #clip != 2 * clipCount
            logger\warn "Clip found in line #{line.humanizedNumber} but the clip has less than #{clipCount} points.\nSkipping this line."
            hasClip = false
        return unless hasClip

        if btn == "Wedge"
            data = wedge data, clip, res
        elseif btn == "Box"
            data = box data, clip, res
        elseif btn == "Ring"
            data = rings data, clip, res
        elseif btn == "Star"
            data = star data, clip, res
        data\commit!
    lines\replaceLines!


depctrl\registerMacro main
