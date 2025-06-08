import TABLE from require "ZF.main.util.table"
import LAYER from require "ZF.main.ass.tags.layer"

class DIALOG

    version: "1.0.0"

    new: (@subs, @selected, @active, @rem = false) =>
        -- i, j, last_selection_index, first_dialogue
        @i = {0, 0, @selected[#@selected], 0}
        @new_selection = {}
        for l, i in @iterSubtitle false
            if l["class"] == "dialogue"
                @i[4] = i
                break
        -- gets the video and style values
        @colletHead!

    -- iterates over all the selected lines of the subtitle
    -- @param copy bool
    -- @return function
    iterSelected: (copy = true, i = 0) =>
        n = #@selected
        ->
            i += 1
            if i <= n
                s = @selected[i]
                l = @subs[s + @i[1]]
                if copy
                    line = TABLE(l)\copy!
                    return l, line, s, i, n
                return l, s, i, n

    -- iterates over all the lines of the subtitle
    -- @param copy bool
    -- @return function
    iterSubtitle: (copy = true, i = 0) =>
        n = #@subs
        ->
            i += 1
            if i <= n
                l = @subs[i + @i[1]]
                if copy
                    line = TABLE(l)\copy!
                    return l, line, i, n
                return l, i, n

    -- gets the new selection of selected lines
    -- @return number, number
    getSelection: =>
        aegisub.set_undo_point script_name
        if #@new_selection > 0
            return @new_selection, @new_selection[1]

    -- adds a line in the subtitle
    -- @param line table
    -- @param s number
    insertLine: (line, s, j = s + @i[1] + 1) =>
        @i[1] += 1
        @i[2] += 1
        @subs.insert j, line
        TABLE(@new_selection)\push j

    -- removes the current subtitle line
    -- @param line table
    -- @param s number
    removeLine: (line, s, j = s + @i[1]) =>
        line.comment = true
        @subs[j] = line
        line.comment = false
        if @rem
            @i[1] -= 1
            @i[2] -= 1
            @subs.delete j

    -- collects the ass file header by adding the alpha values
    colletHead: =>
        @meta, @style = karaskel.collect_head @subs
        for i = 1, @style.n
            with @style[i]
                .alpha  = "&H00&"
                .alpha1 = alpha_from_style .color1
                .alpha2 = alpha_from_style .color2
                .alpha3 = alpha_from_style .color3
                .alpha4 = alpha_from_style .color4
                .color1 = color_from_style .color1
                .color2 = color_from_style .color2
                .color3 = color_from_style .color3
                .color4 = color_from_style .color4

    -- overwrites the style values according to the values contained in the first tag layer
    -- @param line table
    -- @param layers table
    -- @return table
    reStyle: (line, layer) =>
        flayer = LAYER(layer or line.text, false)\animated "hide"
        -- copies the style value
        copyStyle = TABLE(@style)\copy!
        newValues = {
            align:     flayer\getTagValue "an"
            fontname:  flayer\getTagValue "fn"
            fontsize:  flayer\getTagValue "fs"
            scale_x:   flayer\getTagValue "fscx"
            scale_y:   flayer\getTagValue "fscy"
            spacing:   flayer\getTagValue "fsp"
            outline:   flayer\getTagValue "bord"
            shadow:    flayer\getTagValue "shad"
            angle:     flayer\getTagValue "frz"
            alpha:     flayer\getTagValue "alpha"
            alpha1:    flayer\getTagValue "1a"
            alpha2:    flayer\getTagValue "2a"
            alpha3:    flayer\getTagValue "3a"
            alpha4:    flayer\getTagValue "4a"
            color1:    flayer\getTagValue "1c"
            color2:    flayer\getTagValue "2c"
            color3:    flayer\getTagValue "3c"
            color4:    flayer\getTagValue "4c"
            bold:      flayer\getTagValue "b"
            italic:    flayer\getTagValue "i"
            underline: flayer\getTagValue "u"
            strikeout: flayer\getTagValue "s"
        }
        if fs = newValues["fontsize"]
            newValues["fontsize"] = fs <= 0 and nil or fs
        {:margin_l, :margin_r, :margin_t, :margin_b, :text} = line
        for s, value in ipairs copyStyle
            for k, v in pairs newValues
                value[k] = v or value[k]
            value.margin_l = margin_l if margin_l > 0
            value.margin_r = margin_r if margin_r > 0
            value.margin_v = margin_t if margin_t > 0
            value.margin_v = margin_b if margin_b > 0
        flayer\animated "unhide"
        return copyStyle

    -- gets tags that form a perspective transformation
    -- @param line table
    -- @return table
    getPerspectiveTags: (line, layer, values = {}) =>
        flayer = LAYER(layer or line.text, false)\animated "hide"
        -- if you have style reference get the positioning value for margin and alignment
        if ref = line.styleref
            {:res_x, :res_y} = @meta
            {:align, :margin_l, :margin_r, :margin_v} = ref
            -- Axis-X
            x = switch align
                when 1, 4, 7 then margin_l
                when 2, 5, 8 then (res_x - margin_r + margin_l) / 2
                when 3, 6, 9 then res_x - margin_r
            -- Axis-Y
            y = switch align
                when 1, 2, 3 then res_y - margin_v
                when 4, 5, 6 then res_y / 2
                when 7, 8, 9 then margin_v
            values["pos"] = {x, y}
        with values
            .p   = flayer\getTagValue("p")   or "text"

            .frx = flayer\getTagValue("frx") or 0
            .fry = flayer\getTagValue("fry") or 0
            .fax = flayer\getTagValue("fax") or 0
            .fay = flayer\getTagValue("fay") or 0

            .xshad = flayer\getTagValue("xshad") or 0
            .yshad = flayer\getTagValue("yshad") or 0

            .pos = flayer\getTagValue("pos") or (.pos or {0, 0})
            if move = flayer\getTagValue "move"
                .pos = {move[1], move[2]}
                .move = move
            .org = flayer\getTagValue("org") or {.pos[1], .pos[2]}
        flayer\animated "unhide"
        return values

    -- gets the value of the current index
    -- @param s number
    -- @return number
    currentIndex: (s) => s + @i[1] - @i[2] - @i[4] + 1

    progressLine: (s) =>
        if s == "reset"
            aegisub.progress.set 0
            aegisub.progress.task ""
        else
            aegisub.progress.set 100 * s / @i[3]
            aegisub.progress.task "Processing Line: [ #{@currentIndex s} ]"

    warning: (s, msg = "") =>
        aegisub.debug.out 2, "———— [Warning] ➔ Line \"[ #{@currentIndex s} ]\" skipped\n"
        aegisub.debug.out 2, "—— [Cause] ➔ " .. msg .. "\n\n"

{:DIALOG}