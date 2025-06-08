import MATH from require "ZF.main.util.math"

class POINT

    version: "1.0.0"

    new: (x = 0, y = 0) =>
        @x = type(x) == "table" and (rawget(x, "x") and x.x or x[1]) or x
        @y = type(x) == "table" and (rawget(x, "y") and x.y or x[2]) or y

    __add: (p = 0) => type(p) == "number" and POINT(@x + p, @y + p) or POINT(@x + p.x, @y + p.y)
    __sub: (p = 0) => type(p) == "number" and POINT(@x - p, @y - p) or POINT(@x - p.x, @y - p.y)
    __mul: (p = 1) => type(p) == "number" and POINT(@x * p, @y * p) or POINT(@x * p.x, @y * p.y)
    __div: (p = 1) => type(p) == "number" and POINT(@x / p, @y / p) or POINT(@x / p.x, @y / p.y)
    __mod: (p = 1) => type(p) == "number" and POINT(@x % p, @y % p) or POINT(@x % p.x, @y % p.y)
    __pow: (p = 1) => type(p) == "number" and POINT(@x ^ p, @y ^ p) or POINT(@x ^ p.x, @y ^ p.y)

    __eq: (p) => @x == p.x and @y == p.y
    __df: (p) => @x != p.x and @y != p.y
    __lt: (p) => @x < p.x and @y < p.y
    __le: (p) => @x <= p.x and @y <= p.y
    __gt: (p) => @x > p.x and @y > p.y
    __ge: (p) => @x >= p.x and @y >= p.y

    __tostring: => "#{@x} #{@y} "

    get: => @
    set: (p) => @x, @y = p.x, p.y

    dot: (p) => @x * p.x + @y * p.y

    min: (p) => POINT min(@x, p.x), min(@y, p.y)
    max: (p) => POINT max(@x, p.x), max(@y, p.y)

    minx: (p) => POINT min(@x, p.x), @y
    miny: (p) => POINT @x, min(@y, p.y)
    maxx: (p) => POINT max(@x, p.x), @y
    maxy: (p) => POINT @x, max(@y, p.y)

    copy: => POINT @x, @y
    angle: (p) => deg atan2(p.y - @y, p.x - @x)
    cross: (p, o) => (@x - o.x) * (p.y - o.y) - (@y - o.y) * (p.x - o.x)
    distance: (p) => sqrt (p.x - @x) ^ 2 + (p.y - @y) ^ 2
    inside: (p1, p2) => (p2.x - p1.x) * (@y - p1.y) > (p2.y - p1.y) * (@x - p1.x)
    lerp: (p, t = 0.5) => POINT (1 - t) * @x + t * p.x, (1 - t) * @y + t * p.y
    abs: => @x, @y = abs(@x), abs(@y)

    round: (dec = 3) =>
        @x = MATH\round @x, dec
        @y = MATH\round @y, dec
        return @

    rotate: (c = POINT!, angle) =>
        @x = cos(angle) * (@x - c.x) - sin(angle) * (@y - c.y) + c.x
        @y = sin(angle) * (@x - c.x) + cos(angle) * (@y - c.y) + c.y
        return @

    hypot: =>
        if @x == 0 and @y == 0
            return 0
        @abs!
        x, y = max(@x, @y), min(@x, @y)
        return x * sqrt 1 + (y / x) ^ 2

    vecDistance: => @x ^ 2 + @y ^ 2
    vecDistanceSqrt: => sqrt @vecDistance!
    vecNegative: => POINT -@x, -@y

    vecNormalize: =>
        result = POINT!
        length = @vecDistanceSqrt!
        if length != 0
            result.x = @x / length
            result.y = @y / length
        return result

    vecScale: (len) =>
        result = POINT!
        length = @vecDistanceSqrt!
        if length != 0
            result.x = @x * len / length
            result.y = @y * len / length
        return result

    sqDistance: (p) => @distance(p) ^ 2

    sqSegDistance: (p1, p2) =>
        p = POINT p1
        d = p2 - p
        if d.x != 0 or d.y != 0
            t = ((@x - p.x) * d.x + (@y - p.y) * d.y) / d\vecDistance!
            if t > 1
                p = POINT p2
            elseif t > 0
                p += d * t
        return @sqDistance p

{:POINT}