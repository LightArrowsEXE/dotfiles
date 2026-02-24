-- Copyright (c) 2023 petzku <petzku@zku.fi>

export script_name = "Cycle actor field"
export script_namespace = "petzku.CycleActors"
export script_version = "0.1.3"



collect_actors = (sub, idx) ->
    act = {}
    foundacts = {}
    for i = idx, 1, -1
        line = sub[i]
        continue unless line.class == 'dialogue' and not line.comment and line.actor != ''
        continue if foundacts[line.actor]
        table.insert act, line.actor
        foundacts[line.actor] = #act
    return act, foundacts

set_actors = (newact, sub, sel) ->
    for i in *sel
        line = sub[i]
        line.actor = newact
        sub[i] = line

cycle_forward = (sub, sel) ->
    actors, index = collect_actors sub, sel[1]-1
    firstline = sub[sel[1]]
    idx = index[firstline.actor] or 0
    newact = actors[(idx % #actors)+1]
    set_actors newact, sub, sel

cycle_back = (sub, sel) ->
    actors, index = collect_actors sub, sel[1]-1
    firstline = sub[sel[1]]
    idx = index[firstline.actor]
    idx = idx and idx > 1 and idx or #actors+1
    newact = actors[idx - 1]
    set_actors newact, sub, sel


aegisub.register_macro "#{script_name}/Forward", "", cycle_forward
aegisub.register_macro "#{script_name}/Backward", "", cycle_back
