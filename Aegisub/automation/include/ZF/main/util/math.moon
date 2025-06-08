-- globalize lib math
with math
    export pi, log, sin, cos, tan, max, min      = .pi, .log, .sin, .cos, .tan, .max, .min
    export abs, deg, rad, log10, asin, sqrt     = .abs, .deg, .rad, .log10, .asin, .sqrt
    export acos, atan, sinh, cosh, tanh, random = .acos, .atan, .asin, .cosh, .tanh, .random
    export ceil, floor, atan2, format, unpack   = .ceil, .floor, .atan2, string.format, table.unpack or unpack

class MATH

    version: "1.1.1"

    -- rounds numerical values
    -- @param a number
    -- @param dec integer
    round: (a, dec = 3, snot = 10 ^ floor(dec)) => dec >= 1 and floor(a * snot + 0.5) / snot or floor(a + 0.5)

    -- clamps the value in a rage
    -- @param a number
    -- @param b number
    -- @param c number
    -- @return number
    clamp: (a, b, c) => min max(a, b), c

    -- random values between a min and max value
    -- @param a number
    -- @param b number
    -- @return number
    random: (a, b) => random! * (b - a) + a

    -- interpolation between two numerical values
    -- @param t number
    -- @param a number
    -- @param b number
    -- @return number
    lerp: (t, a, b, u = @clamp t, 0, 1) => @round (1 - u) * a + u * b

    -- https://stackoverflow.com/a/27176424
    -- gets the roots of a cubic equation
    -- @param a number
    -- @param b number
    -- @param c number
    -- @param d number
    -- @param ep number
    -- @return table
    cubicRoots: (a, b, c, d, ep = 1e-8) =>
        cubeRoot = (x) ->
            y = abs(x) ^ (1 / 3)
            return x < 0 and -y or y

        p = (3 * a * c - b * b) / (3 * a * a)
        q = (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (27 * a * a * a)

        roots = {}
        if abs(p) < ep
            roots[1] = cubeRoot -q
        elseif abs(q) < ep
            roots[1] = 0
            roots[2] = p < 0 and sqrt(-p) or nil
            roots[3] = p < 0 and -sqrt(-p) or nil
        else
            D = q * q / 4 + p * p * p / 27
            if abs(D) < ep
                roots[1] = -1.5 * q / p
                roots[2] = 3 * q / p
            elseif D > 0
                u = cubeRoot -q / 2 - sqrt(D)
                roots[1] = u - p / (3 * u)
            else
                u = 2 * sqrt(-p / 3)
                t = acos(3 * q / p / u) / 3
                k = 2 * pi / 3
                roots[1] = u * cos t
                roots[2] = u * cos t - k
                roots[3] = u * cos t - 2 * k

        for i = 1, #roots
            roots[i] -= b / (3 * a)

        return roots

{:MATH}