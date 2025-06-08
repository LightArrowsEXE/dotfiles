-- Lua port of https://github.com/kilobtye/potrace

import MATH  from require "ZF.main.util.math"
import SHAPE from require "ZF.main.2D.shape"
import IMAGE from require "ZF.main.img.img"

push_b0 = (t, ...) -> -- table.push base 0
    insert, n = table.insert, select "#", ...
    for i = 1, n
        v = select i, ...
        if not t[0] and #t == 0
            t[0] = v
        else
            insert t, v
    return ...

class Point

    new: (x = 0, y = 0) => @x, @y = x, y

    copy: => Point @x, @y

class Bitmap

    new: (w, h) =>
        @w = w
        @h = h
        @size = w * h
        @data = {}

    at: (x, y) => (x >= 0 and x < @w and y >= 0 and y < @h) and (@data[@w * y + x] == 1)

    index: (i) =>
        point = Point!
        point.y = math.floor i / @w
        point.x = i - point.y * @w
        return point

    flip: (x, y) => @data[@w * y + x] = @at(x, y) and 0 or 1

    copy: =>
        bm = Bitmap @w, @h
        for i = 0, @size - 1
            bm.data[i] = @data[i]
        return bm

class Curve

    new: (n) =>
        @n = n
        @tag = {}
        @c = {}
        @alphaCurve = 0
        @vertex = {}
        @alpha = {}
        @alpha0 = {}
        @beta = {}

class Path

    new: =>
        @area = 0
        @len = 0
        @curve = {}
        @pt = {}
        @minX = 100000
        @minY = 100000
        @maxX = -1
        @maxY = -1

class Sum

    new: (x, y, xy, x2, y2) =>
        @x = x
        @y = y
        @xy = xy
        @x2 = x2
        @y2 = y2

class SetConfigs

    new: (...) =>
        args = ... and (type(...) == "table" and ... or {...}) or {}
        @turnpolicy = args[1] or (@turnpolicy or "minority")
        @turdsize = args[2] or (@turdsize or 2)
        @optcurve = args[3] or (@optcurve  or true)
        @alphamax = args[4] or (@alphamax or 1)
        @opttolerance = args[5] or (@opttolerance or 0.2)

class Quad

    new: => @data = {[0]: 0, 0, 0, 0, 0, 0, 0, 0, 0}

    at: (x, y) => @data[x * 3 + y]

class Opti

    new: =>
        @pen = 0
        @c = {[0]: Point!, Point!}
        @t = 0
        @s = 0
        @alpha = 0

