-- Automatically add accent characters to lines

-- To use: add a tag block immediately before the character with "instructions":
-- Syntax (regex): `!(a|b)([+-]\d+)?(.+)` above/below -- vertical correction in pixels (positive = up) -- accent character or alias
-- Note: one tag should specify only one accent character
-- Sample: `{!a^}s` to place a caret above the character
-- Sample: `{!b+5˘}h` to place a breve below the character, then move up 5 pixels to correct position
-- Sample: `{!amacron}{!a+10grave}n` to place a macron above the character, then a grave above that

-- Creates lines with an effect of "accent", automatically cleans all lines with this effect when running

-- Note: Only works with lines that don't have a linebreak.
-- TODO: Fix that.

script_name = "Accenter"
script_description = "Automatically create accents for lines"
script_author = "petzku"
script_version = "0.2.6"
script_namespace = "petzku.Accenter"

EFFECT = 'accent'
ALIASES = {
    acute = '´',
    grave = '`',
    circumflex = 'ˆ',
    caret = 'ˆ',
    caron = 'ˇ',
    umlaut = '¨',
    macron = 'ˉ',
    breve = '˘',
    overring = '˚',
    oring = '˚',
    o = '˚',
    underring = '˳',
    uring = '˳',
    tilde = '˜',
    ['..'] = '¨',
    ['^'] = 'ˆ',
    ['~'] = '˜',
}

local DependencyControl = require("l0.DependencyControl")
local depctrl = DependencyControl{
    { "karaskel", "aegisub.util" },
    feed = "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"}

kara, util = depctrl:requireModules()

function clear_old(subs, sel)
    -- remove old generated lines
    local to_delete = {}
    for i, line in ipairs(subs) do
        if line.effect and line.effect:find(EFFECT) then
            to_delete[#to_delete + 1] = i
        end
    end
    subs.delete(to_delete)
end

function preproc_chars(line)
    -- preprocess chars in line
    local chars = {}
    local left = line.left
    local i = 1
    -- TODO: this means we drop tags. fine if using just dialog style, not if not.
    for ch in unicode.chars(line.text_stripped) do
        local char = {line = line, i = i}
        char.text = ch
        char.width, char.height, char.descent, _ = aegisub.text_extents(line.styleref, ch)
        char.left = left
        char.center = left + char.width/2

        -- to handle multibyte characters correctly. just remember it's not a normal array
        chars[i] = char
        i = i + ch:len()
        left = left + char.width
    end
    return chars
end

function generate_accents(line)
    -- input line must be karaskel preproc'd
    local chars = preproc_chars(line)

    -- iterate through tag blocks
    local accents = {}
    local i = 1
    local tags_len = 0
    local text = line.text
    local curr_tags = ""
    while true do
        local s, e, tag = text:find("(%b{})", i)
        if tag == nil then break end
        tags_len = tags_len + tag:len()
        if tag:sub(2,2) == "!" then
            -- if it's an accenter block, process it
            aegisub.log(5, "tag: '%s'\n", tag)
            -- note: this is slightly different from the described syntax, because lua patterns don't allow optional groups
            local ab, corr, accent = tag:sub(2, -2):match("!([ab])([+-]?%d*)(.+)")
            if ALIASES[accent] then accent = ALIASES[accent] end
            aegisub.log(5, "ab: '%s', corr: '%s', accent: '%s'\n", ab, corr, accent)

            local char = chars[e - tags_len + 1]
            local acc_line = util.deep_copy(line)

            local x_pos = char.center
            local y_pos = line.middle
            if ab == 'b' then y_pos = y_pos + char.height - char.descent end
            if corr ~= "" and tonumber(corr) then y_pos = y_pos - tonumber(corr) end
            aegisub.log(5, "pos: %.2f, %.2f\n", x_pos, y_pos)

            -- copy any saved tags to the new line, except positioning
            -- TODO: do something to wipe duplicate tags? won't affect rendering, but would be cleaner.
            local t = curr_tags:gsub("\\pos%b()",""):gsub("\\an?%d+",""):gsub("\\move%b()","")
            acc_line.text = string.format("{\\pos(%.2f,%.2f)\\an5%s}%s", x_pos, y_pos, t, accent)
            acc_line.effect = acc_line.effect .. EFFECT
            aegisub.log(5, "Generated line: %s\n", acc_line.text)
            table.insert(accents, acc_line)
        else
            -- ... and save tags if not
            curr_tags = curr_tags .. tag:sub(2,-2)
            aegisub.log(5, "curr_tags: %s\n", curr_tags)
        end
        i = e + 1
    end
    return accents
end

function process_lines(subs, sel)
    local meta, styles = karaskel.collect_head(subs, false)

    local to_add = {}
    local count = #subs
    for i, line in ipairs(subs) do
        aegisub.progress.set(100 * i / count)
        if line.text and not line.comment and line.text:find("{!.*}") then
            -- god why does lua not have `continue`
            karaskel.preproc_line(subs, meta, styles, line)
            to_add[#to_add+1] = {location=i, lines=generate_accents(line)}
        end
    end

    -- bottom-to-top for easy insertion at correct index
    -- TODO: consider layering differently: accents above on a lower layer, below on a higher one
    -- this would handle normal shadows more neatly
    for i = #to_add, 1, -1 do
        local loc = to_add[i].location
        local lines = to_add[i].lines
        for j, line in ipairs(lines) do
            subs.insert(loc+j, line)
        end
    end
end

function main(subs, sel)
    local task = aegisub.progress.task

    task("Clearing old output...")
    clear_old(subs, sel)

    task("Generating new accents...")
    process_lines(subs, sel)

    aegisub.set_undo_point("generate accents")
end

depctrl:registerMacro(main)
