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

--[[ README

Extrapolate a \move over a portion of line's length to full line length.

More specifically, compute the four-param move tag which will match the
currently existing six-param movement. Should work even if one or more
timestamps are outside the line's duration. Those will just be clipped
to the line's time bounds.

]]

script_name = "Extrapolate Move"
script_description = "Extrapolates a \\move tag to the line's full duration"
script_version = "0.1.5"
script_author = "petzku"
script_namespace = "petzku.ExtrapolateMove"

local haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
    depctrl = DependencyControl{
        feed = "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
        {'karaskel'}
    }
    depctrl:requireModules()
else
    require 'karaskel'
end

--- Extrapolates movement to full line length from given move
-- coordinate order is the same as ASS \move tag
-- all six \move tag params are mandatory
function extrapolate(t_start, t_end, x1, y1, x2, y2, t1, t2)
    length = t2 - t1
    dx = (x2 - x1) / length
    dy = (y2 - y1) / length

    start_x = x1 - dx * (t1 - t_start)
    start_y = y1 - dy * (t1 - t_start)
    end_x   = x2 + dx * (t_end - t2)
    end_y   = y2 + dy * (t_end - t2)

    return start_x, start_y, end_x, end_y;
end

function extrapolate_move_to_full_line(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)
    for si, li in ipairs(sel) do
        local line = subs[li]
        karaskel.preproc_line(subs, meta, styles, line)

        -- kinda evil regex matching, can I avoid this?
        regex_movtag = "\\move%(%-?[%d.]+,%-?[%d.]+,%-?[%d.]+,%-?[%d.]+,%-?[%d.]+,%-?[%d.]+%)"
        movtag = line.text:match(regex_movtag)
        if movtag ~= nil then
            -- really ugly :/
            t = {}
            for num in movtag:gmatch("%-?[%d.]+") do
                t[#t+1] = tonumber(num)
            end
            x1, y1, x2, y2 = extrapolate(0, line.duration, unpack(t))
            newtag = string.format("\\move(%.2f,%.2f,%.2f,%.2f)", x1, y1, x2, y2)
            newtext = line.text:gsub(regex_movtag, newtag, 1)
            line.text = newtext
            subs[li] = line
        end
    end
end

if haveDepCtrl then
    depctrl:registerMacro(extrapolate_move_to_full_line)
else
    aegisub.register_macro(script_name, script_description, extrapolate_move_to_full_line)
end
