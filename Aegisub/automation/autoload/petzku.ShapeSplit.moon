-- Copyright (c) 2024, petzku <petzku@zku.fi>

export script_name =        "Split shapes"
export script_description = "Splits shapes"
export script_author =      "petzku"
export script_namespace =   "petzku.ShapeSplit"
export script_version =     "0.2.0"


main = (sub, sel) ->
    for si = #sel, 1, -1
        i = sel[si]
        line = sub[i]
        continue unless line.text\match "\\p1"
        tags = line.text\match "%b{}"
        shape = line.text\sub(#tags + 1)
        sub.delete i
        for sh in shape\gmatch "m [^m]+"
            line.text = tags .. sh
            sub[-i] = line

aegisub.register_macro ":: &Clip && Shape/#{script_name}", script_description, main