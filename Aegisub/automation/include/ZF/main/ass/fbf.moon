import UTIL  from require "ZF.main.util.util"
import MATH  from require "ZF.main.util.math"
import TABLE from require "ZF.main.util.table"
import LAYER from require "ZF.main.ass.tags.layer"
import TAGS  from require "ZF.main.ass.tags.tags"

ffm = aegisub.frame_from_ms
mff = aegisub.ms_from_frame

class FBF

    version: "1.1.4"

    new: (l, start_time = l.start_time, end_time = l.end_time) =>
        assert mff(0), "video not loaded"
        -- copys line
        @line = TABLE(l)\copy!
        -- set line times
        @lstart = start_time
        @lend = end_time
        @ldur = end_time - start_time
        -- converts time values in milliseconds to frames
        @sframe = ffm start_time
        @eframe = ffm end_time
        soffset = mff @sframe
        eoffset = mff @sframe + 1
        @offset = math.floor (eoffset - soffset) / 2
        @dframe = @eframe - @sframe
        @s, @e, @d = 0, end_time, end_time - start_time
        -- gets the transformation "t" through a time interval
        getTimeInInterval = (t1, t2, accel = 1, t) ->
            u = @s + @offset - @lstart
            if u < t1
                t = 0
            elseif u >= t2
                t = 1
            else
                t = (u - t1) ^ accel / (t2 - t1) ^ accel
            return t
        -- libass functions
        @util = {
            -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L633
            transform: (...) ->
                args, t1, t2, accel = {...}, 0, @ldur, 1
                if #args == 3
                    {t1, t2, accel} = args
                elseif #args == 2
                    {t1, t2} = args
                elseif #args == 1
                    {accel} = args
                return getTimeInInterval t1, t2, accel

            -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L452
            move: (x1, y1, x2, y2, t1, t2) ->
                if t1 and t2
                    if t1 > t2
                        t1, t2 = t2, t1
                else
                    t1, t2 = 0, 0
                if t1 <= 0 and t2 <= 0
                    t1, t2 = 0, @ldur
                t = getTimeInInterval t1, t2
                x = MATH\round (1 - t) * x1 + t * x2, 3
                y = MATH\round (1 - t) * y1 + t * y2, 3
                return x, y

            -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L585
            fade: (dec, ...) ->
                -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L196
                interpolate_alpha = (now, t1, t2, t3, t4, a1, a2, a3, a = a3) ->
                    if now < t1
                        a = a1
                    elseif now < t2
                        cf = (now - t1) / (t2 - t1)
                        a = a1 * (1 - cf) + a2 * cf
                    elseif now < t3
                        a = a2
                    elseif now < t4
                        cf = (now - t3) / (t4 - t3)
                        a = a2 * (1 - cf) + a3 * cf
                    return a
                args, a1, a2, a3, t1, t2, t3, t4 = {...}
                if #args == 2
                    -- 2-argument version (\fad, according to specs)
                    a1 = 255
                    a2 = 0
                    a3 = 255
                    t1 = 0
                    {t2, t3} = args
                    t4 = @ldur
                    t3 = t4 - t3
                elseif #args == 7
                    -- 7-argument version (\fade)
                    {a1, a2, a3, t1, t2, t3, t4} = args
                else
                    return ""
                return ass_alpha interpolate_alpha @s + @offset - @lstart, t1, t2, t3, t4, a1, dec or a2, a3
        }

    -- gets frame duration
    frameDur: (dec = 0) =>
        msa, msb = mff(1), mff(101)
        return MATH\round msb and (msb - msa) / 100 or 41.708, dec

    -- adds the \move tag transformation
    insertMove: (layer, move) =>
        if move
            x, y = @util.move unpack move["value"]
            layer\remove {"move", "\\pos(#{x},#{y})"}

    -- adds the \fade tag transformation
    insertFade: (layer, fade) =>
        if fade
            value = layer\getTagValue("alpha") or "&H00&"
            value = value\match "%x%x"
            value = tonumber value, 16
            value = @util.fade value, unpack fade["value"]
            layer\remove {"fade", "\\alpha#{value}"}

    -- adds the \t tag transformation
    insertTransform: (layer, concat = "") =>
        while layer\contain "t"
            {:s, :e, :a, :transform} = layer\getTagValue "t"
            layer\animated "hide"
            for v in *LAYER(transform)\split!
                {:name, :value, :info} = v
                morph, id, p = {nil, value}, info["id"], nil
                if layer\contain name
                    morph[1] = layer\getTagValue name
                else
                    morph[1] = AssTagsPatterns[name]["value"]
                u = @util.transform s, e, a
                unless name == "clip" or name == "iclip"
                    p = UTIL\interpolation u, "auto", morph
                    if type(p) == "number"
                        MATH\round p
                else
                    assert morph[1], "Can't transform a \\clip into a \\iclip or vice versa"
                    -- if is a rectangular clip
                    if type(morph[1]) == "table" and type(morph[2]) == "table"
                        {l1, t1, r1, b1} = morph[1]
                        {l2, t2, r2, b2} = morph[2]
                        l = MATH\round UTIL\interpolation u, "number", l1, l2
                        t = MATH\round UTIL\interpolation u, "number", t1, t2
                        r = MATH\round UTIL\interpolation u, "number", r1, r2
                        b = MATH\round UTIL\interpolation u, "number", b1, b2
                        p = "(#{l},#{t},#{r},#{b})"
                    else
                        -- if is a vector clip --> yes it works
                        p = "(#{UTIL\interpolation u, "shape", morph})"
                concat ..= id .. p
            layer\animated "unhide"
            layer\remove {"t", concat, 1}

    -- initial setup for repair and getting \move and \fade tag values
    setup: (line) =>
        -- adds values to AssTagsPatterns
        for name, info in pairs AssTagsPatterns
            if style_name = info["style_name"]
                AssTagsPatterns[name]["value"] = line.styleref_old[style_name]
            else
                AssTagsPatterns[name]["value"] = AssTagsPatterns[name]["default_value"]
        -- initial tags setup
        tags = TAGS line.text
        tags\firstCategory!
        tags\insertPending false, false, true
        -- gets the first tag layer of the text and
        -- gets the fade and move values if they exist
        flyr = tags["layers_data"][1]
        move = flyr.getTagValue "move"
        fade = flyr.getTagValue "fade"
        return tags, move, fade

    -- performs all transformations on the frame
    perform: (line, tags, move, fade) =>
        __tags = TAGS tags
        layers = __tags["layers"]
        -- adds the \move tag transformation
        @insertMove layers[1], move
        -- iteration with all text layers
        for li, layer in ipairs layers
            -- adds the pending tags for a simultaneous check
            if li > 1
                layer\insertPending layers[li - 1]
            -- adds the \t tag transformation
            @insertTransform layer
            -- adds the \fad or \fade tag transformation
            @insertFade layer, fade
            -- makes a general cleaning in the layer
            layer\clear li > 1 and line.styleref or line.styleref_old
            -- removes equal tags present in different layers
            if li > 1
                layer\removeEquals layers[li - 1]
        result = __tags\__tostring!
        return result\gsub "{%s*}", ""

    -- fbf iteration
    iter: (step = 1) =>
        {:sframe, :eframe, :dframe} = @
        d = sframe - 1
        i = d
        ->
            i += step
            if i < eframe
                -- sets the start and end time of the frame in milliseconds
                @s = mff i - step == d and sframe or i
                @e = mff min i + step, eframe
                @d = @e - @s
                return @s, @e, @d, i - d, dframe

{:FBF}