class POTRACE extends IMAGE

    start: (frame, ...) =>
        @configs = SetConfigs ...
        @setInfos frame

        w, h = @width, @height

        @bm = Bitmap w, h
        @pathlist = {}

        for i = 0, w * h - 1
            with @data[i]
                -- We want background underneath non-opaque regions to be white
                alpha = .a / 255
                .r = 255 + (.r - 255) * alpha
                .g = 255 + (.g - 255) * alpha
                .b = 255 + (.b - 255) * alpha

                color = 0.2126 * .r + 0.7153 * .g + 0.0721 * .b
                @bm.data[i] = color < 128 and 1 or 0
        return @

    process: =>
        @bmToPathlist!
        @processPath!
        return

    bmToPathlist: =>
        currentPoint, bm1 = Point!, @bm\copy!
        findNext = (point) ->
            i = bm1.w * point.y + point.x
            while i < bm1.size and bm1.data[i] != 1
                i += 1
            return i < bm1.size and bm1\index(i) or nil

        majority = (x, y) ->
            for i = 2, 4
                ct = 0
                for a = -i + 1, i - 1
                    ct += bm1\at(x + a, y + i - 1) and 1 or -1
                    ct += bm1\at(x + i - 1, y + a - 1) and 1 or -1
                    ct += bm1\at(x + a - 1, y - i) and 1 or -1
                    ct += bm1\at(x - i, y + a) and 1 or -1
                if ct > 0
                    return 1
                elseif ct < 0
                    return 0
            return 0

        findPath = (point) ->
            path, x, y, dirx, diry = Path!, point.x, point.y, 0, 1
            path.sign = @bm\at(point.x, point.y) and "+" or "-"
            while true
                push_b0(path.pt, Point(x, y))
                if x > path.maxX then path.maxX = x
                if x < path.minX then path.minX = x
                if y > path.maxY then path.maxY = y
                if y < path.minY then path.minY = y
                path.len += 1
                x += dirx
                y += diry
                path.area -= x * diry
                break if x == point.x and y == point.y
                l = bm1\at(x + (dirx + diry - 1) / 2, y + (diry - dirx - 1) / 2)
                r = bm1\at(x + (dirx - diry - 1) / 2, y + (diry + dirx - 1) / 2)
                if r and not l
                    if @configs.turnpolicy == "right" or (@configs.turnpolicy == "black" and path.sign == '+') or (@configs.turnpolicy == "white" and path.sign == '-') or (@configs.turnpolicy == "majority" and majority(x, y)) or (@configs.turnpolicy == "minority" and not majority(x, y))
                        tmp = dirx
                        dirx = -diry
                        diry = tmp
                    else
                        tmp = dirx
                        dirx = diry
                        diry = -tmp
                elseif r
                    tmp = dirx
                    dirx = -diry
                    diry = tmp
                elseif not l
                    tmp = dirx
                    dirx = diry
                    diry = -tmp
            return path

        xorPath = (path) ->
            y1, len = path.pt[0].y, path.len
            for i = 1, len - 1
                x = path.pt[i].x
                y = path.pt[i].y
                if y != y1
                    minY = y1 < y and y1 or y
                    maxX = path.maxX
                    for j = x, maxX - 1
                        bm1\flip(j, minY)
                    y1 = y

        while currentPoint
            path = findPath(currentPoint)
            xorPath(path)
            if path.area > @configs.turdsize
                push_b0(@pathlist, path)
            currentPoint = findNext(currentPoint)

    processPath: =>
        mod = (a, n) -> a >= n and a % n or a >= 0 and a or n - 1 - (-1 - a) % n
        xprod = (p1, p2) -> p1.x * p2.y - p1.y * p2.x
        sign = (i) -> i > 0 and 1 or i < 0 and -1 or 0
        ddist = (p, q) -> sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y))

        cyclic = (a, b, c) ->
            if a <= c
                return a <= b and b < c
            else
                return a <= b or b < c

        quadform = (Q, w) ->
            sum, v = 0, {[0]: w.x, [1]: w.y, [2]: 1}
            for i = 0, 2
                for j = 0, 2
                    sum += v[i] * Q\at(i, j) * v[j]
            return sum

        interval = (lambda, a, b) ->
            res = Point!
            res.x = a.x + lambda * (b.x - a.x)
            res.y = a.y + lambda * (b.y - a.y)
            return res

        dorth_infty = (p0, p2) ->
            r = Point!
            r.y = sign(p2.x - p0.x)
            r.x = -sign(p2.y - p0.y)
            return r

        ddenom = (p0, p2) ->
            r = dorth_infty(p0, p2)
            return r.y * (p2.x - p0.x) - r.x * (p2.y - p0.y)

        dpara = (p0, p1, p2) ->
            x1 = p1.x - p0.x
            y1 = p1.y - p0.y
            x2 = p2.x - p0.x
            y2 = p2.y - p0.y
            return x1 * y2 - x2 * y1

        cprod = (p0, p1, p2, p3) ->
            x1 = p1.x - p0.x
            y1 = p1.y - p0.y
            x2 = p3.x - p2.x
            y2 = p3.y - p2.y
            return x1 * y2 - x2 * y1

        iprod = (p0, p1, p2) ->
            x1 = p1.x - p0.x
            y1 = p1.y - p0.y
            x2 = p2.x - p0.x
            y2 = p2.y - p0.y
            return x1 * x2 + y1 * y2

        iprod1 = (p0, p1, p2, p3) ->
            x1 = p1.x - p0.x
            y1 = p1.y - p0.y
            x2 = p3.x - p2.x
            y2 = p3.y - p2.y
            return x1 * x2 + y1 * y2

        bezier = (t, p0, p1, p2, p3) ->
            s, res = 1 - t, Point!
            res.x = s * s * s * p0.x + 3 * (s * s * t) * p1.x + 3 * (t * t * s) * p2.x + t * t * t * p3.x
            res.y = s * s * s * p0.y + 3 * (s * s * t) * p1.y + 3 * (t * t * s) * p2.y + t * t * t * p3.y
            return res

        tangent = (p0, p1, p2, p3, q0, q1) ->
            A = cprod(p0, p1, q0, q1)
            B = cprod(p1, p2, q0, q1)
            C = cprod(p2, p3, q0, q1)
            a = A - 2 * B + C
            b = -2 * A + 2 * B
            c = A
            d = b * b - 4 * a * c
            return -1 if a == 0 or d < 0
            s = sqrt(d)
            r1 = (-b + s) / (2 * a)
            r2 = (-b - s) / (2 * a)
            if r1 >= 0 and r1 <= 1
                return r1
            elseif r2 >= 0 and r2 <= 1
                return r2
            else
                return -1

        calcSums = (path) ->
            path.x0 = path.pt[0].x
            path.y0 = path.pt[0].y
            path.sums = {}
            s = path.sums
            push_b0(s, Sum(0, 0, 0, 0, 0))
            for i = 0, path.len - 1
                x = path.pt[i].x - path.x0
                y = path.pt[i].y - path.y0
                push_b0(s, Sum(s[i].x + x, s[i].y + y, s[i].xy + x * y, s[i].x2 + x * x, s[i].y2 + y * y))

        calcLon = (path) ->
            n, pt, pivk, nc, ct, path.lon, foundk = path.len, path.pt, {}, {}, {}, {}, nil
            constraint = {[0]: Point!, Point!}
            cur, off, dk, k = Point!, Point!, Point!, 0
            for i = n - 1, 0, -1
                if pt[i].x != pt[k].x and pt[i].y != pt[k].y
                    k = i + 1
                nc[i] = k
            for i = n - 1, 0, -1
                ct[0], ct[1], ct[2], ct[3] = 0, 0, 0, 0
                dir = (3 + 3 * (pt[mod(i + 1, n)].x - pt[i].x) + (pt[mod(i + 1, n)].y - pt[i].y)) / 2
                ct[dir] += 1
                constraint[0].x = 0
                constraint[0].y = 0
                constraint[1].x = 0
                constraint[1].y = 0
                k, k1 = nc[i], i
                while true
                    foundk = 0
                    dir = (3 + 3 * sign(pt[k].x - pt[k1].x) + sign(pt[k].y - pt[k1].y)) / 2
                    ct[dir] += 1
                    if ct[0] != 0 and ct[1] != 0 and ct[2] != 0 and ct[3] != 0
                        pivk[i] = k1
                        foundk = 1
                        break
                    cur.x = pt[k].x - pt[i].x
                    cur.y = pt[k].y - pt[i].y
                    if xprod(constraint[0], cur) < 0 or xprod(constraint[1], cur) > 0
                        break
                    if abs(cur.x) <= 1 and abs(cur.y) <= 1
                        _ = _ -- ??
                    else
                        off.x = cur.x + ((cur.y >= 0 and (cur.y > 0 or cur.x < 0)) and 1 or -1)
                        off.y = cur.y + ((cur.x <= 0 and (cur.x < 0 or cur.y < 0)) and 1 or -1)
                        if xprod(constraint[0], off) >= 0
                            constraint[0].x = off.x
                            constraint[0].y = off.y
                        off.x = cur.x + ((cur.y <= 0 and (cur.y < 0 or cur.x < 0)) and 1 or -1)
                        off.y = cur.y + ((cur.x >= 0 and (cur.x > 0 or cur.y < 0)) and 1 or -1)
                        if xprod(constraint[1], off) <= 0
                            constraint[1].x = off.x
                            constraint[1].y = off.y
                    k1 = k
                    k = nc[k1]
                    break if not cyclic(k, i, k1)
                if foundk == 0
                    dk.x = sign(pt[k].x - pt[k1].x)
                    dk.y = sign(pt[k].y - pt[k1].y)
                    cur.x = pt[k1].x - pt[i].x
                    cur.y = pt[k1].y - pt[i].y
                    a = xprod(constraint[0], cur)
                    b = xprod(constraint[0], dk)
                    c = xprod(constraint[1], cur)
                    d = xprod(constraint[1], dk)
                    j = 10000000
                    if b < 0
                        j = floor(a / -b)
                    if d > 0
                        j = min(j, floor(-c / d))
                    pivk[i] = mod(k1 + j, n)
            j = pivk[n - 1]
            path.lon[n - 1] = j
            for i = n - 2, 0, -1
                if cyclic(i + 1, pivk[i], j)
                    j = pivk[i]
                path.lon[i] = j
            i = n - 1
            while cyclic(mod(i + 1, n), j, path.lon[i])
                path.lon[i] = j
                i -= 1

        bestPolygon = (path) ->
            penalty3 = (path, i, j) ->
                local x, y, xy, x2, y2, k
                n, pt, sums, r = path.len, path.pt, path.sums, 0
                if j >= n
                    j -= n
                    r = 1
                if r == 0
                    x = sums[j + 1].x - sums[i].x
                    y = sums[j + 1].y - sums[i].y
                    x2 = sums[j + 1].x2 - sums[i].x2
                    xy = sums[j + 1].xy - sums[i].xy
                    y2 = sums[j + 1].y2 - sums[i].y2
                    k = j + 1 - i
                else
                    x = sums[j + 1].x - sums[i].x + sums[n].x
                    y = sums[j + 1].y - sums[i].y + sums[n].y
                    x2 = sums[j + 1].x2 - sums[i].x2 + sums[n].x2
                    xy = sums[j + 1].xy - sums[i].xy + sums[n].xy
                    y2 = sums[j + 1].y2 - sums[i].y2 + sums[n].y2
                    k = j + 1 - i + n
                px = (pt[i].x + pt[j].x) / 2 - pt[0].x
                py = (pt[i].y + pt[j].y) / 2 - pt[0].y
                ey = (pt[j].x - pt[i].x)
                ex = -(pt[j].y - pt[i].y)
                a = ((x2 - 2 * x * px) / k + px * px)
                b = ((xy - x * py - y * px) / k + px * py)
                c = ((y2 - 2 * y * py) / k + py * py)
                s = ex * ex * a + 2 * ex * ey * b + ey * ey * c
                return sqrt(s)
            n = path.len
            pen, prev, clip0, clip1, seg0, seg1 = {}, {}, {}, {}, {}, {}
            for i = 0, n - 1
                c = mod(path.lon[mod(i - 1, n)] - 1, n)
                if c == i
                    c = mod(i + 1, n)
                if c < i
                    clip0[i] = n
                else
                    clip0[i] = c
            j = 1
            for i = 0, n - 1
                while j <= clip0[i]
                    clip1[j] = i
                    j += 1
            i, j = 0, 0
            while i < n
                seg0[j] = i
                i = clip0[i]
                j += 1
            seg0[j] = n
            m = j
            i, j = n, m
            while j > 0
                seg1[j] = i
                i = clip1[i]
                j -= 1
            seg1[0], pen[0], j = 0, 0, 1
            while j <= m
                for i = seg1[j], seg0[j]
                    best = -1
                    for k = seg0[j - 1], clip1[i], -1
                        thispen = penalty3(path, k, i) + pen[k]
                        if best < 0 or thispen < best
                            prev[i] = k
                            best = thispen
                    pen[i] = best
                j += 1
            path.m, path.po = m, {}
            i, j = n, m - 1
            while i > 0
                i = prev[i]
                path.po[j] = i
                j -= 1

        adjustVertices = (path) ->
            pointslope = (path, i, j, ctr, dir) ->
                n, sums, r, l = path.len, path.sums, 0, nil
                while j >= n
                    j -= n
                    r += 1
                while i >= n
                    i -= n
                    r -= 1
                while j < 0
                    j += n
                    r -= 1
                while i < 0
                    i += n
                    r += 1
                x = sums[j + 1].x - sums[i].x + r * sums[n].x
                y = sums[j + 1].y - sums[i].y + r * sums[n].y
                x2 = sums[j + 1].x2 - sums[i].x2 + r * sums[n].x2
                xy = sums[j + 1].xy - sums[i].xy + r * sums[n].xy
                y2 = sums[j + 1].y2 - sums[i].y2 + r * sums[n].y2
                k = j + 1 - i + r * n
                ctr.x = x / k
                ctr.y = y / k
                a = (x2 - x * x / k) / k
                b = (xy - x * y / k) / k
                c = (y2 - y * y / k) / k
                lambda2 = (a + c + sqrt((a - c) * (a - c) + 4 * b * b)) / 2
                a -= lambda2
                c -= lambda2
                if abs(a) >= abs(c)
                    l = sqrt(a * a + b * b)
                    if l != 0
                        dir.x = -b / l
                        dir.y = a / l
                else
                    l = sqrt(c * c + b * b)
                    if l != 0
                        dir.x = -c / l
                        dir.y = b / l
                if l == 0
                    dir.x = 0
                    dir.y = 0
            m, po, n, pt, x0, y0 = path.m, path.po, path.len, path.pt, path.x0, path.y0
            q, v, s, ctr, dir = {}, {}, Point!, {}, {}
            path.curve = Curve(m)
            for i = 0, m - 1
                j = po[mod(i + 1, m)]
                j = mod(j - po[i], n) + po[i]
                ctr[i] = Point!
                dir[i] = Point!
                pointslope(path, po[i], j, ctr[i], dir[i])
            for i = 0, m - 1
                q[i] = Quad!
                d = dir[i].x * dir[i].x + dir[i].y * dir[i].y
                if d == 0
                    for j = 0, 2
                        for k = 0, 2
                            q[i].data[j * 3 + k] = 0
                else
                    v[0] = dir[i].y
                    v[1] = -dir[i].x
                    v[2] = -v[1] * ctr[i].y - v[0] * ctr[i].x
                    for l = 0, 2
                        for k = 0, 2
                            q[i].data[l * 3 + k] = v[l] * v[k] / d
            for i = 0, m - 1
                Q = Quad!
                w = Point!
                s.x = pt[po[i]].x - x0
                s.y = pt[po[i]].y - y0
                j = mod(i - 1, m)
                for l = 0, 2
                    for k = 0, 2
                        Q.data[l * 3 + k] = q[j]\at(l, k) + q[i]\at(l, k)
                while true
                    det = Q\at(0, 0) * Q\at(1, 1) - Q\at(0, 1) * Q\at(1, 0)
                    if det != 0
                        w.x = (-Q\at(0, 2) * Q\at(1, 1) + Q\at(1, 2) * Q\at(0, 1)) / det
                        w.y = (Q\at(0, 2) * Q\at(1, 0) - Q\at(1, 2) * Q\at(0, 0)) / det
                        break
                    if Q\at(0, 0) > Q\at(1, 1)
                        v[0] = -Q\at(0, 1)
                        v[1] = Q\at(0, 0)
                    elseif (Q\at(1, 1)) != 0
                        v[0] = -Q\at(1, 1)
                        v[1] = Q\at(1, 0)
                    else
                        v[0] = 1
                        v[1] = 0
                    d = v[0] * v[0] + v[1] * v[1]
                    v[2] = -v[1] * s.y - v[0] * s.x
                    for l = 0, 2
                        for k = 0, 2
                            Q.data[l * 3 + k] += v[l] * v[k] / d
                dx = abs(w.x - s.x)
                dy = abs(w.y - s.y)
                if dx <= 0.5 and dy <= 0.5
                    path.curve.vertex[i] = Point(w.x + x0, w.y + y0)
                    continue
                min, xmin, ymin = quadform(Q, s), s.x, s.y
                if Q\at(0, 0) != 0
                    for z = 0, 1
                        w.y = s.y - 0.5 + z
                        w.x = -(Q\at(0, 1) * w.y + Q\at(0, 2)) / Q\at(0, 0)
                        dx = abs(w.x - s.x)
                        cand = quadform(Q, w)
                        if dx <= 0.5 and cand < min
                            min, xmin, ymin = cand, w.x, w.y
                if Q\at(1, 1) != 0
                    for z = 0, 1
                        w.x = s.x - 0.5 + z
                        w.y = -(Q\at(1, 0) * w.x + Q\at(1, 2)) / Q\at(1, 1)
                        dy = abs(w.y - s.y)
                        cand = quadform(Q, w)
                        if dy <= 0.5 and cand < min
                            min, xmin, ymin = cand, w.x, w.y
                for l = 0, 2
                    for k = 0, 2
                        w.x = s.x - 0.5 + l
                        w.y = s.y - 0.5 + k
                        cand = quadform(Q, w)
                        if cand < min
                            min, xmin, ymin = cand, w.x, w.y
                path.curve.vertex[i] = Point(xmin + x0, ymin + y0)

        reverse = (path) ->
            curve = path.curve
            m, v = curve.n, curve.vertex
            i, j = 0, m - 1
            while i < j
                tmp = v[i]
                v[i] = v[j]
                v[j] = tmp
                i += 1
                j -= 1

        smooth = (path) ->
            m, curve, alpha = path.curve.n, path.curve, nil
            for i = 0, m - 1
                j = mod(i + 1, m)
                k = mod(i + 2, m)
                p4 = interval(1 / 2, curve.vertex[k], curve.vertex[j])
                denom = ddenom(curve.vertex[i], curve.vertex[k])
                if denom != 0
                    dd = dpara(curve.vertex[i], curve.vertex[j], curve.vertex[k]) / denom
                    dd = abs(dd)
                    alpha = dd > 1 and (1 - 1 / dd) or 0
                    alpha /= 0.75
                else
                    alpha = 4 / 3
                curve.alpha0[j] = alpha
                if alpha >= @configs.alphamax
                    curve.tag[j] = "CORNER"
                    curve.c[3 * j + 1] = curve.vertex[j]
                    curve.c[3 * j + 2] = p4
                else
                    if alpha < 0.55
                        alpha = 0.55
                    elseif alpha > 1
                        alpha = 1
                    p2 = interval(0.5 + 0.5 * alpha, curve.vertex[i], curve.vertex[j])
                    p3 = interval(0.5 + 0.5 * alpha, curve.vertex[k], curve.vertex[j])
                    curve.tag[j] = "CURVE"
                    curve.c[3 * j + 0] = p2
                    curve.c[3 * j + 1] = p3
                    curve.c[3 * j + 2] = p4
                curve.alpha[j] = alpha
                curve.beta[j] = 0.5
            curve.alphacurve = 1

        optiCurve = (path) ->

            opti_penalty = (path, i, j, res, opttolerance, convc, areac) ->
                m = path.curve.n
                curve = path.curve
                vertex = curve.vertex
                return 1 if i == j
                k = i
                i1 = mod(i + 1, m)
                k1 = mod(k + 1, m)
                conv = convc[k1]
                return 1 if conv == 0
                d = ddist(vertex[i], vertex[i1])
                k = k1
                while k != j
                    k1 = mod(k + 1, m)
                    k2 = mod(k + 2, m)
                    return 1 if convc[k1] != conv
                    return 1 if sign(cprod(vertex[i], vertex[i1], vertex[k1], vertex[k2])) != conv
                    return 1 if iprod1(vertex[i], vertex[i1], vertex[k1], vertex[k2]) < d * ddist(vertex[k1], vertex[k2]) * -0.999847695156
                    k = k1
                p0 = curve.c[mod(i, m) * 3 + 2]\copy!
                p1 = vertex[mod(i + 1, m)]\copy!
                p2 = vertex[mod(j, m)]\copy!
                p3 = curve.c[mod(j, m) * 3 + 2]\copy!
                area = areac[j] - areac[i]
                area -= dpara(vertex[0], curve.c[i * 3 + 2], curve.c[j * 3 + 2]) / 2
                area += areac[m] if i >= j
                A1 = dpara(p0, p1, p2)
                A2 = dpara(p0, p1, p3)
                A3 = dpara(p0, p2, p3)
                A4 = A1 + A3 - A2
                return 1 if A2 == A1
                t = A3 / (A3 - A4)
                s = A2 / (A2 - A1)
                A = A2 * t / 2
                return 1 if A == 0
                R = area / A
                alpha = 2 - sqrt(4 - R / 0.3)
                res.c[0] = interval(t * alpha, p0, p1)
                res.c[1] = interval(s * alpha, p3, p2)
                res.alpha = alpha
                res.t = t
                res.s = s
                p1 = res.c[0]\copy!
                p2 = res.c[1]\copy!
                res.pen = 0
                k = mod(i + 1, m)
                while k != j
                    k1 = mod(k + 1, m)
                    t = tangent(p0, p1, p2, p3, vertex[k], vertex[k1])
                    return 1 if t < -0.5
                    pt = bezier(t, p0, p1, p2, p3)
                    d = ddist(vertex[k], vertex[k1])
                    return 1 if d == 0
                    d1 = dpara(vertex[k], vertex[k1], pt) / d
                    return 1 if abs(d1) > opttolerance
                    return 1 if iprod(vertex[k], vertex[k1], pt) < 0 or iprod(vertex[k1], vertex[k], pt) < 0
                    res.pen += d1 * d1
                    k = k1
                k = i
                while k != j
                    k1 = mod(k + 1, m)
                    t = tangent(p0, p1, p2, p3, curve.c[k * 3 + 2], curve.c[k1 * 3 + 2])
                    return 1 if t < -0.5
                    pt = bezier(t, p0, p1, p2, p3)
                    d = ddist(curve.c[k * 3 + 2], curve.c[k1 * 3 + 2])
                    return 1 if d == 0
                    d1 = dpara(curve.c[k * 3 + 2], curve.c[k1 * 3 + 2], pt) / d
                    d2 = dpara(curve.c[k * 3 + 2], curve.c[k1 * 3 + 2], vertex[k1]) / d
                    d2 *= 0.75 * curve.alpha[k1]
                    if d2 < 0
                        d1 = -d1
                        d2 = -d2
                    return 1 if d1 < d2 - opttolerance
                    if d1 < d2
                        res.pen += (d1 - d2) * (d1 - d2)
                    k = k1
                return 0
            curve = path.curve
            m, vert, pt, pen, len, opt, convc, areac, o = curve.n, curve.vertex, {}, {}, {}, {}, {}, {}, Opti!
            for i = 0, m - 1
                if curve.tag[i] == "CURVE"
                    convc[i] = sign(dpara(vert[mod(i - 1, m)], vert[i], vert[mod(i + 1, m)]))
                else
                    convc[i] = 0
            area, areac[0] = 0, 0
            p0 = curve.vertex[0]
            for i = 0, m - 1
                i1 = mod(i + 1, m)
                if curve.tag[i1] == "CURVE"
                    alpha = curve.alpha[i1]
                    area += 0.3 * alpha * (4 - alpha) * dpara(curve.c[i * 3 + 2], vert[i1], curve.c[i1 * 3 + 2]) / 2
                    area += dpara(p0, curve.c[i * 3 + 2], curve.c[i1 * 3 + 2]) / 2
                areac[i + 1] = area
            pt[0], pen[0], len[0] = -1, 0, 0
            for j = 1, m
                pt[j] = j - 1
                pen[j] = pen[j - 1]
                len[j] = len[j - 1] + 1
                for i = j - 2, 0, -1
                    r = opti_penalty(path, i, mod(j, m), o, @configs.opttolerance, convc, areac)
                    break if r == 1
                    if len[j] > len[i] + 1 or (len[j] == len[i] + 1 and pen[j] > pen[i] + o.pen)
                        pt[j] = i
                        pen[j] = pen[i] + o.pen
                        len[j] = len[i] + 1
                        opt[j] = o
                        o = Opti!
            om = len[m]
            ocurve = Curve(om)
            s, t, j = {}, {}, m
            for i = om - 1, 0, -1
                if pt[j] == j - 1
                    ocurve.tag[i] = curve.tag[mod(j, m)]
                    ocurve.c[i * 3 + 0] = curve.c[mod(j, m) * 3 + 0]
                    ocurve.c[i * 3 + 1] = curve.c[mod(j, m) * 3 + 1]
                    ocurve.c[i * 3 + 2] = curve.c[mod(j, m) * 3 + 2]
                    ocurve.vertex[i] = curve.vertex[mod(j, m)]
                    ocurve.alpha[i] = curve.alpha[mod(j, m)]
                    ocurve.alpha0[i] = curve.alpha0[mod(j, m)]
                    ocurve.beta[i] = curve.beta[mod(j, m)]
                    s[i] = 1
                    t[i] = 1
                else
                    ocurve.tag[i] = "CURVE"
                    ocurve.c[i * 3 + 0] = opt[j].c[0]
                    ocurve.c[i * 3 + 1] = opt[j].c[1]
                    ocurve.c[i * 3 + 2] = curve.c[mod(j, m) * 3 + 2]
                    ocurve.vertex[i] = interval(opt[j].s, curve.c[mod(j, m) * 3 + 2], vert[mod(j, m)])
                    ocurve.alpha[i] = opt[j].alpha
                    ocurve.alpha0[i] = opt[j].alpha
                    s[i] = opt[j].s
                    t[i] = opt[j].t
                j = pt[j]
            for i = 0, om - 1
                i1 = mod(i + 1, om)
                ocurve.beta[i] = s[i] / (s[i] + t[i1])
            ocurve.alphacurve = 1
            path.curve = ocurve
        for i = 0, #@pathlist
            path = @pathlist[i]
            calcSums(path)
            calcLon(path)
            bestPolygon(path)
            adjustVertices(path)
            reverse(path) if path.sign == "-"
            smooth(path)
            optiCurve(path) if @configs.optcurve

    getShape: (dec) =>
        path = (curve) ->
            local x1, y1, x2, y2, x3, y3
            bezier = (i) ->
                {x: x1, y: y1} = curve.c[i * 3 + 0]
                {x: x2, y: y2} = curve.c[i * 3 + 1]
                {x: x3, y: y3} = curve.c[i * 3 + 2]
                return "b #{x1} #{y1} #{x2} #{y2} #{x3} #{y3} "
            segment = (i) ->
                {x: x1, y: y1} = curve.c[i * 3 + 1]
                return "l #{x1} #{y1} "
            n = curve.n
            {x: x1, y: y1} = curve.c[(n - 1) * 3 + 2]
            conc = "m #{x1} #{y1} "
            for i = 0, n - 1
                tag = curve.tag[i]
                if tag == "CURVE"
                    conc ..= bezier i
                elseif tag == "CORNER"
                    conc ..= segment i
            return SHAPE(conc)\build dec
        shape = ""
        for i = 0, #@pathlist
            shape ..= path @pathlist[i].curve
        return shape

{:POTRACE}