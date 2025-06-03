export script_name = "Toggle Templates"
export script_description = "Toggle disabled state for selected auto4 ktemplate components"
export script_author = "petzku"
export script_version = "0.3.2"
export script_namespace = "petzku.ToggleTemplates"

is_component = (line) ->
    return false unless line.class == "dialogue" and line.comment
    cls = line.effect\match "(%l+) "
    -- assume anything marked "disabled" is also fair game
    return cls == 'disabled' or cls == 'template' or cls == 'code' or cls == 'mixin' or line.effect == 'kara'

is_disabled = (line) ->
    return 'disabled' == line.effect\sub 1, 8

main = (sub, sel) ->
    for i in *sel
        line = sub[i]
        continue unless is_component line
        if is_disabled line
            line.effect = line.effect\sub 10
        else
            line.effect = 'disabled ' .. line.effect
        sub[i] = line

can_run = (sub, sel) ->
    for i in *sel
        return true if is_component sub[i]
    return false

aegisub.register_macro script_name, script_description, main
