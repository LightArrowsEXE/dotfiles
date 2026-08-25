export script_name = "QC Report"
export script_description = "Write and generate QC reports"
export script_author = "PhosCity"
export script_namespace = "phos.qcreport"
export script_version = "1.0.3"

default_config =
  section: {"Timing", "Typesetting", "Editing"},
  itemTiming: { "Too much lead in.", "Too much lead out.", "Not enough lead in.", "Not enough lead out.", "Snap to keyframes.", "Link lines.", "Mouth flap." },
  itemTypesetting: { "Too much blur.", "Not enough blur.", "Color mismatch.", "Mask fail.", "Incorrect tracking.", "Missing sign.", "Incorrect position.",
  "Banding visible.", "Incorrect perspective.", "Font mismatch.", "Incorrect fade.", "Incorrect size." }
  itemEditing: {}

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl({})
config = depctrl\getConfigHandler(default_config, "config", false)
logger = depctrl\getLogger!

show_hour = false


config_setup = () ->
  config\load()
  opt = config.c

  value = table.concat opt.section, "\n"
  
  conf_dlg = {
		{ x: 0, y: 0, width: 1, height: 1, class: "label", label: "Add your sections below:", },
		{ x: 0, y: 1, width: 15, height: math.min(#opt.section+2, 5), class: "textbox", value: value, name: "section" },
	}

  for section in *opt.section
    items = [i for i in *opt["item"..section]]
    value = table.concat items, "\n"
    row = conf_dlg[#conf_dlg].y + conf_dlg[#conf_dlg].height
    conf_dlg[#conf_dlg+1] = { x: 0, y: row, width: 1, height: 1, class: "label", label: "Pre-made reports for #{section}", }
    conf_dlg[#conf_dlg+1] = { x: 0, y: row+1, width: 15, height: math.min(#items+2, 5), class: "textbox", value: value, name: "item"..section }

  buttons = { "Save", "Reset", "Cancel" }
  pressed, result = aegisub.dialog.display(conf_dlg, buttons)
  switch pressed
    when "Cancel" then aegisub.cancel!
    when "Save"
      section_tbl = {}
      for s in result["section"]\gmatch("[^\n]+")
        table.insert section_tbl, s

        opt["item"..s] = {}
        continue unless result["item"..s]
        for item in result["item"..s]\gmatch("[^\n]+")
          table.insert opt["item"..s], item

      opt.section = section_tbl
      config\write()
    when "Reset"
      opt.section = default_config.section
      config\write()


clear_notes = (subs, sel) ->
  to_delete = {}
  for i = 1, #subs do
    continue unless subs[i].class == "dialogue"
    line = subs[i]
    continue unless line.text\match "{%*%[.*%*}"
    line.text = line.text\gsub "{%*%[.*%*}", ""
    line.effect = line.effect\gsub "%[QC-[^%]]+%]", ""
    if line.text == "" then table.insert(to_delete, i)
    subs[i] = line
  subs.delete(to_delete)


create_gui = (opt) ->
  dlg = {}
  for index, item in ipairs opt.section
    dropdownitems = [item for item in *opt["item"..item]]
    dlg[#dlg+1] = {x: index-1, y: 0, class: "checkbox", label: item, name: item}
    dlg[#dlg+1] = {x: index-1, y: 1, class: "dropdown", items: dropdownitems, name: "item"..item, value: nil}

  dlg[#dlg+1] = {x: 0, y: 2, width: 2, height: 1, class: "label", label: "Write you notes below:"}
  dlg[#dlg+1] = {x: 16, y: 2, width: 2, height: 1, class: "checkbox", label: "Use video frame", name: "use_video", value: opt.use_video}
  dlg[#dlg+1] = {x: 0, y: 3, class: "textbox", name: "note", value: "", width: 18, height: 10}

  return dlg


-- This one uses video frame position to add notes
-- If the current frame has a line, then then the note will be added to that line
-- If the current frame has no line, then a new line with note will be inserted with current frame's time
useVideo = (subs, header, note) ->
  video_frame = aegisub.project_properties().video_position

  unless video_frame
    logger\log "Video is not loaded. Adding note to current selected line."
    return nil
  else
    time_frame = aegisub.ms_from_frame(video_frame)

    for i=1, #subs
      continue unless subs[i].class == "dialogue"
      line = subs[i]
      if time_frame > line.start_time and time_frame < line.end_time
        return i, {i}

    for i=1, #subs
      continue unless subs[i].class == "dialogue"
      line = subs[i]
      if line.start_time > time_frame
        line.text = "{*#{note}*}"
        line.start_time = time_frame
        line.end_time = time_frame
        line.effect = "[QC-#{header}]"
        subs[-i] = line
        return false, {i}


writeQC = (subs, sel, act) ->
  config\load()
  opt = config.c

  dlg = create_gui opt
  btn, res = aegisub.dialog.display dlg, {"Add Note", "Cancel"}, {"ok": "Add Note", "cancel": "Cancel"}

  opt.use_video = res["use_video"]
  config\write()

  if btn
    header = "Note"
    template = ""
    for section in *opt.section
      if res[section]
        header = section
        template = res["item"..section]

    note = res["note"]
    return if note == "" and template == ""
    note = "#{template} #{note}"

    note = note\gsub("\n", "\\N")\gsub("{", "[")\gsub("}", "]")
    note = "[#{header}] #{note}"

    -- If video_frame is chosen
    local new_index
    local new_sel
    if res["use_video"]
      new_index, new_sel = useVideo(subs, header, note)
      return new_sel unless new_index

    new_index or= act
    line = subs[new_index]
    line.text  ..= "{*#{note}*}"
    line.effect  ..= "[QC-#{header}]"
    subs[new_index] = line

    return new_sel


ms2timecode = (num) ->
  hh = math.floor((num / (60 * 60 * 1000)) % 24)
  mm = math.floor((num / (60 * 1000)) % 60)
  ss = math.floor((num / 1000) % 60)
  if show_hour
    return string.format("%01d:%02d:%02d", hh, mm, ss)
  else
    return string.format("%02d:%02d", mm, ss)


generate_QC = (subs, sel) ->
  maxTime = 0
  for i = 1, #subs
    continue unless subs[i].class == "dialogue"
    maxTime = math.max(subs[i].start_time, maxTime)
  show_hour = math.floor((maxTime/(60*60*1000))%24) > 0

  report = {}
  for i = 1, #subs do
    continue unless subs[i].class == "dialogue"
    line = subs[i]
    for qc in line.text\gmatch "{%*([^%*]+)%*}"
      section_header = qc\match "^%[([^%]]+)%].*"
      note = qc\gsub("#{section_header}", "")\gsub("[%[%]]", "")\gsub("^%s+", "")\gsub("\\N", "\n")
      note = ms2timecode(line.start_time).." - "..note
      report[section_header] or= {}
      table.insert(report[section_header], note)

  for k, v in pairs report
    logger\log "[#{k}]"
    for note in *v
      logger\log note
    logger\log " "


depctrl\registerMacros({
  { "Write QC", script_description, writeQC },
  { "Generate QC Report", script_description, generate_QC },
  { "Config", "Configuration for script", config_setup },
  { "Clear Notes", "Clear the notes", clear_notes },
})
