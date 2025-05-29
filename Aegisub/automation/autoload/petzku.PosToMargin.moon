-- Copyright (c) 2021 petzku <petzku@zku.fi> 

export script_name =        "Margin Position"
export script_description = "Transforms \\pos-based positioning into margin and vice versa"
export script_author =      "petzku"
export script_namespace =   "petzku.PosToMargin"
export script_version =     "2.0.1"

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
if havedc
    dep = DependencyControl{
        feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
        {'karaskel'}
    }
    dep\requireModules!
else
    require 'karaskel'

margin_y_from_pos = (line, posy, height) ->
    an = line.text\match "\\an(%d)"
    valign = line.valign
    if an
        valign = switch math.floor((an - 1) / 3)
            when 0 then "bottom"
            when 1 then "middle"
            when 2 then "top"

    margin = switch valign
        when "top"
            math.floor(posy + 0.5)
        when "bottom"
            math.floor(height - posy + 0.5)
        else
            -- \an456 doesn't respect vertical margins at all
            return

    aegisub.log 4, "margin (%s): %s\n", type(margin), margin
    line.margin_t = margin

margin_x_from_pos = (line, posx, width) ->
    an = line.text\match "\\an(%d)"
    halign = line.halign
    if an
        halign = switch an % 3
            when 0 then "right"
            when 1 then "left"
            when 2 then "center"

    -- preserve the "width" of the available space, should ensure text never reflows accidentally.
    org_margin_l = if line.margin_l != 0 then line.margin_l else line.styleref.margin_l
    org_margin_r = if line.margin_r != 0 then line.margin_r else line.styleref.margin_r
    buffer = (org_margin_l + org_margin_r) / 2

    local margin_l, margin_r
    switch halign
        when "center"
            offset = posx - (width / 2)
            margin_l = buffer + offset
            margin_r = buffer - offset
        when "left"
            offset = posx
            margin_l = offset
            margin_r = 2 * buffer - offset
        when "right"
            offset = posx - width
            margin_l = 2 * buffer + offset
            margin_r = -offset

    -- ensure line margins are non-zero (i.e. do not read from style)
    -- might possibly cause reflows in very edge cases!
    if margin_l == 0
        margin_l = -1
        margin_r -= 1
    if margin_r == 0
        margin_r = -1
        margin_l -= 1
    
    -- for clean-up: remove useless margin values
    if margin_l == line.styleref.margin_l then margin_l = 0
    if margin_r == line.styleref.margin_r then margin_r = 0

    line.margin_l = math.floor(margin_l + 0.5)
    line.margin_r = math.floor(margin_r + 0.5)

remove_pos = (line) ->
    line.text = line.text\gsub("\\pos%b()", "", 1)
    -- in case position is the only tag, clean up the block too
    line.text = line.text\gsub("{}", "", 1)

pos2margin = (subs, sel) ->
    meta, styles = karaskel.collect_head subs, false
    width, height = meta.res_x, meta.res_y

    for i in *sel
        line = subs[i]
        karaskel.preproc_line subs, meta, styles, line

        posx, posy = line.text\match("\\pos%((-?[%d.]+),(-?[%d.]+)%)")
        unless posx continue

        margin_y_from_pos line, posy, height
        margin_x_from_pos line, posx, width

        remove_pos line

        subs[i] = line

margin2pos = (subs, sel) ->
    meta, styles = karaskel.collect_head subs, false
    width, height = meta.res_x, meta.res_y

    for i in *sel
        line = subs[i]
        karaskel.preproc_line subs, meta, styles, line

        marg_l = if line.margin_l != 0 then line.margin_l else line.styleref.margin_l
        marg_r = if line.margin_r != 0 then line.margin_r else line.styleref.margin_r
        marg_v = if line.margin_v != 0 then line.margin_v else line.styleref.margin_v
        an = line.text\match "\\an(%d)"

        halign = line.halign
        if an
            halign = switch an % 3
                when 0 then "right"
                when 1 then "left"
                when 2 then "center"
        valign = line.valign
        if an
            valign = switch math.floor((an - 1) / 3)
                when 0 then "bottom"
                when 1 then "middle"
                when 2 then "top"

        x = switch halign
            when "left"
                marg_l
            when "center"
                (marg_l + width - marg_r) / 2
            when "right"
                width - marg_r
        y = switch valign
            when "top"
                marg_v
            when "bottom"
                height - marg_v
            else
                height / 2

        pos_str = string.format("{\\pos(%d,%d)}", x, y)
        line.text = (pos_str..line.text)\gsub("}{", "", 1)

        subs[i] = line

check_pos = (subs, sel) ->
    -- check that at least one line in selection has a position tag, otherwise we'd be doing nothing
    for i in *sel
        line = subs[i]
        if line.text\match "\\pos%b()"
            return true
    return false

macros = {
    {"Position to Margin", "Transforms \\pos-based positioning into margin", pos2margin, check_pos},
    {"Margin to Position", "Transforms margin-based positioning into \\pos", margin2pos}
}

if havedc
    dep\registerMacros macros
else
    for macro in *macros
        aegisub.register_macro unpack macro
