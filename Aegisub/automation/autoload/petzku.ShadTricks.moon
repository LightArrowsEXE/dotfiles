-- Copyright (c) 2021, petzku <petzku@zku.fi>

export script_name =        "Shadtricks"
export script_description = "(Semi-)automate shad tricking"
export script_author =      "petzku"
export script_namespace =   "petzku.ShadTricks"
export script_version =     "0.1.0"

main = (sub, sel) ->
    for i in *sel
        line = sub[i]
        if line.text\sub(1,1) == "{"
            line.text = "{\\1a&HFE&\\3a&HFE&\\4a&H00&\\shad0.01\\bord0" .. line.text\sub(2)
        else
            line.text = "{\\1a&HFE&\\3a&HFE&\\4a&H00&\\shad0.01\\bord0}" .. line.text
        sub[i] = line

aegisub.register_macro(script_name, script_description, main)
