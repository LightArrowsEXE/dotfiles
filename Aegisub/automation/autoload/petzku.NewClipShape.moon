-- Copyright (c) 2021 petzku <petzku@zku.fi>

export script_name =        "New Clip Shape"
export script_description = "Converts the last point of a vectorial clip into a new origin point"
export script_author =      "petzku"
export script_namespace =   "petzku.NewClipShape"
export script_version =     "0.3.2"

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
if havedc
    dep = DependencyControl{feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"}

make_final_move = (clip) ->
    aegisub.log 4, "make_final_move('%s')\n", clip

    clip\gsub " ([-%d.]+ [-%d.]+)%s*$", " m %1"

rep_clip_tag = (tag) ->
    tag\gsub "m [^)]+", make_final_move

main = (subs, sel) ->
    for i in *sel
        line = subs[i]

        aegisub.log 5, "looking at line %d: %s\n", i, line.text
        continue unless line.text\match "\\i?clip%(m .*%)"

        -- very permissive pattern, because make_final_move only needs one valid pair of coords at the end
        line.text = line.text\gsub "\\i?clip%(m .*%)", rep_clip_tag

        aegisub.log 5, "after gsub, line.text: %s\n", line.text

        subs[i] = line

can_run = (subs, sel) ->
    for i in *sel
        line = subs[i]
        return true if line.text\match "\\i?clip%(m .*%)"
    false

if havedc
    dep\registerMacro main, can_run
else
    aegisub.register_macro script_name, script_description, main, can_run
