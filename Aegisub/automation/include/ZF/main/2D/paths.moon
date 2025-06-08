import MATH    from require "ZF.main.util.math"
import TABLE   from require "ZF.main.util.table"
import POINT   from require "ZF.main.2D.point"
import SEGMENT from require "ZF.main.2D.segment"
import PATH    from require "ZF.main.2D.path"

class PATHS

    version: "1.1.3"

    -- @param ... PATHS || PATH
    new: (...) =>
        @paths = {}
        @push ...
        @setBoudingBox!

    -- converts the paths into a sequence of points
    -- @return table
    toPoints: (points = {}) =>
        for path in *@paths
            TABLE(points)\push path\toPoints!
        return points

    -- adds (paths or path) to paths
    push: (...) =>
        args = {...}
        if #args == 1 and rawget args[1], "paths"
            for path in *args[1].paths
                TABLE(@paths)\push PATH!
                for segment in *path
                    @paths[#@paths]\push segment
        elseif #args == 1 and rawget args[1], "path"
            TABLE(@paths)\push PATH!
            for segment in *args[1].path
                @paths[#@paths]\push segment
        return @

    -- copies the entire contents of the class
    -- @return PATHS
    copy: (copyPaths = true) =>
        new = PATHS!
        with new
            {l: .l, t: .t, r: .r, b: .b, w: .w, h: .h, c: .c, m: .m} = @
            if copyPaths
                for path in *@paths
                    new\push path
        return new

    -- opens all path
    -- @return PATHS
    open: =>
        for path in *@paths
            path\open!
        return @

    -- closes all path
    -- @return PATHS
    close: =>
        for path in *@paths
            path\close!
        return @

    -- finds the coordinates of the rectangle gives boundingBox
    -- @return PATHS
    setBoudingBox: =>
        @l, @t, @r, @b = math.huge, math.huge, -math.huge, -math.huge
        for path in *@paths
            l, t, r, b = path\boudingBox!
            @l, @t = min(@l, l), min(@t, t)
            @r, @b = max(@r, r), max(@b, b)
        @w = @r - @l
        @h = @b - @t
        @c = @l + @w / 2
        @m = @t + @h / 2
        return @

    -- gets the rectangle shape gives bounding box
    -- @return SHAPE
    getBoudingBoxAssDraw: =>
        {:l, :t, :r, :b} = @
        return ("m %s %s l %s %s %s %s %s %s ")\format l, t, r, t, r, b, l, b

    -- gets the bounding box values in sequence
    -- @return number
    unpackBoudingBox: => @l, @t, @r, @b

    -- transform all linear points into bezier points
    -- @return PATHS
    allCubic: =>
        for path in *@paths
            path\allCubic!
        return @

    -- runs through all points
    -- @param fn function
    -- @return PATHS
    filter: (fn = (x, y, p) -> x, y) =>
        for path in *@paths
            path\filter fn
        return @

    -- moves points
    -- @param px number
    -- @param py number
    -- @return PATHS
    move: (px = 0, py = 0) =>
        @filter (x, y) ->
            x += px
            y += py
            return x, y

    -- scales points
    -- @param sx number
    -- @param sy number
    -- @param inCenter boolean
    -- @return PATHS
    scale: (sx = 100, sy = 100, inCenter) =>
        sx /= 100
        sy /= 100
        {c: cx, m: cy} = @
        @filter (x, y) ->
            if inCenter
                x = sx * (x - cx) + cx
                y = sy * (y - cy) + cy
            else
                x *= sx
                y *= sy
            return x, y

    -- rotates points
    -- @param angle number
    -- @param cx number
    -- @param cy number
    -- @return PATHS
    rotate: (angle, cx = @c, cy = @m) =>
        theta = rad angle
        cs = cos theta
        sn = sin theta
        @filter (x, y) ->
            dx = x - cx
            dy = y - cy
            rx = cs * dx - sn * dy + cx
            ry = sn * dx + cs * dy + cy
            return rx, ry

    -- moves the points to their origin
    -- @return PATHS
    toOrigin: => @move -@l, -@t

    -- moves the points to their center
    -- @return PATHS
    toCenter: => @move -@l - @w / 2, -@t - @h / 2

    -- does a perspective transformation in the points
    -- @return PATHS
    perspective: (mesh, real, ep = 1e-2) =>
        mesh or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }

        real or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }

        {x: rx1, y: ry1} = real[1]
        {x: rx3, y: ry3} = real[3]
        {x: mx1, y: my1} = mesh[1]
        {x: mx2, y: my2} = mesh[2]
        {x: mx3, y: my3} = mesh[3]
        {x: mx4, y: my4} = mesh[4]

        mx3 += ep if mx2 == mx3
        mx4 += ep if mx1 == mx4
        mx2 += ep if mx1 == mx2
        mx3 += ep if mx4 == mx3

        a1 = (my2 - my3) / (mx2 - mx3)
        a2 = (my1 - my4) / (mx1 - mx4)
        a3 = (my1 - my2) / (mx1 - mx2)
        a4 = (my4 - my3) / (mx4 - mx3)

        a2 += ep if a1 == a2
        b1 = (a1 * mx2 - a2 * mx1 + my1 - my2) / (a1 - a2)
        b2 = a1 * (b1 - mx2) + my2

        a4 += ep if a3 == a4
        c1 = (a3 * mx2 - a4 * mx3 + my3 - my2) / (a3 - a4)
        c2 = a3 * (c1 - mx2) + my2

        c1 += ep if b1 == c1
        c3 = (b2 - c2) / (b1 - c1)

        a3 += ep if c3 == a3
        d1 = (c3 * mx4 - a3 * mx1 + my1 - my4) / (c3 - a3)
        d2 = c3 * (d1 - mx4) + my4

        a1 += ep if c3 == a1
        e1 = (c3 * mx4 - a1 * mx2 + my2 - my4) / (c3 - a1)
        e2 = c3 * (e1 - mx4) + my4
        @filter (x, y) ->
            f1 = (ry3 - y) / (ry3 - ry1)
            f2 = (x - rx1) / (rx3 - rx1)

            g1 = (d1 - mx4) * f1 + mx4
            g2 = (d2 - my4) * f1 + my4

            h1 = (e1 - mx4) * f2 + mx4
            h2 = (e2 - my4) * f2 + my4

            g1 += ep if c1 == g1
            h1 += ep if b1 == h1
            i1 = (c2 - g2) / (c1 - g1)
            i2 = (b2 - h2) / (b1 - h1)
            i2 += ep if i1 == i2

            px = (i1 * c1 - i2 * b1 + b2 - c2) / (i1 - i2)
            py = i1 * (px - g1) + g2
            return px, py

    -- does a envelope transformation in the points
    -- @return PATHS
    envelopeDistort: (mesh, real, ep = 1e-2) =>
        @allCubic!
        mesh or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }
        real or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }
        assert #real == #mesh, "The control points must have the same quantity!"
        for i = 1, #real
            with real[i]
                .x -= ep if .x == @l
                .y -= ep if .y == @t
                .x += ep if .x == @r
                .y += ep if .y == @b
            with mesh[i]
                .x -= ep if .x == @l
                .y -= ep if .y == @t
                .x += ep if .x == @r
                .y += ep if .y == @b
        A, W = {}, {}
        @filter (x, y, pt) ->
            -- Find Angles
            for i = 1, #real
                vi, vj = real[i], real[i % #real + 1]
                r0i = pt\distance vi
                r0j = pt\distance vj
                rij = vi\distance vj
                r = (r0i ^ 2 + r0j ^ 2 - rij ^ 2) / (2 * r0i * r0j)
                A[i] = r != r and 0 or acos max -1, min r, 1
            -- Find Weights
            for i = 1, #real
                j = (i > 1 and i or #real + 1) - 1
                r = real[i]\distance pt
                W[i] = (tan(A[j] / 2) + tan(A[i] / 2)) / r
            -- Normalise Weights
            Ws = TABLE(W)\reduce (a, b) -> a + b
            -- Reposition
            nx, ny = 0, 0
            for i = 1, #real
                L = W[i] / Ws
                with mesh[i]
                    nx += L * .x
                    ny += L * .y
            return nx, ny

    -- linearly flattens the path of the paths
    -- @param srt integer
    -- @param len integer
    -- @param red integer
    -- @param seg string
    -- @param fix boolean
    -- @return PATHS
    flatten: (srt, len, red, seg, fix) =>
        new = @copy!
        for i = 1, #@paths
            new.paths[i] = @paths[i]\flatten srt, len, red, seg, fix
        return new

    -- gets all lengths of the paths
    -- @return table
    getLengths: =>
        lengths = {sum: {}, max: 0}
        for i = 1, #@paths
            lengths[i] = @paths[i]\getLength!
            lengths.max += lengths[i].max
            lengths.sum[i] = lengths.max
        return lengths

    -- gets the total length of the paths
    -- @return number
    length: => @getLengths!["max"]

    -- splits the path into two
    -- @param t number
    -- @return table
    splitPath: (t) =>
        a = @splitPathInInterval 0, t
        b = @splitPathInInterval t, 1
        return {a, b}

    -- splits the path into an interval
    -- @param s number
    -- @param e number
    -- @return PATHS
    splitPathInInterval: (s, e) =>
        new = @copy false
        for i = 1, #@paths
            new.paths[i] = @paths[i]\splitInInterval s, e
        return new

    -- splits the paths into two
    -- @param t number
    -- @return table
    splitPaths: (t) =>
        a = @splitPathsInInterval 0, t
        b = @splitPathsInInterval t, 1
        return {a, b}

    -- splits the paths into an interval
    -- @param s number
    -- @param e number
    -- @return PATHS
    splitPathsInInterval: (s = 0, e = 1) =>
        -- clamps the time values between "0 ... 1"
        s = MATH\clamp s, 0, 1
        e = MATH\clamp e, 0, 1

        -- if the start value is greater than the end value, reverses the values
        s, e = e, s if s > e

        -- gets the required lengths
        lens = @getLengths!
        slen = s * lens.max
        elen = e * lens.max

        spt, inf, new = nil, nil, @copy false
        for i = 1, #lens.sum
            -- if the sum is less than the final value
            if lens.sum[i] >= elen
                -- gets the start index
                k = 1
                for i = 1, #lens.sum
                    if lens.sum[i] >= slen
                        k = i
                        break
                -- splits the initial part of the path
                val = @paths[k]
                u = (lens.sum[k] - slen) / val\length!
                u = 1 - u
                -- if the split is on a different path
                if i != k
                    spt = val\splitInInterval u, 1
                    new\push spt
                -- if not initial, add the parts that will not be damaged
                if i > 1
                    for j = k + 1, i - 1
                        TABLE(new.paths)\push @paths[j]
                -- splits the final part of the path
                val = @paths[i]
                t = (lens.sum[i] - elen) / val\length!
                t = 1 - t
                -- if the split is on a different path
                if i != k
                    spt = val\splitInInterval 0, t
                    new\push spt
                else
                    spt = val\splitInInterval u, t
                    new\push spt
                -- gets useful information
                inf = {:i, :k, :u, :t}
                break

        return new, inf

    -- gets the normal tangent of a time on the paths
    -- @param t number
    -- @param inverse boolean
    -- @return POINT, POINT, number
    getNormal: (t, inverse) =>
        new, inf = @splitPathsInInterval 0, t
        return @paths[inf.i]\getNormal inf.t, inverse

    -- rounds the corners of the paths
    -- @param radius number
    -- @return PATHS
    roundCorners: (radius) =>
        lengths = @getLengths!
        for i = 1, #@paths
            -- sorts so that the order is from the shortest length to the longest
            table.sort lengths[i], (a, b) -> a < b
            -- replaces the paths for paths with rounded corners 
            @paths[i] = @paths[i]\roundCorners radius, lengths[i][1] / 2
        return @

    -- concatenates all the points to assdraw format
    -- @param dec number
    -- @return string
    __tostring: (dec) =>
        concat = ""
        for path in *@paths
            concat ..= path\__tostring dec
        return concat

    -- same as __tostring
    build: (dec) => @__tostring dec

{:PATHS}