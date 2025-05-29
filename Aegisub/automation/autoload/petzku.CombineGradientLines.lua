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

-- Combines consecutive identical lines in a clip-based gradient, especially those created using GradientEverything

script_name = "Combine Gradient Lines"
script_description = "Combines identical rect-clip gradient lines"
script_author = "petzku"
script_version = "0.2.5"
script_namespace = "petzku.CombineGradientLines"

local DependencyControl = require("l0.DependencyControl")
local depctrl = DependencyControl{feed = "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"}

local function generate_clipstr(corners)
    return ("\\clip(%.2f,%.2f,%.2f,%.2f)")
            :format(unpack(corners))
            :gsub("(%d)%.00", "%1")
end

local function extend_prev(subs, prev, x1, y1, x2, y2)
    local previ, prevline, _, prevstart, prevrest = unpack(prev)
    local newclip = {x1, y1, x2, y2}
    local clipstr = generate_clipstr(newclip)
    prevline.text = prevstart .. clipstr .. prevrest
    subs[previ] = prevline
    aegisub.log(4, "combined new clip: %s\n", clipstr)
    return {previ, prevline, newclip, prevstart, prevrest}
end

function combine_gradient_lines(subs, sel)
    local to_delete = {}
    local prev = nil

    local new_sel = {}
    local removed = 0

    for _, li in ipairs(sel) do
        local line = subs[li]
        aegisub.log(5, "started on line: %s\n", line.text)
        local s, e, x1,y1, x2,y2 = line.text:find("\\clip%((-?[%d.]+),(-?[%d.]+),(-?[%d.]+),(-?[%d.]+)%)")

        if not s then
            table.insert(new_sel, li-removed)
            goto continue --based luaJIT
        end
        local start, rest = line.text:sub(1, s-1), line.text:sub(e+1, -1)

        local clip = {tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2)}
        if not prev then
            prev = {li, line, clip, start, rest}
            aegisub.log(5, "No prev entry... (should happen only once)\n")
            table.insert(new_sel, li)
        else
            local previ, _, prevclip, prevstart, prevrest = unpack(prev)

            aegisub.log(5, "prev: %d, %s, %s\n", previ, prevstart, prevrest)
            if start == prevstart and rest == prevrest then
                aegisub.log(5, "combining...\n")
                -- nothing's changed, try to combine
                local px1, py1, px2, py2 = unpack(prevclip)

                local function conditional_combine(comp1, comp2)
                    if comp1 == 0 then
                        return extend_prev(subs, prev, px1,py1, x2,y2)
                    elseif comp2 == 0 then
                        return extend_prev(subs, prev, x1,y1, px2,py2)
                    else
                        -- just in case: gap or overlap, do nothing
                        aegisub.log(5, "skipping (no matching co-ords)\n")
                        return
                    end
                end

                local p
                if x1 - px1 == 0 and x2 - px2 == 0 then
                    -- x co-ords match -> combine y co-ords
                    p = conditional_combine(y1-py2, y2-py1)
                elseif y1 - py1 == 0 and y2 - py2 == 0 then
                    -- combine x co-ords
                    p = conditional_combine(x1-px2, x2-px1)
                end
                if p then
                    prev = p
                    removed = removed + 1
                else
                    prev = {li, line, clip, start, rest}
                    table.insert(new_sel, li-removed)
                end

                table.insert(to_delete, li)
            else
                prev = {li, line, clip, start, rest}
                table.insert(new_sel, li-removed)
                aegisub.log(5, "mismatch, skipping\n")
            end
        end
        ::continue::
    end

    for i=#to_delete,1,-1 do
        subs.delete(to_delete[i])
    end
    aegisub.set_undo_point(script_name)
    return new_sel
end

depctrl:registerMacro(combine_gradient_lines)
