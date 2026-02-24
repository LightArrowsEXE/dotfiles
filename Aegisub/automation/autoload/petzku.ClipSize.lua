-- Copyright (c) 2020, petzku <petzku@zku.fi>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-- Provides dimensions of a clip on the currently active line

script_name = "Clip Size"
script_description = "Measures distances in a vectorial clip"
script_author = "petzku"
script_version = "1.3.0"
script_namespace = "petzku.ClipSize"

local DependencyControl = require("l0.DependencyControl")
local depctrl = DependencyControl{feed = "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"}

function clipsize(subs, sel)
    -- consider only first active line; clip tools usually deselect all others anyway
    local line = subs[sel[1]]
    local clip = line.text:match("\\i?clip(%b())")
    aegisub.log(5, "clip match: `%s`\n", clip)
    local coords = {}
    -- at least some builds of aegi have subpixel precision clip tools
    local is_subpixel = false
    if clip:find(',') then
        -- rect clip
        local xs1,ys1,xs2,ys2 = clip:match("([%d.]+),([%d.]+),([%d.]+),([%d.]+)")
        local x1,y1,x2,y2 = tonumber(xs1), tonumber(ys1), tonumber(xs2), tonumber(ys2)
        coords = {{x1, y1}, {x2, y2}}
        if not (isint(x1) and isint(x2) and isint(y1) and isint(y2)) then
            is_subpixel = true
        end
    else
        for xs,ys in clip:gmatch("([%d.]+) ([%d.]+)") do
            local x = tonumber(xs)
            local y = tonumber(ys)
            table.insert(coords, {x, y})
            if not (isint(x) and isint(y)) then is_subpixel = true end
        end
    end
    aegisub.log(5, "coords size: %d\n", #coords)

    dialog = {{class='label', x=0, y=0, label="Clip sizes:"}}
    for i = 1, #coords-1 do
        aegisub.log(5, "current coords: %d %d\n", coords[i][1], coords[i][2])
        local dx = coords[i+1][1] - coords[i][1]
        local dy = coords[i+1][2] - coords[i][2]
        local dx_string, dy_string
        if is_subpixel then
            dx_string = align_number(dx, 7, 1)
            dy_string = align_number(dy, 7, 1)
        else
            dx_string = align_number(dx, 5, 0)
            dy_string = align_number(dy, 5, 0)
        end
        -- aegisub.log(3, "delta: %s, %s\n", dx_string, dy_string)
        table.insert(dialog, {class='label', x=1, y=i, label=dx_string})
        table.insert(dialog, {class='label', x=3, y=i, label=dy_string})
    end
    aegisub.dialog.display(dialog)
end

function align_number(n, width, precision)
    -- https://en.wikipedia.org/wiki/Figure_space, thanks bucket3432
    return string.format("%"..width.."."..precision.."f", n):gsub(' ', ' ')
end

function isint(x)
    return x == math.floor(x)
end

depctrl:registerMacro(clipsize)
