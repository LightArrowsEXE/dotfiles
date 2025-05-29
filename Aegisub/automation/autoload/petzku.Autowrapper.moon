export script_name = "Autowrapper"
export script_description = "Automatically set/unset \\q2 on lines with/without manual linebreaks"
export alt_description = "Automatically unset \\q2 on lines without manual linebreaks"
export script_author = "petzku"
export script_namespace = "petzku.Autowrapper"
export script_version = "0.5.1"

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
if havedc
    dep = DependencyControl{
        feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
        {'karaskel'}
    }
    dep\requireModules!
else
    require 'karaskel'

lines_needed = (meta, line) ->
    -- maximum width of line before automatically wrapping
    -- eff_margin takes into account in-line margins
    wrap_width = meta.res_x - line.eff_margin_l - line.eff_margin_r
    line.width / wrap_width

process = (subs, _sel, add_q2=true, rem_q2=true) ->
    meta, styles = karaskel.collect_head subs, false
    -- operate on all dialogue lines, not just selection
    -- maybe change this?
    res_addq2, res_autobreak, res_remq2 = 0,0,0
    res_overq2 = 0
    res_threelines, res_maybethree = 0, 0
    for i, line in ipairs subs
        continue unless line.class == 'dialogue' and not line.comment
        karaskel.preproc_line subs, meta, styles, line

        if line.text_stripped\find '\\N'
            if add_q2 and not line.text\find '\\q2'
                line.text = '{\\q2}'..line.text
                res_addq2 += 1
        else
            lines = lines_needed meta, line
            if not line.text\find '\\q2'
                if lines > 2
                    -- three-liner
                    line.effect ..= "## THREE-LINER ##"
                    res_threelines += 1
                elseif lines > 1.9
                    -- maybe three-liner
                    line.effect ..= "## POSSIBLE THREE-LINER ##"
                    res_maybethree += 1
                elseif lines > 1
                    -- warn, do not add \q2
                    line.effect ..= "## AUTOMATIC LINEBREAK ##"
                    res_autobreak += 1
            else
                if lines > 1
                    -- overwidth but has \q2
                    line.effect ..= "## OVERWIDTH WITH FORCED WRAP ##"
                    res_overq2 += 1
                elseif rem_q2
                    line.text = line.text\gsub '\\q2', ''
                    -- and remove empty tag blocks, if we caused one
                    line.text = line.text\gsub '{}', ''
                    res_remq2 += 1
        subs[i] = line
    aegisub.set_undo_point "automatically set/unset \\q2"

    if res_addq2 > 0 then     aegisub.log "Added %d \\q2's on lines with \\N\n", res_addq2
    if res_autobreak > 0 then aegisub.log "Found %d automatic linebreaks\n", res_autobreak
    if res_threelines + res_maybethree > 0 then aegisub.log "Found %d three-liners and %d likely ones\n", res_threelines, res_maybethree
    if res_overq2 > 0 then    aegisub.log "Found %d overwidth lines with forced wrapping\n", res_overq2
    if res_remq2 > 0 then     aegisub.log "Removed %d \\q2's from lines without \\N\n", res_remq2

main = (subs, sel) ->
    process subs, sel

no_q2 = (subs, sel) ->
    process subs, sel, false

comment = (subs, sel) ->
    process subs, sel, false, false

macros = {
    { "Add missing \\q2 tags", script_description, main },
    { "Remove unnecessary \\q2 tags", alt_description, no_q2 },
    { "Only note automatic breaks", "", comment }
}

if havedc
    dep\registerMacros macros
else
    for m in *macros
        name, desc, fun = unpack m
        aegisub.register_macro script_name..'/'..name, desc, fun
