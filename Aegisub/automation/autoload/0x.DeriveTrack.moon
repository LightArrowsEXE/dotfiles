require 'karaskel'

check_cancel = () ->
	if aegisub.progress.is_cancelled!
		aegisub.cancel!

main = (subs, sel, active) ->
	meta, styles = karaskel.collect_head subs, false

	positions = {}
	scales = {}
	rotations = {}

	for i in *sel
		line = subs[i]
		style = styles[line.style]

		insert = (t, v) ->

		local pos, fscx, fscy, frz
		for block in line.text\gmatch '{.-}'
			if pos_tag = block\match '\\pos%([0-9.-]+,[0-9.-]+%)'
				x, y = pos_tag\match '([0-9.-]+),([0-9.-]+)'
				pos = {x: x, y: y}

			fscx = block\match('\\fscx([0-9.-]+)')
			fscy = block\match('\\fscy([0-9.-]+)')
			frz = block\match('\\frz([0-9.-]+)')

		if pos == nil
			aegisub.log 'missing pos tag\n'
		fscx or= style.scale_x
		fscy or= style.scale_y
		frz or= style.angle

		start_frame = aegisub.frame_from_ms line.start_time
		end_frame = aegisub.frame_from_ms line.end_time
		for _ = start_frame, end_frame - 1
			table.insert positions, pos
			table.insert scales, {x: fscx, y: fscy}
			table.insert rotations, frz
	
	data = {}
	println = (fmt, ...) -> table.insert data, string.format(fmt or '', ...)
	println 'Adobe After Effects 6.0 Keyframe Data'
	println ''
	println '\tUnits per Second\t23.976'
	println '\tSource Width\t%d', meta.res_x
	println '\tSource Height\t%d', meta.res_y
	println '\tSource Pixel Aspect Ratio\t1'
	println '\tComp Pixel Aspect Ratio\t1'
	println ''

	println 'Position'
	println '\tFrame\tX pixels\tY pixels\tZ pixels'
	for i, pos in ipairs positions
		println '\t%d\t%f\t%f\t0', i - 1, pos.x, pos.y
	
	println ''
	println 'Scale'
	println '\tFrame\tX percent\tY percent\tZ percent'
	for i, scale in ipairs scales
		println '\t%d\t%f\t%f\t0', i - 1, scale.x, scale.y
	
	println ''
	println 'Rotation'
	println '\tFrame\tDegrees'
	for i, rotation in ipairs rotations
		println '\t%d\t%f', i - 1, -rotation

	result = table.concat data, '\n'

	aegisub.log result

validate = (subs, sel, _active) ->
	-- tag blocks' contents can (and probably will) change, but their presence shouldn't
	strip = (line) -> line.text\gsub '{.-}', '{}'

	-- no meaningful derivation if there isn't a selection of multiple lines
	return false if #sel < 2

	for i = 2, #sel
		i0, i1 = sel[i - 1], sel[i]
		line0, line1 = subs[i0], subs[i1]
		if strip(line0) != strip(line1) or
		   line0.end_time != line1.start_time or
		   line0.layer != line1.layer or
		   line0.comment != line1.comment
				return false

	return true

aegisub.register_macro 'Aegisub-Motion/Derive', 'Attempt to derive motion tracking data from tracked lines', main, validate
