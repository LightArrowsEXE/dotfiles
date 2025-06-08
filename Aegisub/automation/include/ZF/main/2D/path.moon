local *
import POINT   from require "ZF.main.2D.point"
import SEGMENT from require "ZF.main.2D.segment"
import MATH    from require "ZF.main.util.math"
import TABLE   from require "ZF.main.util.table"
import UTIL    from require "ZF.main.util.util"

class PATH

    version: "1.1.0"

    -- @param ... PATH || SEGMENT
    new: (...) =>
        @path = {}
        @push ...

    -- converts the path into a sequence of points
    -- @return table
    toPoints: (points = {}) =>
        {:path} = @
        points = {path[1]\unpack!}
        for j = 2, #path - 1
            TABLE(points)\push path[j]["segment"][2]
        return points

    -- adds points to the path
    -- @return PATH
    push: (...) =>
        args = {...}
        if #args == 1 and rawget args[1], "path"
            for segment in args[i].path
                TABLE(@path)\push SEGMENT!
                for point in *segment
                    @path[#@path]\push point
        elseif #args == 1 and rawget args[1], "segment"
            TABLE(@path)\push SEGMENT!
            for point in *args[1].segment
                @path[#@path]\push point
        return @

    -- checks if the path is closed
    -- @return boolean
    isClosed: => @path[1]["segment"][1] == @path[#@path]["segment"][#@path[#@path]["segment"]]

    -- checks if the path is open
    -- @return boolean
    isOpen: => not @isClosed!

    -- closes the path
    -- @return PATH
    close: =>
        {x: fx, y: fy} = @path[1]["segment"][1]
        {x: lx, y: ly} = @path[#@path]["segment"][#@path[#@path]["segment"]]
        unless @isClosed!
            TABLE(@path)\push SEGMENT POINT(lx, ly), POINT(fx, fy)
        return @

    -- opens the path
    -- @return PATH
    open: =>
        unless @isOpen!
            TABLE(@path)\pop!
        return @

    -- gets the path bounding box
    -- @param typer string
    -- @return number, number, number, number
    boudingBox: (typer) =>
        l, t, r, b = math.huge, math.huge, -math.huge, -math.huge
        for segment in *@path
            minx, miny, maxx, maxy = segment\boudingBox typer
            l, t = min(l, minx), min(t, miny)
            r, b = max(r, maxx), max(b, maxy)
        return l, t, r, b

    -- transforms all line segments into bezier segments
    -- @return PATH
    allCubic: =>
        for i = 1, #@path
            @path[i] = @path[i]\allCubic!
        return @

    -- gets all path lengths
    -- @return table
    getLength: =>
        length = {sum: {}, max: 0}
        for b, bezier in ipairs @path
            length[b] = bezier\length!
            length.max += length[b]
            length.sum[b] = length.max
        return length

    -- gets the max length of the path
    -- @return number
    length: => @getLength!["max"]

    -- runs through all points of the path
    -- @param fn function
    -- @return PATH
    filter: (fn = (x, y, p) -> x, y) =>
        for p, path in ipairs @path
            for b, pt in ipairs path.segment
                with pt
                    {:x, :y} = pt
                    px, py = fn x, y, pt
                    if type(px) == "table" and UTIL\getClassName(px) == "POINT"
                        {x: .x, y: .y} = px
                    else
                        .x, .y = px or x, py or y
        return @

    -- flattens segments specifically
    -- @param srt integer
    -- @param len integer
    -- @param red integer
    -- @param seg string
    -- @param fix boolean
    -- @return PATH
    flatten: (srt, len, red, seg = "m", fix) =>
        new = PATH!
        for segment in *@path
            tp = segment.segment.t
            if tp == (seg == "m" and tp or seg)
                flatten = segment\casteljau srt, len, red, fix
                for i = 2, #flatten
                    prev = flatten[i - 1]
                    curr = flatten[i - 0]
                    new\push SEGMENT prev, curr
            else
                new\push SEGMENT segment\unpack!
        return new

    -- rounds the corners of the path
    -- @param radius number
    -- @param limit number
    -- @return PATH
    roundCorners: (radius, limit) =>
        -- conditions to see if it can be a corner
        isCorner = (ct, nt, lt) -> -- curr, next and last t
            if ct == "b"
                return false
            elseif ct == "l" and nt == "b"
                return false
            elseif lt == "b"
                return false
            return true

        new, r = PATH!, limit < radius and limit or radius
        for i = 1, #@path
            currPath = @path[i]
            nextPath = @path[i == #@path and 1 or i + 1]

            if isCorner currPath.segment.t, nextPath.segment.t, @path[#@path].segment.t
                prevPoint = currPath.segment[1]
                currPoint = currPath.segment[2]
                nextPoint = nextPath.segment[2]

                F = SEGMENT currPoint, prevPoint
                L = SEGMENT currPoint, nextPoint

                angleF = F\linearAngle!
                angleL = L\linearAngle!
                {x: px, y: py} = currPoint

                -- creating the bezier segment
                p1 = POINT px + r * cos(angleF), py + r * sin(angleF)
                p4 = POINT px + r * cos(angleL), py + r * sin(angleL)
                c1 = POINT (p1.x + 2 * px) / 3, (p1.y + 2 * py) / 3
                c2 = POINT (p4.x + 2 * px) / 3, (p4.y + 2 * py) / 3

                new\push SEGMENT currPoint, p1 if i > 1
                new\push SEGMENT p1, c1, c2, p4
            else
                new\push currPath

        return new

    -- splits the path into two parts
    -- @param t number
    -- @return table
    split: (t = 0.5) =>
        a = @splitInInterval 0, t
        b = @splitInInterval t, 1
        return {a, b}

    -- splits the path in a time interval
    -- @param s number
    -- @param e number
    -- @return PATH, table
    splitInInterval: (s = 0, e = 1) =>
        -- clamps the time values between "0 ... 1"
        s = MATH\clamp s, 0, 1
        e = MATH\clamp e, 0, 1

        -- if the start value is greater than the end value, reverses the values
        s, e = e, s if s > e

        -- gets the required lengths
        lens = @getLength!
        slen = s * lens.max
        elen = e * lens.max

        new, inf, sum = PATH!, {}, 0
        for i = 1, #lens.sum
            -- if the sum is less than the final value
            if lens.sum[i] >= elen
                -- gets the start index
                k = 1
                for i = 1, #lens
                    if lens.sum[i] >= slen
                        k = i
                        break
                -- splits the initial part of the path
                val = @path[k]
                u = (lens.sum[k] - slen) / val\length!
                u = 1 - u
                -- if the split is on a different path
                if i != k
                    new\push val\split(u)[2]
                -- if not initial, add the parts that will not be damaged
                if i > 1
                    for j = k + 1, i - 1
                        new\push @path[j]
                -- splits the final part of the path
                val = @path[i]
                t = (lens.sum[i] - elen) / val\length!
                t = 1 - t
                -- if the split is on a different path
                if i != k
                    new\push val\split(t)[1]
                else
                    new\push val\splitInInterval u, t
                -- gets useful information
                inf = {:i, :k, :u, :t}
                break

        return new, inf

    -- gets the normalized tangent of time
    -- @param t number
    -- @param inverse boolean
    -- @return POINT, POINT, number
    getNormal: (t, inverse) =>
        new, inf = @splitInInterval 0, t
        return @path[inf.i]\getNormal inf.t, inverse

    -- simplifies path points
    -- @param simplifyType string
    -- @param precision number
    -- @param limit number
    -- @return PATH
    simplify: (simplifyType = "linear", precision, limit = 3) =>
        newPath = PATH!
        -- calls the SIMPLIFY class
        if simplifyType == "line" or simplifyType == "linear"
            points = {}
            -- adds the path structure in a single table
            {a, b} = @path[1].segment
            TABLE(points)\push a, b
            for i = 2, #@path
                TABLE(points)\push @path[i].segment[2]
            -- simplifies all segments
            points = SIMPLIFY(points, precision)\spLines!
            -- re-adds it back to the path structure
            for i = 2, #points
                pointPrev = points[i - 1]
                pointCurr = points[i - 0]
                newPath\push SEGMENT pointPrev, pointCurr
        else
            i, lens, groups = 1, @getLength!, {}
            while i <= #lens
                if lens[i] <= limit
                    temp = {}
                    TABLE(groups)\push {simplify: true}
                    -- repeat ... until --> not lens[i] or lens[i] > limit
                    while true
                        TABLE(temp)\push @path[i]
                        i += 1
                        break if not lens[i] or lens[i] > limit
                    -- path to points
                    {a, b} = temp[1].segment
                    TABLE(groups[#groups])\push a, b
                    for j = 2, #temp
                        TABLE(groups[#groups])\push temp[j].segment[2]
                    TABLE(groups)\push {@path[i]} if @path[i]
                else
                    TABLE(groups)\push {} if #groups == 0
                    TABLE(groups[#groups])\push @path[i] if @path[i]
                i += 1
            -- if it can be simplified, simplify, if not just add
            for spt in *groups
                spt = spt.simplify and SIMPLIFY(spt, precision)\spLines2Bezier! or spt
                [newPath\push smp for smp in *spt]
        return newPath

    -- concatenates all points to ass shape
    -- @param dec number
    -- @return string
    __tostring: (dec = 3) =>
        conc, last = "", ""
        for p, path in ipairs @path
            tp = path.segment.t
            path\round dec
            if p == 1
                conc ..= "m " .. path\__tostring 1
            conc ..= (tp == last and "" or tp .. " ") .. path\__tostring!
            last = tp
        return conc

-- https://github.com/ynakajima/polyline2bezier
-- https://github.com/mourner/simplify-js
class SIMPLIFY

    new: (points, tolerance = 1, highestQuality = true) =>
        @pts = points
        @tol = tolerance / 10
        @hqy = highestQuality
        @bld = {}

    push: (curve) => TABLE(@bld)\push SEGMENT curve[1], curve[2], curve[3], curve[4]

    computeLeftTangent: (d, _end) =>
        tHat1 = d[_end + 1] - d[_end]
        return tHat1\vecNormalize!

    computeRightTangent: (d, _end) =>
        tHat2 = d[_end - 1] - d[_end]
        return tHat2\vecNormalize!

    computeCenterTangent: (d, center) =>
        V1 = d[center - 1] - d[center]
        V2 = d[center] - d[center + 1]
        tHatCenter = POINT!
        tHatCenter.x = (V1.x + V2.x) / 2
        tHatCenter.y = (V1.y + V2.y) / 2
        return tHatCenter\vecNormalize!

    chordLengthParameterize: (d, first, last) =>
        u = {0}
        for i = first + 1, last
            u[i - first + 1] = u[i - first] + d[i]\distance d[i - 1]
        for i = first + 1, last
            u[i - first + 1] /= u[last - first + 1]
        return u

    bezierII: (degree, V, t) =>
        Vtemp = {}
        for i = 0, degree
            Vtemp[i] = POINT V[i + 1].x, V[i + 1].y

        for i = 1, degree
            for j = 0, degree - i
                Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
                Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y

        return POINT Vtemp[0].x, Vtemp[0].y

    computeMaxError: (d, first, last, bezCurve, u, splitPoint) =>
        splitPoint = (last - first + 1) / 2

        maxError = 0
        for i = first + 1, last - 1
            P = @bezierII 3, bezCurve, u[i - first + 1]
            v = P - d[i]
            dist = v\vecDistance!
            if dist >= maxError
                maxError = dist
                splitPoint = i

        return {:maxError, :splitPoint}

    newtonRaphsonRootFind: (_Q, _P, u) =>
        Q1, Q2 = {}, {}

        Q = {
            POINT _Q[1].x, _Q[1].y
            POINT _Q[2].x, _Q[2].y
            POINT _Q[3].x, _Q[3].y
            POINT _Q[4].x, _Q[4].y
        }
    
        P = POINT _P.x, _P.y

        Q_u = @bezierII 3, Q, u
        for i = 1, 3
            Q1[i] = POINT!
            Q1[i].x = (Q[i + 1].x - Q[i].x) * 3
            Q1[i].y = (Q[i + 1].y - Q[i].y) * 3

        for i = 1, 2
            Q2[i] = POINT!
            Q2[i].x = (Q1[i + 1].x - Q1[i].x) * 2
            Q2[i].y = (Q1[i + 1].y - Q1[i].y) * 2
    
        Q1_u = @bezierII 2, Q1, u
        Q2_u = @bezierII 1, Q2, u

        numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y)
        denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) + (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y)

        if denominator == 0
            return u

        return u - (numerator / denominator)

    reparameterize: (d, first, last, u, bezCurve) =>
        _bezCurve = {
            POINT bezCurve[1].x, bezCurve[1].y
            POINT bezCurve[2].x, bezCurve[2].y
            POINT bezCurve[3].x, bezCurve[3].y
            POINT bezCurve[4].x, bezCurve[4].y
        }
        uPrime = {}
        for i = first, last
            uPrime[i - first + 1] = @newtonRaphsonRootFind _bezCurve, d[i], u[i - first + 1]
        return uPrime

    BM: (u, tp) =>
        switch tp
            when 1 then 3 * u * ((1 - u) ^ 2)
            when 2 then 3 * (u ^ 2) * (1 - u)
            when 3 then u ^ 3
            else        (1 - u) ^ 3

    generateBezier: (d, first, last, uPrime, tHat1, tHat2) =>
        C, A, bezCurve = {{0, 0}, {0, 0}, {0, 0}}, {}, {}
        nPts = last - first + 1

        for i = 1, nPts
            v1 = POINT tHat1.x, tHat1.y
            v2 = POINT tHat2.x, tHat2.y
            v1 = v1\vecScale @BM uPrime[i], 1
            v2 = v2\vecScale @BM uPrime[i], 2
            A[i] = {v1, v2}

        for i = 1, nPts
            C[1][1] += A[i][1]\dot A[i][1]
            C[1][2] += A[i][1]\dot A[i][2]

            C[2][1] = C[1][2]
            C[2][2] += A[i][2]\dot A[i][2]

            b0 = d[first] * @BM uPrime[i]
            b1 = d[first] * @BM uPrime[i], 1
            b2 = d[last] * @BM uPrime[i], 2
            b3 = d[last] * @BM uPrime[i], 3

            tm0 = b2 + b3
            tm1 = b1 + tm0
            tm2 = b0 + tm1
            tmp = d[first + i - 1] - tm2

            C[3][1] += A[i][1]\dot tmp
            C[3][2] += A[i][2]\dot tmp

        det_C0_C1 = C[1][1] * C[2][2] - C[2][1] * C[1][2]
        det_C0_X = C[1][1] * C[3][2] - C[2][1] * C[3][1]
        det_X_C1 = C[3][1] * C[2][2] - C[3][2] * C[1][2]

        alpha_l = det_C0_C1 == 0 and 0 or det_X_C1 / det_C0_C1
        alpha_r = det_C0_C1 == 0 and 0 or det_C0_X / det_C0_C1

        segLength = d[last]\distance d[first]
        epsilon = 1e-6 * segLength

        if alpha_l < epsilon or alpha_r < epsilon
            dist = segLength / 3
            bezCurve[1] = d[first]
            bezCurve[4] = d[last]
            bezCurve[2] = bezCurve[1] + tHat1\vecScale dist
            bezCurve[3] = bezCurve[4] + tHat2\vecScale dist
            return bezCurve

        bezCurve[1] = d[first]
        bezCurve[4] = d[last]
        bezCurve[2] = bezCurve[1] + tHat1\vecScale alpha_l
        bezCurve[3] = bezCurve[4] + tHat2\vecScale alpha_r
        return bezCurve

    fitCubic: (d, first, last, tHat1, tHat2, _error) =>
        u, uPrime, maxIterations, tHatCenter = {}, {}, 4, POINT!
        iterationError = _error ^ 2
        nPts = last - first + 1

        if nPts == 2
            dist = d[last]\distance(d[first]) / 3

            bezCurve = {}
            bezCurve[1] = d[first]
            bezCurve[4] = d[last]
            tHat1 = tHat1\vecScale dist
            tHat2 = tHat2\vecScale dist
            bezCurve[2] = bezCurve[1] + tHat1
            bezCurve[3] = bezCurve[4] + tHat2
            @push bezCurve
            return

        u = @chordLengthParameterize d, first, last
        bezCurve = @generateBezier d, first, last, u, tHat1, tHat2

        resultMaxError = @computeMaxError d, first, last, bezCurve, u, nil
        maxError = resultMaxError.maxError
        splitPoint = resultMaxError.splitPoint

        if maxError < _error
            @push bezCurve
            return

        if maxError < iterationError
            for i = 1, maxIterations
                uPrime = @reparameterize d, first, last, u, bezCurve
                bezCurve = @generateBezier d, first, last, uPrime, tHat1, tHat2
                resultMaxError = @computeMaxError d, first, last, bezCurve, uPrime, splitPoint
                maxError = resultMaxError.maxError
                splitPoint = resultMaxError.splitPoint
                if maxError < _error
                    @push bezCurve
                    return
                u = uPrime

        tHatCenter = @computeCenterTangent d, splitPoint
        @fitCubic d, first, splitPoint, tHat1, tHatCenter, _error
        tHatCenter = tHatCenter\vecNegative!
        @fitCubic d, splitPoint, last, tHatCenter, tHat2, _error
        return

    fitCurve: (d, nPts, _error = 1) =>
        tHat1 = @computeLeftTangent d, 1
        tHat2 = @computeRightTangent d, nPts
        @fitCubic d, 1, nPts, tHat1, tHat2, _error
        return

    simplifyRadialDist: =>
        prevPoint = @pts[1]
        newPoints, point = {prevPoint}, nil
        for i = 2, #@pts
            point = @pts[i]
            if point\sqDistance(prevPoint) > @tol
                TABLE(newPoints)\push point
                prevPoint = point
        if prevPoint != point
            TABLE(newPoints)\push point
        return newPoints

    simplifyDPStep: (first, last, simplified) =>
        maxSqDist, index = @tol, nil
        for i = first + 1, last
            sqDist = @pts[i]\sqSegDistance @pts[first], @pts[last]
            if sqDist > maxSqDist
                index = i
                maxSqDist = sqDist
        if maxSqDist > @tol
            if index - first > 1
                @simplifyDPStep first, index, simplified
            TABLE(simplified)\push @pts[index]
            if last - index > 1
                @simplifyDPStep index, last, simplified

    simplifyDouglasPeucker: =>
        simplified = {@pts[1]}
        @simplifyDPStep 1, #@pts, simplified
        TABLE(simplified)\push @pts[#@pts]
        return simplified

    spLines: =>
        if #@pts <= 2
            return @pts

        @tol = @tol ^ 2
        @pts = @hqy and @pts or @simplifyRadialDist!
        @bld = @simplifyDouglasPeucker!
        return @bld

    spLines2Bezier: =>
        @fitCurve @pts, #@pts, @tol
        return @bld

{:PATH, :SIMPLIFY}