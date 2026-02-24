-- Copyright (c) 2025 petzku <petzku@zku.fi>

export script_name =        "Quantize K-timing"
export script_description = "Quantize \\k-tags to discrete beats"
export script_author =      "petzku"
export script_namespace =   "petzku.QuantizeKara"
export script_version =     "1.0.0"

require 'karaskel'

round = (x) -> math.floor x + 0.5

-- bpm (quarter notes)
BPM = nil

-- ms duration of 16th
notedur16 = -> 60 * 1000 / BPM / 4
-- ms duration of 24th (16th triplets)
notedur24 = -> 60 * 1000 / BPM / 6

quantize = (quantum, sub, sel) ->
    for i in *sel
        line = sub[i]
        -- karaskel internal function, but it's documented, so...
        karaskel.preproc_line_text nil, nil, line

        line.text = ""
        local last_offset

        for syl in *line.kara
            -- first syl
            if not last_offset
                last_offset = 0
                -- blank first syl
                if syl.text_stripped == ""
                    -- ignore this syl. assume its end time is accurate; only adjust all following syls
                    line.text ..= "{#{syl.tag}#{syl.duration/10}}"
                    last_offset
                    continue

            dur16ths = (last_offset + syl.duration) / quantum
            aegisub.log 5, "%s + %s = %s", last_offset, syl.duration, last_offset+syl.duration
            -- round to nearest 16th
            newdur = quantum * round dur16ths
            -- round to cs and replace into text
            newkdur = round newdur / 10
            aegisub.log 5, " -> %s (%s) ~ %s", newdur, dur16ths, (newkdur * 10)

            last_offset = (last_offset + syl.duration) - (10 * newkdur)
            newtag = "{#{syl.tag}#{newkdur}}"
            aegisub.log 5, " (%s)\n", last_offset

            -- we might *want to* use gsub, but since we must do replacements one at a time, it's better to rebuild the line ourself
            -- this also means we get to avoid other kinds of dumb shit
            line.text ..= newtag .. syl.text
        sub[i] = line

quantize_16th = (...) -> quantize notedur16!, ...
quantize_24th = (...) -> quantize notedur24!, ...

-- try to calculate bpm from k tags
-- assume each is a quarter note, round to integer bpm
calc_bpm = (sub, sel, act) ->
    line = sub[act]
    karaskel.preproc_line_text nil, nil, line
    -- treat first and last syls as buffers (last syl's start should be placed on the final beat)
    first_time = line.kara[1].end_time
    last_time = line.kara[#line.kara].start_time
    beat_count = #line.kara - 1
    aegisub.log 5, "%d beats from %d to %d", beat_count, first_time, last_time

    -- in ms
    beatdur = (last_time - first_time) / (beat_count - 1)
    _bpm = 60 * 1000 / beatdur
    export BPM = round _bpm
    aegisub.log 5, " -> %.2f bpm (%.2f ms) => %d\n", _bpm, beatdur, BPM
    aegisub.log 3, "Determined BPM: %d\n", BPM

set_bpm = () ->
    btn, res = aegisub.dialog.display {
        { x: 0, y: 0, class: 'label', label: "BPM: " }
        { x: 1, y: 0, class: 'intedit', value: BPM or 120, name: 'bpm' }
    }
    BPM = res.bpm if btn


can_quantize = (sub, sel) ->
    -- require BPM to be set before running
    return false unless BPM
    -- check for at least some karaoke tags, hopefully
    for i in *sel
        return true if sub[i].text\match "\\[kK]"
    false

can_derive = (sub, sel, act) ->
    -- current line should have at least two k tags
    _, n = sub[act].text\gsub "\\[kK]", '', 2
    n > 1


macros = {
    {"Quantize to 16th notes", script_description, quantize_16th, can_quantize}
    {"Quantize to 16th triplets", script_description, quantize_24th, can_quantize}
    {"Derive BPM from k-tags", "Determine BPM from k-timed quarter notes", calc_bpm, can_derive}
    {"Set BPM...", "Set BPM for quantization", set_bpm}
}

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
if havedc
    dep = DependencyControl
        feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"
    dep\registerMacros macros
else
    for macro in *macros
        macro[1] = "#{script_name}/#{macro[1]}"
        aegisub.register_macro unpack macro
