import SHAPE from require "ZF.main.2D.shape"
import MATH  from require "ZF.main.util.math"
import TABLE from require "ZF.main.util.table"
import UTIL  from require "ZF.main.util.util"
import TAGS  from require "ZF.main.ass.tags.tags"
import FONT  from require "ZF.main.ass.font"

class LINE

    version: "1.4.0"

    new: (@line, @text, @text_stripped, @tags) =>
        @text or= @line.text
        @text_stripped or= @line.text_stripped
        @tags or= TAGS @text

    -- extends line information
    -- @param dialog DIALOG
    -- @return LINE
    prepoc: (dialog) =>
        {:line, :tags, :text} = @
        {:res_x, :res_y, :video_x_correct_factor} = dialog["meta"]

        line.tags = line.tags and line.tags or tags.layers[1]["layer"]
        line.text_stripped = text\gsub("%b{}", "")\gsub("\\h", " ")
        line.duration = line.end_time - line.start_time

        -- sets values found in the first tag layer as style defaults
        new_style = dialog\reStyle line

        -- sets style references
        if style = new_style[line.style]
            line.styleref = style
        else
            aegisub.debug.out 2, "WARNING: Style not found: #{line.style}\n"
            line.styleref = new_style[1]

        -- sets style references
        if style = dialog.style[line.style]
            line.styleref_old = style
        else
            aegisub.debug.out 2, "WARNING: Style not found: #{line.style}\n"
            line.styleref_old = new_style[1]

        -- gets align
        align = line.styleref.align

        -- adds the metric values to the line
        line.width, line.height, line.descent, line.extlead = aegisub.text_extents line.styleref, line.text_stripped
        line.space_width = aegisub.text_extents line.styleref, " "

        -- fixes the width value
        line.width *= video_x_correct_factor
        line.space_width *= video_x_correct_factor

        -- effective margins
        line.margin_v = line.margin_t
        line.eff_margin_l = line.margin_l > 0 and line.margin_l or line.styleref.margin_l
        line.eff_margin_r = line.margin_r > 0 and line.margin_r or line.styleref.margin_r
        line.eff_margin_t = line.margin_t > 0 and line.margin_t or line.styleref.margin_t
        line.eff_margin_b = line.margin_b > 0 and line.margin_b or line.styleref.margin_b
        line.eff_margin_v = line.margin_v > 0 and line.margin_v or line.styleref.margin_v

        switch align
            when 1, 4, 7
                -- Left aligned
                line.left = line.eff_margin_l
                line.center = line.left + line.width / 2
                line.right = line.left + line.width
                line.x = line.left
            when 2, 5, 8
                -- Centered aligned
                line.left = (res_x - line.eff_margin_l - line.eff_margin_r - line.width) / 2 + line.eff_margin_l
                line.center = line.left + line.width / 2
                line.right = line.left + line.width
                line.x = line.center
            when 3, 6, 9
                -- Right aligned
                line.left = res_x - line.eff_margin_r - line.width
                line.center = line.left + line.width / 2
                line.right = line.left + line.width
                line.x = line.right

        switch align
            when 7, 8, 9
                -- Top aligned
                line.top = line.eff_margin_t
                line.middle = line.top + line.height / 2
                line.bottom = line.top + line.height
                line.y = line.top
            when 4, 5, 6
                -- Mid aligned
                line.top = (res_y - line.eff_margin_t - line.eff_margin_b - line.height) / 2 + line.eff_margin_t
                line.middle = line.top + line.height / 2
                line.bottom = line.top + line.height
                line.y = line.middle
            when 1, 2, 3
                -- Bottom aligned
                line.bottom = res_y - line.eff_margin_b
                line.middle = line.bottom - line.height / 2
                line.top = line.bottom - line.height
                line.y = line.bottom

        return @

    -- converts each layer to a new line
    -- @param dialog DIALOG
    -- @param noblank bool
    -- @return table
    tags2Lines: (dialog, noblank = true) =>
        {:line, :tags} = @

        unless line.styleref
            @prepoc dialog

        {:res_x, :res_y} = dialog["meta"]
        {:layers, :between} = @tags

        temp = {n: #layers, text: "", left: 0, width: 0, height: 0, offsety: 0, breaky: 0}
        for i = 1, temp.n
            tag_layer = layers[i]["layer"]
            txt_layer = between[i]

            -- removes hard spaces
            txt_layer = txt_layer\gsub "\\h", " "

            -- copies the table to new settings
            l = TABLE(line)\copy!
            l.isTags = true

            -- number of blanks at the beginning and the end
            l.prevspace = @tags\blank(txt_layer, "spaceL")\len!
            l.postspace = @tags\blank(txt_layer, "spaceR")\len!

            -- removes the blanks from the beginning and the end
            txt_layer = @tags\blank txt_layer

            -- sets text and tags values
            l.text = tag_layer .. txt_layer
            l.tags = tag_layer
            l.text_stripped = txt_layer

            -- sets preprocline
            LINE(l)\prepoc dialog
            align, offsety = l.styleref.align

            -- calculates the value of the previous blank
            prevspace = l.prevspace * l.space_width
            temp.left += prevspace

            switch align
                when 1, 4, 7
                    -- Left aligned
                    l.offsetx = 0
                    l.left = temp.left + l.eff_margin_l
                    l.center = l.left + l.width / 2
                    l.right = l.left + l.width
                when 2, 5, 8
                    -- Centered aligned
                    l.offsetx = (res_x - l.eff_margin_l - l.eff_margin_r) / 2 + l.eff_margin_l
                    l.left = temp.left
                    l.center = l.left + l.width / 2
                    l.right = l.left + l.width
                when 3, 6, 9
                    -- Right aligned
                    l.offsetx = res_x - l.eff_margin_r
                	l.left = temp.left
                    l.center = l.left + l.width / 2
                    l.right = l.left + l.width

            switch align
                when 7, 8, 9
                    -- Top aligned
                    l.offsety = 0.5 - l.descent + l.height
                    l.top = l.eff_margin_t
                    l.middle = l.top + l.height / 2
                    l.bottom = l.top + l.height
                when 4, 5, 6
                    -- Mid aligned
                    l.offsety = 0.5 - l.descent + l.height / 2
                    l.top = (res_y - l.eff_margin_t - l.eff_margin_b - l.height) / 2 + l.eff_margin_t
                    l.middle = l.top + l.height / 2
                    l.bottom = l.top + l.height
                when 1, 2, 3
                    -- Bottom aligned
                    l.offsety = 0.5 - l.descent
                    l.bottom = res_y - l.eff_margin_b
                    l.middle = l.bottom - l.height / 2
                    l.top = l.bottom - l.height

            -- calculates the value of the next blank
            postspace = l.postspace * l.space_width
            temp.left += l.width + postspace

            -- adds the text from tag
            temp.text ..= l.text_stripped

            -- recalculates the metrics of the fonts according to the largest one for the respective settings
            temp.width  += l.width + prevspace + postspace
            temp.height  = math.max temp.height, l.height
            temp.descent = not temp.descent and l.descent or math.max temp.descent, l.descent
            temp.extlead = not temp.extlead and l.extlead or math.max temp.extlead, l.extlead
            temp.breaky  = math.max temp.breaky, l.styleref.fontsize * l.styleref.scale_y / 100

            -- recalculates the value of the height difference to obtain the optimal value for the positioning return
            temp.offsety = align > 3 and math.max(temp.offsety, l.offsety) or math.min(temp.offsety, l.offsety)
            temp[i] = l

        {:n, :text, :offsety, :width, :height, :offsety, :breaky} = temp
        data = {n: 0, :text, :offsety, :width, :height, :offsety, :breaky}
        for i = 1, n
            l = temp[i]

            -- fixes the problem regarding text width in different tag layers
            switch l.styleref.align
                when 1, 4, 7
                    l.x = l.left
                when 2, 5, 8
                    l.offsetx -= width / 2
                    l.center += l.offsetx
                    l.x = l.center
                when 3, 6, 9
                    l.offsetx -= width
                    l.right += l.offsetx
                    l.x = l.right

            -- fixes the problem regarding text height in different tag layers
            l.offsety = offsety - l.offsety
            switch l.styleref.align
                when 7, 8, 9
                    l.top += l.offsety
                    l.y = l.top
                when 4, 5, 6
                    l.middle += l.offsety
                    l.y = l.middle
                when 1, 2, 3
                    l.bottom += l.offsety
                    l.y = l.bottom

            -- add only when it is not a blank
            if noblank and l.text_stripped != ""
                data.n += 1
                data[data.n] = l

        return data

    -- converts each line break to a new line
    -- @param dialog DIALOG
    -- @param noblank bool
    -- @return table
    breaks2Lines: (dialog, noblank = true) =>
        {:line, :tags} = @

        split = tags\breaks!
        slen, data, add = #split, {n: 0}, {n: {sum: 0}, r: {sum: 0}}

        -- gets the tag data values for each line break
        temp = [LINE(line, split[i])\tags2Lines dialog, noblank for i = 1, slen]

        -- gets the offset for each line break
        for i = 1, slen
            j = slen - i + 1
            -- adds normal
            {:text, :breaky} = temp[i]
            add.n[i] = add.n.sum
            add.n.sum += text == "" and breaky / 2 or breaky
            -- adds reverse
            {:text, :breaky} = temp[j]
            add.r[j] = add.r.sum
            add.r.sum += text == "" and breaky / 2 or breaky

        -- repositions the Y-axis on the tag data
        for i = 1, slen
            brk = temp[i]
            for j = 1, brk.n
                tag = brk[j]
                tag.y = switch line.styleref.align
                    when 7, 8, 9 then tag.y + add.n[i]
                    when 4, 5, 6 then tag.y + (add.n[i] - add.r[i]) / 2
                    when 1, 2, 3 then tag.y - add.r[i]

            -- add only when it is not a blank
            if noblank and brk.text != ""
                data.n += 1
                data[data.n] = brk

        return data

    -- gets values for all characters contained in the text
    -- @param noblank bool
    -- @return table
    chars: (noblank = true) =>
        {:line, :text_stripped} = @
        {:tags, :styleref, :start_time, :end_time, :duration, :isTags} = line
        chars, left, align = {n: 0}, line.left, styleref.align
        for c, char in Yutils.utf8.chars text_stripped
            text = char
            text_stripped = char

            width, height, descent, extlead = aegisub.text_extents styleref, text_stripped
            center                          = left + width / 2
            right                           = left + width
            top                             = line.top
            middle                          = line.middle
            bottom                          = line.bottom

            addx = isTags and line.offsetx or 0
            x = switch align
                when 1, 4, 7 then left
                when 2, 5, 8 then center + addx
                when 3, 6, 9 then right + addx

            addy = isTags and line.y or nil
            y = switch align
                when 7, 8, 9 then addy or top
                when 4, 5, 6 then addy or middle
                when 1, 2, 3 then addy or bottom

            unless noblank and UTIL\isBlank text_stripped
                chars.n += 1
                chars[chars.n] = {
                    i: chars.n
                    :text, :tags, :text_stripped
                    :width, :height, :descent, :extlead
                    :center, :left, :right, :top, :middle, :bottom, :x, :y
                    :start_time, :end_time, :duration
                }

            left += width
        return chars

    -- gets values for all words contained in the text
    -- @param noblank bool
    -- @return table
    words: (noblank = true) =>
        {:line, :text_stripped} = @
        {:tags, :styleref, :space_width, :start_time, :end_time, :duration, :isTags} = line
        words, left, align = {n: 0}, line.left, styleref.align
        for prevspace, word, postspace in line.text_stripped\gmatch "(%s*)(%S+)(%s*)"
            text = word
            text_stripped = word

            prevspace                       = prevspace\len!
            postspace                       = postspace\len!

            width, height, descent, extlead = aegisub.text_extents styleref, text_stripped
            left                           += prevspace * space_width
            center                          = left + width / 2
            right                           = left + width
            top                             = line.top
            middle                          = line.middle
            bottom                          = line.bottom

            addx = isTags and line.offsetx or 0
            x = switch align
                when 1, 4, 7 then left
                when 2, 5, 8 then center + addx
                when 3, 6, 9 then right + addx

            addy = isTags and line.y or nil
            y = switch align
                when 7, 8, 9 then addy or top
                when 4, 5, 6 then addy or middle
                when 1, 2, 3 then addy or bottom

            unless noblank and UTIL\isBlank text_stripped
                words.n += 1
                words[words.n] = {
                    i: words.n
                    :text, :tags, :text_stripped
                    :width, :height, :descent, :extlead
                    :center, :left, :right, :top, :middle, :bottom, :x, :y
                    :start_time, :end_time, :duration
                }

            left += width + postspace * space_width
        return words

    -- reallocates the positioning values from the information in an index
    -- @param index table
    -- @param coords table
    -- @return table, table
    reallocate: (index, coords) =>
        {:line} = @
        local vx, vy, x1, y1, x2, y2, isMove
        with coords
            vx, vy, isMove = if .move then .move[1], .move[2], true else .pos[1], .pos[2]
        x1 = MATH\round index.x - line.x + vx
        y1 = MATH\round index.y - line.y + vy
        pos = {x1, y1}
        if isMove
            x2 = MATH\round index.x - line.x + coords.move[3]
            y2 = MATH\round index.y - line.y + coords.move[4]
            pos = {x1, y1, x2, y2, coords.move[5], coords.move[6]}
        return pos, (index.tags\match("\\fr[xyz]*[%-%.%d]*") or line.styleref.angle != 0) and coords.org or nil

    -- converts the text into a shape and relocates its position
    -- @param dialog DIALOG
    -- @param align number
    -- @param px number
    -- @param py number
    -- @return string, string
    toShape: (dialog, align = @line.styleref.align, px = 0, py = 0) =>
        {:left, :center, :right, :top, :middle, :bottom} = @line
        clip, breaks = "", @breaks2Lines dialog
        for b, brk in ipairs breaks
            for t, tag in ipairs brk
                font = FONT tag.styleref
                {:shape, :width, :height} = font\get tag.text_stripped
                shape = SHAPE shape
                temp = switch align
                    when 1, 4, 7 then shape\move px + tag.x - left
                    when 2, 5, 8 then shape\move px + tag.x - center - width / 2
                    when 3, 6, 9 then shape\move px + tag.x - right - width
                temp = switch align
                    when 7, 8, 9 then temp\move 0, py + tag.y - top
                    when 4, 5, 6 then temp\move 0, py + tag.y - middle - height / 2
                    when 1, 2, 3 then temp\move 0, py + tag.y - bottom - height
                clip ..= temp\build!
        shape = SHAPE(clip)\setPosition(align, "ucp", px, py)\build!
        return shape, clip

{:LINE}