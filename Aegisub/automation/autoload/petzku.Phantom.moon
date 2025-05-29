-- Copyright (c) 2022, petzku <petzku@zku.fi>

export script_name =        "Phantom"
export script_description = "Align line content to match others by adding text and abusing transparency"
export script_author =      "petzku"
export script_namespace =   "petzku.Phantom"
export script_version =     "1.1.1"

-- Currently uses {} as delimiters
-- e.g. "foo{}bar{}baz" -> "<HIDE>bar<SHOW>foobar<HIDE>baz"

-- Additionally, if using a version of aegisub exposing cursor position, an extra macro is registered,
-- using the selection (and direction of it) to determine the "desired" output.

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
dep = DependencyControl{feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"} if havedc

HIDE = "{\\alpha&HFF&}"
SHOW = "{\\alpha}"

proc_align_start = (beg, mid, den) -> HIDE..mid..SHOW..beg..mid..HIDE..den
proc_align_end =   (beg, mid, den) -> HIDE..beg..SHOW..mid..den..HIDE..mid

pattern_replacer = (rep) -> (part, _offset) ->
    -- thanks for the Universal Pattern Hammer, arch1t3ct
    part\gsub "^(.-){}(.-){}(.-)$", rep

cursor_proc = (part, offset) ->
    sels, sele = aegisub.gui.get_selection()
    cur = aegisub.gui.get_cursor() or sele
    -- blame arch1t3ct if this can be something other than a selection endpoint
    proc = if sele == cur then proc_align_start else proc_align_end

    sels = sels - offset
    sele = sele - offset

    if sels > part\len! or sele < 1
        part
    else
        proc part\sub(1, sels-1), part\sub(sels, sele-1), part\sub(sele)
    

-- only operate on active line; ignore selection
main = (sub, act, proc) ->
    line = sub[act]
    
    -- extract start tags
    start, text = line.text\match "^({.-})(.+)$"
    unless start
        start, text = "", line.text

    procd = {}
    idx_offset = #start

    for part in string.gmatch text.."\\N", "(.-)\\N"
        part = proc part, idx_offset
        table.insert procd, part
        -- adjust for processed output + newline
        idx_offset += #part + 2
    
    line.text = start .. table.concat procd, "\\N"
    sub[act] = line

align_start = (sub, _sel, act) ->
    main sub, act, pattern_replacer proc_align_start
    
align_end = (sub, _sel, act) ->
    main sub, act, pattern_replacer proc_align_end

align_by_cursor = (sub, _sel, act) ->
    main sub, act, cursor_proc

macros = {
    {script_name.."/Align start", "Keep start of line aligned", align_start},
    {script_name.."/Align end", "Keep end of line aligned", align_end}
}
if aegisub.gui
    table.insert macros, {script_name.."/By cursor", "Determine sections and alignment from selection", align_by_cursor}

if havedc
    dep\registerMacros macros
else
    for macro in *macros
        aegisub.register_macro unpack macro
