export script_name = "Snapper"
export script_description = "Snaps line start and end times to keyframes"
export script_author = "petzku"
export script_namespace = "petzku.Snapper"
export script_version = "1.0.1"

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
if havedc
    dep = DependencyControl{
        feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
    }

_snap_start = (subs, sel) ->
    kfs = aegisub.keyframes!
    table.sort kfs
    for i in *sel
        line = subs[i]
        t_start, t_end = aegisub.get_audio_selection!
        kf = do
            j = 1
            frame = aegisub.frame_from_ms t_start
            while kfs[j] <= frame
                j += 1
            kfs[j-1]

        line.start_time = aegisub.ms_from_frame kf
        line.end_time = t_end
        subs[i] = line

_snap_end = (subs, sel) ->
    kfs = aegisub.keyframes!
    table.sort kfs
    for i in *sel
        line = subs[i]
        t_start, t_end = aegisub.get_audio_selection!
        kf = do
            j = 1
            frame = aegisub.frame_from_ms t_end
            while kfs[j] < frame
                j += 1
            kfs[j]

        line.end_time = aegisub.ms_from_frame kf
        line.start_time = t_start
        subs[i] = line

snap_start = (subs, sel) ->
    _snap_start subs, sel
    aegisub.set_undo_point "snap line start to previous keyframe"

snap_end = (subs, sel) ->
    _snap_end subs, sel
    aegisub.set_undo_point "snap line end to next keyframe"

snap_both = (subs, sel) ->
    _snap_start subs, sel
    _snap_end subs, sel
    aegisub.set_undo_point "snap line start and end to surrounding keyframes"

macros = {
    {'start', "Snaps line start to previous keyframe", snap_start},
    {'end', "Snaps line end to next keyframe", snap_end}
    {'both', "Snaps line start and end to surrounding keyframes", snap_both}
}

if havedc
    dep\registerMacros macros
else
    for macro in *macros
        name, desc, fun, cond = unpack macro
        aegisub.register_macro script_name..'/'..name, desc, fun, cond
