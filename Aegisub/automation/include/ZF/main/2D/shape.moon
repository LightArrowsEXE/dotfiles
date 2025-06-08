import PATHS   from require "ZF.main.2D.paths"
import PATH    from require "ZF.main.2D.path"
import SEGMENT from require "ZF.main.2D.segment"
import POINT   from require "ZF.main.2D.point"

class SHAPE extends PATHS

    version: "1.1.4"

    -- @param shape string || SHAPE
    -- @param close boolean
    new: (shape, close = true) =>
        -- checks if the value is a number, otherwise it returns an invalid error
        isNumber = (v) ->
            if v = tonumber v
                return v
            else
                error "unknown shape"

        @paths = {}
        if type(shape) == "string"
            -- indexes all values that are different from a space
            i, data = 1, [s for s in shape\gmatch "%S+"]
            while i <= #data
                switch data[i]
                    when "m"
                        -- creates a new path layer
                        @push PATH!
                        -- skip to the next letter
                        i += 2
                    when "l"
                        j = 1
                        while tonumber(data[i + j]) != nil
                            last = @paths[#@paths]
                            path, p0 = last.path, POINT!
                            if #path == 0 and data[i - 3] == "m"
                                p0.x = isNumber data[i - 2]
                                p0.y = isNumber data[i - 1]
                            else
                                segment = path[#path].segment
                                p0 = POINT segment[#segment]
                            -- creates the new line points and
                            -- checks if they are really a number
                            p1 = POINT!
                            p1.x = isNumber data[i + j + 0]
                            p1.y = isNumber data[i + j + 1]
                            -- adds the line to the path
                            last\push SEGMENT p0, p1
                            j += 2
                        -- skip to the next letter
                        i += j - 1
                    when "b"
                        j = 1
                        while tonumber(data[i + j]) != nil
                            last = @paths[#@paths]
                            path, p0 = last.path, POINT!
                            if #path == 0 and data[i - 3] == "m"
                                p0.x = isNumber data[i - 2]
                                p0.y = isNumber data[i - 1]
                            else
                                segment = path[#path].segment
                                p0 = POINT segment[#segment]
                            -- creates the new bezier points and
                            -- checks if they are really a number
                            p1, p2, p3 = POINT!, POINT!, POINT!
                            p1.x = isNumber data[i + j + 0]
                            p1.y = isNumber data[i + j + 1]
                            p2.x = isNumber data[i + j + 2]
                            p2.y = isNumber data[i + j + 3]
                            p3.x = isNumber data[i + j + 4]
                            p3.y = isNumber data[i + j + 5]
                            -- adds the bezier to the path
                            last\push SEGMENT p0, p1, p2, p3
                            j += 6
                        -- skip to the next letter
                        i += j - 1
                    else -- if the (command | letter) is other than "m", "l" and "b", that shape is unknown
                        error "unknown shape"
                i += 1
        elseif type(shape) == "table" and rawget shape, "paths"
            for key, value in pairs shape\copy!
                @[key] = value

        -- removes invalid path
        i = 1
        while i <= #@paths
            path = @paths[i].path
            if #path == 0
                table.remove @paths, i
                i -= 1
            i += 1

        -- checks whether to close or open the shape
        if close == true or close == "close"
            @close!
        elseif close == "open"
            @open!

        -- sets the bounding box
        @setBoudingBox!

    -- sets the position the paths will be
    -- @param an integer
    -- @param mode string
    -- @param px number
    -- @param py number
    -- @return SHAPE
    setPosition: (an = 7, mode = "tcp", px = 0, py = 0) =>
        {:w, :h} = @
        switch an
            when 1
                switch mode
                    when "tcp" then @move px, py - h
                    when "ucp" then @move -px, -py + h
            when 2
                switch mode
                    when "tcp" then @move px - w / 2, py - h
                    when "ucp" then @move -px + w / 2, -py + h
            when 3
                switch mode
                    when "tcp" then @move px - w, py - h
                    when "ucp" then @move -px + w, -py + h
            when 4
                switch mode
                    when "tcp" then @move px, py - h / 2
                    when "ucp" then @move -px, -py + h / 2
            when 5
                switch mode
                    when "tcp" then @move px - w / 2, py - h / 2
                    when "ucp" then @move -px + w / 2, -py + h / 2
            when 6
                switch mode
                    when "tcp" then @move px - w, py - h / 2
                    when "ucp" then @move -px + w, -py + h / 2
            when 7
                switch mode
                    when "tcp" then @move px, py
                    when "ucp" then @move -px, -py
            when 8
                switch mode
                    when "tcp" then @move px - w / 2, py
                    when "ucp" then @move -px + w / 2, -py
            when 9
                switch mode
                    when "tcp" then @move px - w, py
                    when "ucp" then @move -px + w, -py
        return @

    -- transforms the points from perspective tags [fax, fay...]
    -- https://github.com/Alendt/Aegisub-Scripts/blob/0e897aeaab4eb11855cd1d83474616ef06307268/macros/alen.Shapery.moon#L3787
    -- @param line table
    -- @param data table
    -- @return SHAPE
    expand: (line, data) =>
        pf = (sx = 100, sy = 100, p = 1) ->
            assert p > 0 and p == floor p
            if p == 1
                sx / 100, sy / 100
            else
                p -= 1
                sx /= 2
                sy /= 2
                pf sx, sy, p
        with data
            p = .p == "text" and 1 or .p

            frx = pi / 180 * .frx
            fry = pi / 180 * .fry
            frz = pi / 180 * line.styleref.angle

            sx, cx = -sin(frx), cos(frx)
            sy, cy =  sin(fry), cos(fry)
            sz, cz = -sin(frz), cos(frz)

            xscale, yscale = pf line.styleref.scale_x, line.styleref.scale_y, p

            fax = .fax * xscale / yscale
            fay = .fay * yscale / xscale

            wx = line.styleref.shadow
            wy = line.styleref.shadow
            if data.xshad != 0 and data.yshad == 0
                wx = data.xshad
            elseif data.xshad == 0 and data.yshad != 0
                wy = data.yshad
            elseif data.xshad != 0 and data.yshad != 0
                wx = data.xshad
                wy = data.yshad

            ascent = 0
            switch line.styleref.align
                when 1, 2, 3
                    ascent = .p == "text" and line.height or @h
                when 4, 5, 6
                    ascent = (.p == "text" and line.height or @h) / 2

            x1 = {1, fax, .pos[1] - .org[1] + wx + fax * ascent}
            y1 = {fay, 1, .pos[2] - .org[2] + wy}

            x2, y2 = {}, {}
            for i = 1, 3
                x2[i] = x1[i] * cz - y1[i] * sz
                y2[i] = x1[i] * sz + y1[i] * cz

            y3, z3 = {}, {}
            for i = 1, 3
                y3[i] = y2[i] * cx
                z3[i] = y2[i] * sx

            x4, z4 = {}, {}
            for i = 1, 3
                x4[i] = x2[i] * cy - z3[i] * sy
                z4[i] = x2[i] * sy + z3[i] * cy

            dist = 312.5
            z4[3] += dist

            offs_x = .org[1] - .pos[1] - wx
            offs_y = .org[2] - .pos[2] - wy

            matrix = [{} for i = 1, 3]
            for i = 1, 3
                matrix[1][i] = z4[i] * offs_x + x4[i] * dist
                matrix[2][i] = z4[i] * offs_y + y3[i] * dist
                matrix[3][i] = z4[i]

            @filter (x, y) ->
                v = [(matrix[m][1] * x * xscale) + (matrix[m][2] * y * yscale) + matrix[m][3] for m = 1, 3]
                w = 1 / max v[3], 0.1
                return v[1] * w, v[2] * w
        return @

    -- distorts a shape into a clip
    -- http://www.planetclegg.com/projects/WarpingTextToSplines.html
    -- @param an integer
    -- @param clip string || SHAPE
    -- @param mode string
    -- @param leng integer
    -- @param offset number
    -- @return SHAPE
    inClip: (an = 7, clip, mode = "left", leng, offset = 0) =>
        mode = mode\lower!

        @toOrigin!
        if type(clip) != "table"
            clip = SHAPE clip, false
        leng or= clip\length!
        size = leng - @w

        @ = @flatten nil, nil, 2
        @filter (x, y) ->
            y = switch an
                when 7, 8, 9 then y - @h
                when 4, 5, 6 then y - @h / 2
                -- when 1, 2, 3 then y
            x = switch mode
                when 1, "left"   then x + offset
                when 2, "center" then x + offset + size / 2
                when 3, "right"  then x - offset + size
            -- gets normal tangent
            tan, pnt, t = clip\getNormal x / leng, true
            -- reescale tangent
            tan.x = pnt.x + y * tan.x
            tan.y = pnt.y + y * tan.y
            return tan
        return @

{:SHAPE}