-- Copyright (c) 2024 petzku <petzku@zku.fi>

export script_name =        "Honorary"
export script_description = "Rightfully restore (or remove) honoraries easily by inserting autoswapper bits"
export script_author =      "petzku"
export script_namespace =   "petzku.Honorary"
export script_version =     "0.2.0"


_add_swap = (line, idx) ->
    beg, den = line.text\sub(1, idx-1), line.text\sub(idx)
    line.text = beg .. "{**}" .. den
    -- cursor at end of this: {**_}
    aegisub.gui.set_cursor idx + 3
    line

_enable = (line) ->
    ss, se = aegisub.gui.get_selection!
    beg = line.text\sub 1, ss-1
    sel = line.text\sub ss, se-1
    den = line.text\sub se
    line.text = "#{beg}{*}#{sel}{*}#{den}"
    -- at second: mary{*}-tan{*_}
    aegisub.gui.set_cursor #beg + #sel + 6
    line

_disable = (line) ->
    ss, se = aegisub.gui.get_selection!
    beg = line.text\sub 1, ss-1
    sel = line.text\sub ss, se-1
    den = line.text\sub se
    line.text = "#{beg}{*}{*#{sel}}#{den}"
    -- at first: mary{*}_{*-tan}
    aegisub.gui.set_cursor #beg + 4
    line


main = (line, fun) ->
    -- if zero-length selection, just add the swap thing
    ss, se = aegisub.gui.get_selection!
    if ss == se
        _add_swap line, ss
    else
        fun line


main_en = (sub, _, act) ->
    sub[act] = main sub[act], _enable

main_dis = (sub, _, act) ->
    sub[act] = main sub[act], _disable


aegisub.register_macro "#{script_name}/Enable", "Rightfully restore the honorary", main_en
aegisub.register_macro "#{script_name}/Disable", "Rightfully remove the honorary", main_dis
