-- Adds a mode to unanimated's JumpToNext script (https://github.com/unanimated/luaegisub/blob/master/ua.JumpToNext.lua)
-- to jump to the next/previous start time for a line. Should work entirely standalone too.
-- Might be useful for jumping around really big signs that are edited every few frames, or something
--
-- Note: because I'm lazy and ua's code is horrible, I didn't bother implementing the multiline thing.
-- Just gonna use the first selected line or something

script_name = "Jump to Next++"
script_description = "Jumps to next 'sign' in the subtitle grid"
script_description2 = "Jumps to previous 'sign' in the subtitle grid"
script_author = "petzku"
script_version = "0.1.5"
script_namespace = "petzku.JumpToNextPlus"

local DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"}

function nextsel(subs, sel, marker)
    local start = sel[1]
    local i = 1
    local mark = markers(subs[start], marker)
    while start + i <= #subs do
        local line = subs[start+i]
        local hit = markers(line, marker)
        if hit ~= mark then
            sel = {start + i}
            break
        end
        i = i + 1 
    end
    return sel
end

function prevsel(subs, sel, marker)
    local start = sel[1]
    local i = 1
    local mark = markers(subs[start], marker)
    while start - i > 0 do
        local line = subs[start-i]
        local hit = markers(line, marker)
        if hit ~= mark then
            sel = {start - i}
            break
        end
        i = i + 1
    end
    return sel
end

function markers(line, marker)
    if marker == "start" then return line.start_time end
    if marker == "end" then return line.end_time end
end

function nextStart(subs, sel) sel = nextsel(subs, sel, "start") return sel end
function prevStart(subs, sel) sel = prevsel(subs, sel, "start") return sel end
function nextEnd(subs, sel) sel = nextsel(subs, sel, "end") return sel end
function prevEnd(subs, sel) sel = prevsel(subs, sel, "end") return sel end

depctrl:registerMacros({
    {"Jump to Next/Start Time", script_description, nextStart},
    {"Jump to Next/End Time", script_description, nextEnd},
    {"Jump to Previous/Start Time", script_description2, prevStart},
    {"Jump to Previous/End Time", script_description2, prevEnd},
}, false)
