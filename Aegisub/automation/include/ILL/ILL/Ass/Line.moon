-- https://github.com/Aegisub/Aegisub/blob/master/automation/include/karaskel-auto4.lua

-- Uses WinGDI and FreeType to capture metrics
-- This is a copy of "karaskel-auto4.lua" in order to further explore the metrics

import Aegi   from require "ILL.ILL.Aegi"
import Math   from require "ILL.ILL.Math"
import Table  from require "ILL.ILL.Table"
import Util   from require "ILL.ILL.Util"
import UTF8   from require "ILL.ILL.UTF8"
import Tags   from require "ILL.ILL.Ass.Text.Tags"
import Text   from require "ILL.ILL.Ass.Text.Text"
import Path   from require "ILL.ILL.Ass.Shape.Path"
import Font   from require "ILL.ILL.Font.Font"

class Line

	-- processes the line values by extending its information pool
	process: (ass, l) ->
		{:styles, :meta} = ass
		{:res_x, :res_y, :video_x_correct_factor} = meta

		if type(l.text) == "string"
			l.text = Text l.text

		if not l.data and not l.isShape
			l.text\moveToFirstLayer!

		with l
			.text_stripped = .text.textBlocks[1]\gsub "%b{}", ""
			.duration = .end_time - .start_time
			textIsBlank = Util.isBlank .text_stripped

			if not .styleref or .reset
				if styleValue = .reset and styles[.reset.name] or styles[.style]
					.styleref = Table.copy styleValue
				else
					Aegi.debug 2, "WARNING: Style not found: #{.style}\n"
					.styleref = Table.copy styles[next styles]

				-- gets the alpha and color values separately
				.styleref.alpha  = "&H00&"
				.styleref.alpha1 = Util.convertColor "alpha_fs", .styleref.color1
				.styleref.alpha2 = Util.convertColor "alpha_fs", .styleref.color2
				.styleref.alpha3 = Util.convertColor "alpha_fs", .styleref.color3
				.styleref.alpha4 = Util.convertColor "alpha_fs", .styleref.color4
				.styleref.color1 = Util.convertColor "color_fs", .styleref.color1
				.styleref.color2 = Util.convertColor "color_fs", .styleref.color2
				.styleref.color3 = Util.convertColor "color_fs", .styleref.color3
				.styleref.color4 = Util.convertColor "color_fs", .styleref.color4

				-- adds tag values that are not part of the default style composition
				.data = Table.copy .styleref
				for tag, data in pairs ASS_TAGS
					{:style_name, :typer, :value} = data
					unless style_name or typer == "coords"
						.data[tag] = value

			-- sets the values found in the tags to the style
			.tags or= Tags .text.tagsBlocks[1]\get!
			for {:tag, :name} in *.tags\split!
				{:style_name, :value} = tag
				if style_name
					.data[style_name] = value
				elseif .isShape or .data[name]
					.data[name] = value

			-- as some tags can only appear once this avoids unnecessary
			-- capture repetitions which minimizes processing
			unless .reset
				values = Line.firstCategoryTags l, res_x, res_y
				for k, v in pairs values
					.data[k] = v
			else
				for name in *{"an", "pos", "move", "org", "fad", "fade"}
					if value = .reset.data[name]
						.data[name] = value

			font = Font .data

			-- if it's a shape, this information are irrelevant
			unless .isShape
				-- gets the value of the width of a space
				.space_width = font\getTextExtents(" ").width
				.space_width *= video_x_correct_factor

				-- spaces that are on the left and right of the text
				.prevspace = .text_stripped\match("^(%s*).-%s*$")\len! * .space_width
				.postspace = .text_stripped\match("^%s*.-(%s*)$")\len! * .space_width

				-- removes the spaces between the text
				unless textIsBlank
					.text_stripped = .text_stripped\match "^%s*(.-)%s*$"
			else
				-- to make everything more dynamic
				.shape = .text_stripped
				.text_stripped = ""
				.prevspace = 0
				.postspace = 0

			-- gets the metric values of the text
			if textIsBlank
				textExtents = font\getTextExtents " "
				textMetrics = font\getMetrics!
				.width = 0
				.height = textExtents.height
				.ascent = textMetrics.ascent
				.descent = textMetrics.descent
			else
				textValue = ""
				unless .isShape
					textValue = .text_stripped\gsub "\\h", " "
					.text_stripped = textValue
				textExtents = font\getTextExtents textValue
				textMetrics = font\getMetrics!
				.width = textExtents.width * video_x_correct_factor
				.height = textExtents.height
				.ascent = textMetrics.ascent
				.descent = textMetrics.descent
				.internal_leading = textMetrics.internal_leading
				.external_leading = textMetrics.external_leading

			-- text alignment
			{:an} = .data

			-- effective margins
			.eff_margin_l = .margin_l > 0 and .margin_l or .data.margin_l
			.eff_margin_r = .margin_r > 0 and .margin_r or .data.margin_r
			.eff_margin_t = .margin_t > 0 and .margin_t or .data.margin_t
			.eff_margin_b = .margin_b > 0 and .margin_b or .data.margin_b
			.eff_margin_v = .margin_t > 0 and .margin_t or .data.margin_v

			-- X-axis alignment
			switch an
				when 1, 4, 7
					-- Left aligned
					.left = .eff_margin_l
					.center = .left + .width / 2
					.right = .left + .width
					.x = .left
				when 2, 5, 8
					-- Centered aligned
					.left = (res_x - .eff_margin_l - .eff_margin_r - .width) / 2 + .eff_margin_l
					.center = .left + .width / 2
					.right = .left + .width
					.x = .center
				when 3, 6, 9
					-- Right aligned
					.left = res_x - .eff_margin_r - .width
					.center = .left + .width / 2
					.right = .left + .width
					.x = .right

			-- Y-axis alignment
			switch an
				when 7, 8, 9
					-- Top aligned
					.top = .eff_margin_t
					.middle = .top + .height / 2
					.bottom = .top + .height
					.y = .top
				when 4, 5, 6
					-- Mid aligned
					.top = (res_y - .eff_margin_t - .eff_margin_b - .height) / 2 + .eff_margin_t
					.middle = .top + .height / 2
					.bottom = .top + .height
					.y = .middle
				when 1, 2, 3
					-- Bottom aligned
					.bottom = res_y - .eff_margin_b
					.middle = .bottom - .height / 2
					.top = .bottom - .height
					.y = .bottom

	-- gets all the data values from the tags blocks
	tagsBlocks: (ass, l, noblank = false) ->
		data = {width: 0, height: 0, n: 0}

		unless l.data
			Line.process ass, l

		-- text alignment
		{:an} = l.data
		l.data.clip = nil
		l.data.iclip = nil

		-- the values will be used as an aid to obtain the correct metrics
		left, ascent, descent = 0, 0, 0

		for tags, text in l.text\iter!
			line = Table.copy l

			line.text_stripped = text
			line.tags = tags\clean!
			line.text = Text line.tags\__tostring! .. line.text_stripped
			line.text.textBlocks[1] = line.text_stripped

			-- support for the \r tag in line processing
			if reset = line.tags\getTag "r"
				line.reset = {data: l.data, name: reset.tag.value}

			-- extends the values of each tag layer
			Line.process ass, line

			-- adds the real height and width values of the line
			data.width += line.width + line.prevspace + line.postspace
			ascent = math.max ascent, line.height - line.descent
			descent = math.max descent, line.descent
			data.height = math.max data.height, ascent + descent

			-- updates the style value for the next line
			l.data = line.data

			-- inserts the processed line into the table data
			data.n += 1
			data[data.n] = line

		-- copies the values from the original data
		dataNoblank = {width: data.width, height: data.height, n: 0}

		-- fixes the positioning of tag blocks in relation to the rendered text
		for line in *data

			-- sums with the previous space values
			left += line.prevspace

			offsetX = left + line.left
			line.x = switch an
				when 1, 4, 7 then offsetX
				when 2, 5, 8 then offsetX + line.width - data.width / 2
				when 3, 6, 9 then offsetX + line.width * 2 - data.width

			offsetY = descent - line.descent
			line.y = switch an
				when 7, 8, 9 then line.top - offsetY + data.height - line.height
				when 4, 5, 6 then line.middle - offsetY + (data.height - line.height) / 2
				when 1, 2, 3 then line.bottom - offsetY

			-- sums with the post space values
			left += line.postspace + line.width

			-- ignores blanks
			unless noblank and Util.isBlank line.text_stripped
				dataNoblank.n += 1
				dataNoblank[dataNoblank.n] = line

		return noblank and dataNoblank or data

	-- gets all the data values from the line breaks
	lineBreaks: (ass, l, noblank = false) ->
		data = {width: 0, height: 0, n: 0}

		unless l.data
			Line.process ass, l

		-- text alignment
		{:an} = l.data

		-- gets the texts between line breaks
		brk, n = Text.getLineBreaks l.text\get!

		for i = 1, n
			text = brk[i]

			line = Table.copy l
			line.text = Text text
			line.data.clip = nil
			line.data.iclip = nil

			-- processes the values of the tags blocks at the line break
			lines = Line.tagsBlocks ass, line, noblank
			lines.text_stripped = text\gsub "%b{}", ""

			-- gets the real value of the width
			data.width = math.max data.width, lines.width

			-- inserts the processed line into the table data
			data.n += 1
			data[data.n] = lines

		offsetHeightA, heightA = {}, 0
		offsetHeightB, heightB = {}, 0
		for i = 1, n
			j = n - i + 1

			-- current line break and reverse current line break
			linesA, linesB = data[i], data[j]

			-- adds the value of the current line break height value
			offsetHeightA[i] = heightA
			offsetHeightB[j] = heightB

			-- gets the value of the height of the next line break 
			heightA += linesA.text_stripped == "" and linesA.height / 2 or linesA.height
			heightB += linesB.text_stripped == "" and linesB.height / 2 or linesB.height

		-- gets the real value of the height
		data.height = heightA
 
		-- copies the values from the original data
		dataNoblank = {width: data.width, height: data.height, n: 0}

		-- fixes the positioning of line breaks in relation to the rendered text
		for i = 1, n
			lines, a, b = data[i], offsetHeightA[i], offsetHeightB[i]
			for line in *lines
				line.y = switch an
					when 7, 8, 9 then line.y + a
					when 4, 5, 6 then line.y + (a - b) / 2
					when 1, 2, 3 then line.y - b

			-- ignores blanks
			unless noblank and Util.isBlank lines.text_stripped
				dataNoblank.n += 1
				dataNoblank[dataNoblank.n] = lines

		return noblank and dataNoblank or data

	-- adds all possible information to the line
	extend: (ass, l, noblank = true) ->
		Line.process ass, l
		unless l.isShape
			l.lines = Line.lineBreaks ass, l, noblank
			l.extended = true

	-- updates line information
	update: (ass, l, noblank) ->
		l.lines = nil
		l.data = nil
		l.styleref = nil
		l.extended = false
		l.text = l.text\__tostring!
		Line.extend ass, l, noblank

	-- splits the text word by word
	words: (ass, l, noblank = false) ->
		if l.extended
			words = {n: 0}
			for i = 1, l.lines.n
				lineBreak = l.lines[i]
				left = switch l.data.an
					when 1, 4, 7 then l.eff_margin_l
					when 2, 5, 8 then (ass.meta.res_x - l.eff_margin_l - l.eff_margin_r - lineBreak.width) / 2 + l.eff_margin_l
					when 3, 6, 9 then ass.meta.res_x - l.eff_margin_r - lineBreak.width
				for j = 1, lineBreak.n
					lineTags = lineBreak[j]
					lineTagsText = lineTags.text_stripped
					lineTagsTags = lineTags.tags\get!
					wordText, k = "", 1
					while k <= #lineTagsText
						s = lineTagsText\sub k, k
						if s\match "%s"
							wordText = lineTagsText\match "(%s+)", k
							k += #wordText
						else
							wordText = lineTagsText\match "(%S+)", k
							k += #wordText
						word = Table.copy lineTags
						word.tags = Tags lineTagsTags
						word.text = Text wordText
						word.text.tagsBlocks[1] = Tags lineTagsTags
						word.text_stripped = wordText
						font = Font word.data
						textExtents = font\getTextExtents wordText
						word.width = textExtents.width * ass.meta.video_x_correct_factor
						word.left = left
						word.center = left + word.width * 0.5
						word.right = left + word.width
						word.top = lineTags.top
						word.middle = lineTags.middle
						word.bottom = lineTags.bottom
						word.x = switch l.data.an
							when 1, 4, 7 then word.left
							when 2, 5, 8 then word.center
							when 3, 6, 9 then word.right
						word.y = lineTags.y
						left += word.width
						words.n += 1
						words[words.n] = word
					left += lineTags.postspace
			if noblank
				wordsNoblank = {n: 0}
				for word in *words
					unless Util.isBlank word.text_stripped
						wordsNoblank.n += 1
						wordsNoblank[wordsNoblank.n] = word
				return wordsNoblank
			return words
		else
			error "You have to extend the line before you get the words", 2

	-- splits the text character by character
	chars: (ass, l, noblank = false) ->
		if l.extended
			chars = {n: 0}
			for i = 1, l.lines.n
				lineBreak = l.lines[i]
				left = switch l.data.an
					when 1, 4, 7 then l.eff_margin_l
					when 2, 5, 8 then (ass.meta.res_x - l.eff_margin_l - l.eff_margin_r - lineBreak.width) / 2 + l.eff_margin_l
					when 3, 6, 9 then ass.meta.res_x - l.eff_margin_r - lineBreak.width
				for j = 1, lineBreak.n
					lineTags = lineBreak[j]
					lineTagsText = lineTags.text_stripped
					lineTagsTags = lineTags.tags\get!
					for ci, charText in UTF8(lineTagsText)\chars!
						char = Table.copy lineTags
						char.tags = Tags lineTagsTags
						char.text = Text charText
						char.text.tagsBlocks[1] = Tags lineTagsTags
						char.text_stripped = charText
						font = Font char.data
						textExtents = font\getTextExtents charText
						char.width = textExtents.width * ass.meta.video_x_correct_factor
						char.left = left
						char.center = left + char.width * 0.5
						char.right = left + char.width
						char.top = lineTags.top
						char.middle = lineTags.middle
						char.bottom = lineTags.bottom
						char.x = switch l.data.an
							when 1, 4, 7 then char.left
							when 2, 5, 8 then char.center
							when 3, 6, 9 then char.right
						char.y = lineTags.y
						left += char.width
						chars.n += 1
						chars[chars.n] = char
					left += lineTags.postspace
			if noblank
				charsNoblank = {n: 0}
				for char in *chars
					unless Util.isBlank char.text_stripped
						charsNoblank.n += 1
						charsNoblank[charsNoblank.n] = char
				return charsNoblank
			return chars
		else
			error "You have to extend the line before you get the characters", 2

	-- splits the text line break by line break
	breaks: (ass, l, noblank = false) ->
		if l.extended
			lines = {n: 0}
			for line in *l.lines
				lineBreak = Table.copy line[1]
				newBreakText = ""
				for i = 1, line.n
					newBreakTags = Table.copy line[i].tags
					if i > 1
						newBreakTags\difference line[i-1].tags
					newBreakText ..= newBreakTags\get! .. line[i].text.textBlocks[1]
					lineBreak.y = math.max line[i].y, lineBreak.y
				lineBreak.text = Text newBreakText
				lineBreak.tags = Tags lineBreak.text.tagsBlocks[1]\get!
				lineBreak.text_stripped = newBreakText
				left = switch l.data.an
					when 1, 4, 7 then l.eff_margin_l
					when 2, 5, 8 then (ass.meta.res_x - l.eff_margin_l - l.eff_margin_r - lineBreak.width) / 2 + l.eff_margin_l
					when 3, 6, 9 then ass.meta.res_x - l.eff_margin_r - lineBreak.width
				lineBreak.x = switch l.data.an
					when 1, 4, 7 then left
					when 2, 5, 8 then left + lineBreak.width * 0.5
					when 3, 6, 9 then left + lineBreak.width
				lines.n += 1
				lines[lines.n] = lineBreak
			if noblank
				linesNoblank = {n: 0}
				for line in *lines
					unless Util.isBlank line.text_stripped
						linesNoblank.n += 1
						linesNoblank[linesNoblank.n] = line
				return linesNoblank
			return lines
		else
			error "You have to extend the line before you get the breaks", 2

	-- splits the text tags blocks by tags blocks
	tags: (ass, l, noblank = false) ->
		if l.extended
			lines = {n: 0}
			for line in *l.lines
				for lineTags in *line
					lines.n += 1
					lines[lines.n] = Table.copy lineTags
			if noblank
				linesNoblank = {n: 0}
				for line in *lines
					unless Util.isBlank line.text_stripped
						linesNoblank.n += 1
						linesNoblank[linesNoblank.n] = line
				return linesNoblank
			return lines
		else
			error "You have to extend the line before you get the tags", 2

	-- callback to access the line values frame by frame
	callBackFBF: (ass, l, fn) ->
		-- gets the line data
		{:data, :start_time, :end_time, :duration} = l
		-- interpolates all the tags contained in the \t tag
		lerpTagTransform = (currTime, data, tags) ->
			{:insert} = table
			while true
				if tr = tags\getTag "t"
					{:s, :e, :a} = tr.tag.value
					s or= 0
					e or= duration
					t = Util.getTimeInInterval currTime, s, e, a
					lerp, values = "", Tags(tr.tag.value.transform)\split!
					for i = 1, #values
						{:name, :tag} = values[i]
						if tag.transformable
							if tags\existsTag name
								tags\remove name
							name = tag.style_name and tag.style_name or name
							v1, v2, result = data[name], tag.value, nil
							unless name == "clip" or name == "iclip"
								result = Util.interpolation t, nil, v1, v2
								if type(result) == "number"
									result = Math.round result, 2
								data[name] = result
							else
								-- if is a rectangular clip
								if type(v1) == "table" and type(v2) == "table"
									{l1, t1, r1, b1} = v1
									{l2, t2, r2, b2} = v2
									data[name][1] = Math.round Util.interpolation(t, "number", l1, l2), 2
									data[name][2] = Math.round Util.interpolation(t, "number", t1, t2), 2
									data[name][3] = Math.round Util.interpolation(t, "number", r1, r2), 2
									data[name][4] = Math.round Util.interpolation(t, "number", b1, b2), 2
									result = "(#{data[name][1]},#{data[name][2]},#{data[name][3]},#{data[name][4]})"
								else
									-- if is a vector clip --> yes it works
									data[name] = "#{Util.interpolation t, "shape", v1, v2}"
									result = "(#{data[name]})"
							lerp ..= tag.ass .. result
					tags\remove {"t", lerp, 1}
				else
					break
		-- interpolates between the start and end coordinates of the \move tag
		lerpTagMove = (currTime, data, tags) ->
			if tags\existsTag "move"
				x, y = Util.getTagMove currTime, duration, unpack data.move
				data.pos[1] = x
				data.pos[2] = y
				data.move = nil
				tags\remove {"move", "\\pos(#{x},#{y})"}
		-- interpolates the value of the \fad or \fade tag given the initial value of alpha
		lerpTagFade = (currTime, data, tags) ->
			if fade = data.fad or data.fade
				value = 0
				if alpha = tags\getTag "alpha"
					value = tonumber alpha.tag.value\match("%x%x"), 16
				data.alpha = ("&H%02X&")\format Util.getTagFade currTime, duration, value, unpack fade
				if tags\existsTag "fad"
					tags\remove "alpha", {"fad", "\\alpha#{data.alpha}"}
				elseif tags\existsTag "fade"
					tags\remove "alpha", {"fade", "\\alpha#{data.alpha}"}
				elseif tags\existsTag "alpha"
					tags\remove {"alpha", "\\alpha#{data.alpha}"}
		-- gets the start and end time values in frames
		stt_frame = Aegi.ffm start_time
		end_frame = Aegi.ffm end_time
		j = 0
		n = end_frame - stt_frame
		-- iterates over all the identified frames
		for i = stt_frame, end_frame - 1
			s = Aegi.mff i
			e = Aegi.mff i + 1
			f = math.floor((s + e) / 2) - start_time
			dado = Table.copy data
			line = Table.copy l
			line.start_time = s
			line.end_time = e
			line.duration = e - s
			unless l.isShape
				line.text\callBack (tags, text, j) ->
					if j == 1
						lerpTagMove f, dado, tags
					lerpTagTransform f, dado, tags
					lerpTagFade f, dado, tags
					return tags, text
			else
				lerpTagMove f, dado, line.tags
				lerpTagTransform f, dado, line.tags
				lerpTagFade f, dado, line.tags
			j += 1
			fn line, i, end_frame, j, n

	-- callback to map between all possible lines of text
	callBackTags: (ass, l, fn) ->
		unless l.isShape
			{:clip, :isIclip} = l.data
			j, isMove = 0, l.tags\existsTag "move"
			for lineBreak in *l.lines
				for lineBlock in *lineBreak
					j += 1
					-- gets the new position of the text
					lineBlock.text_stripped = lineBlock.text_stripped\gsub "\\h", " "
					lineBlock.data.pos = Line.reallocate l, lineBlock
					if isMove
						lineBlock.tags\insert {{"move", Line.reallocate l, lineBlock, true}, true}
					else
						lineBlock.tags\insert {{"pos", lineBlock.data.pos}, true}
					-- adds the values \clip or \iclip to all tag blocks
					if clip
						lineBlock.tags\insert {{isIclip and "iclip" or "clip", clip}}
					fn lineBlock, j

	-- callback to access the shapes
	callBackShape: (ass, l, fn) ->
		line = Table.copy l
		-- gets the line data
		{:data} = line
		if line.isShape
			-- makes the process of expanding shape
			line.shape = Path(line.shape)\reallocate(line.data.an)\export!
			-- removes unnecessary tags
			unless line.tags\existsTag "move"
				line.tags\insert {{"pos", data.pos}, true}
			fn line, 1
		else
			Line.callBackTags ass, line, (lineBlock, j) ->
				-- converts the text to shape and then converts the shape to Path
				newShape = Line.toPath lineBlock
				newShape\reallocate line.data.an, {width: lineBlock.width, height: lineBlock.height}
				-- fixes the scale interference in the function expand
				lineBlock.styleref.scale_x = 100
				lineBlock.styleref.scale_y = 100
				-- adds the shape properties to the lineBlock
				lineBlock.shape = newShape\export!
				lineBlock.isShape = true
				lineBlock.tags\remove "font"
				lineBlock.tags\insert {{"an", 7}, true}, "\\fscx100\\fscy100\\p1"
				fn lineBlock, j

	-- callback to access the shapes already expanded
	callBackExpand: (ass, l, grid, fn) ->
		line = Table.copy l
		-- gets the line data
		{:data} = line
		if line.isShape
			-- makes the process of expanding shape
			newShape = Path line.shape
			if grid
				{x, y} = line.data.pos
				path, colDistance, rowDistance = newShape\envelopeGrid unpack grid
				line.grid = {:path, :colDistance, :rowDistance}
				Line.expand line.grid.path, line
				line.grid.path\move x, y
			Line.expand newShape, line
			-- updates the value of the shape in the variable
			line.shape = newShape\export!
			-- removes unnecessary tags
			line.tags\remove "perspective", "p"
			unless line.tags\existsTag "move"
				line.tags\insert {{"pos", data.pos}, true}
			line.tags\insert {{"an", 7}, true}, "\\fscx100\\fscy100\\frz0\\p1"
			fn line, 1
		else
			Line.callBackTags ass, line, (lineBlock, j) ->
				-- save old values
				{:scale_x, :scale_y} = lineBlock.data
				{:height} = lineBlock
				-- sets new values
				lineBlock.data.scale_x = 100
				lineBlock.data.scale_y = 100
				font = Font lineBlock.data
				textExtents = font\getTextExtents lineBlock.text_stripped
				lineBlock.width = textExtents.width
				lineBlock.height = textExtents.height
				-- converts the text to shape and then converts the shape to Path
				newShape = Line.toPath lineBlock
				-- makes the process of expanding shape
				lineBlock.data.scale_x = scale_x
				lineBlock.data.scale_y = scale_y
				if grid
					{x, y} = lineBlock.data.pos
					path, colDistance, rowDistance = newShape\envelopeGrid unpack grid
					lineBlock.grid = {:path, :colDistance, :rowDistance}
					Line.expand lineBlock.grid.path, lineBlock, height
					lineBlock.grid.path\move x, y
				Line.expand newShape, lineBlock, height
				-- adds the shape properties to the lineBlock
				lineBlock.shape = newShape\export!
				lineBlock.isShape = true
				lineBlock.tags\remove "font", "perspective", "p", "r"
				lineBlock.tags\insert {{"an", 7}, true}, "\\fscx100\\fscy100\\frz0\\p1"
				fn lineBlock, j

	-- gets the values of the first category tags
	firstCategoryTags: (l, res_x, res_y) ->
		values = {["an"]: l.styleref.align}
		for name in *{"an", "pos", "move", "org", "clip", "iclip", "fad", "fade"}
			if value = l.tags\getTag name
				values[name] = value\getValue!
		-- checks if the \iclip tag exists
		if values["iclip"]
			values["clip"] = Table.copy values["iclip"]
			values["isIclip"] = true
		-- if there is no value of \pos
		unless values["pos"]
			-- if there is a \move
			if values["move"]
				{x, y} = values["move"]
				values["pos"] = {x, y}
			else
				{:margin_l, :margin_r, :margin_t} = l.styleref
				{:an} = values
				-- Axis-X
				x = switch an
					when 1, 4, 7 then margin_l
					when 2, 5, 8 then (res_x - margin_r + margin_l) / 2
					when 3, 6, 9 then res_x - margin_r
				-- Axis-Y
				y = switch an
					when 1, 2, 3 then res_y - margin_t
					when 4, 5, 6 then res_y / 2
					when 7, 8, 9 then margin_t
				values["pos"] = {x, y}
		-- if there is no value of \org
		unless values["org"]
			{x, y} = values["pos"]
			values["org"] = {x, y}
		return values

	-- changes the text alignment
	changeAlign: (l, an, width, height) ->
		-- gets the width and height of the text or shape
		unless width and height
			if l.isShape
				{:width, :height} = Path(l.shape)\boundingBox!
			else
				{:width, :height} = l.lines
		-- value of the bounding box center
		cx, cy = width * 0.5, height * 0.5
		-- offset axis-x
		ox = switch l.data.an
			when 1, 4, 7
				switch an
					when 1, 4, 7 then 0
					when 2, 5, 8 then cx
					when 3, 6, 9 then width
			when 2, 5, 8
				switch an
					when 1, 4, 7 then -cx
					when 2, 5, 8 then 0
					when 3, 6, 9 then cx
			when 3, 6, 9
				switch an
					when 1, 4, 7 then -width
					when 2, 5, 8 then -cx
					when 3, 6, 9 then 0
		-- offset axis-y
		oy = switch l.data.an
			when 7, 8, 9
				switch an
					when 7, 8, 9 then 0
					when 4, 5, 6 then cy
					when 1, 2, 3 then height
			when 4, 5, 6
				switch an
					when 7, 8, 9 then -cy
					when 4, 5, 6 then 0
					when 1, 2, 3 then cy
			when 1, 2, 3
				switch an
					when 7, 8, 9 then -height
					when 4, 5, 6 then -cy
					when 1, 2, 3 then 0
		-- if necessary insert the tag \org
		fr = l.data.angle != 0
		if l.isShape
			if fr or l.tags\existsTagOr "frx", "fry", "frz"
				l.tags\insert {{"org", l.data.org}, true}
		else
			if fr or l.text\existsTagOr "frx", "fry", "frz"
				l.tags\insert {{"org", l.data.org}, true}
		-- changes the value of the current alignment to the new one
		l.tags\insert {{"an", an}, true}
		unless l.isShape
			l.text\modifyBlock l.tags
		-- if the \move tag exists change its value
		with l.data
			if l.tags\existsTag "move"
				.move[1] += Math.round ox
				.move[2] += Math.round oy
				.move[3] += Math.round ox
				.move[4] += Math.round oy
				l.tags\insert {{"move", .move}, true}
			else
				-- change the value of the \pos tag
				.pos[1] += Math.round ox
				.pos[2] += Math.round oy
				l.tags\insert {{"pos", .pos}, true}

	-- reallocates the coordinate value given to the original line and a different one
	reallocate: (lineA, lineB, isMove) ->
		round = Math.round
		if isMove
			{x1, y1, x2, y2, t1, t2} = lineA.data.move
			x1 = round lineB.x - lineA.x + x1
			y1 = round lineB.y - lineA.y + y1
			x2 = round lineB.x - lineA.x + x2
			y2 = round lineB.y - lineA.y + y2
			return {x1, y1, x2, y2, t1, t2}
		-- \pos
		{x1, y1} = lineA.data.pos
		x1 = round lineB.x - lineA.x + x1
		y1 = round lineB.y - lineA.y + y1
		return {x1, y1}

	-- fixes the values of the shadow tag axes
	solveShadow: (l) ->
		{:xshad, :yshad, :shadow} = l.data
		-- gets the information from the defined tags
		a = l.tags\getTag "xshad"
		b = l.tags\getTag "yshad"
		c = l.tags\getTag "shad"
		-- this will fix the x and y values of the shading tags
		-- first it checks if the tag xshad and yshad exist
		-- if either or both of them exist,
		-- it is checked if they appear before the shad tag
		-- if the tag shad exists and it is in front of them
		-- the value of xshad or yshad is replaced by the value of shad
		xshad = a and (c and (a.i < c.i and shadow) or xshad) or shadow
		yshad = b and (c and (b.i < c.i and shadow) or yshad) or shadow
		return xshad, yshad

	-- expand the appearence of path and remove all tags
	expand: (path, l, oldHeight) ->
		dist = 312.5

		{:pi, :rad, :sin, :cos, :max} = math
		{:an, :pos, :org, :fax, :fay, :frx, :fry, :angle, :scale_x, :scale_y, :xshad, :yshad, :p} = l.data
		{:width, :height, :isShape} = l

		if isShape
			path\reallocate an
			{:height} = path\boundingBox!
		else
			path\reallocate an, {:width, :height}
			height = oldHeight or height

		asc = switch an
			when 1, 2, 3 then height
			when 4, 5, 6 then height * 0.5
			else 0

		frx = rad frx
		fry = rad fry
		frz = rad angle

		sx, cx = -sin(frx), cos(frx)
		sy, cy =  sin(fry), cos(fry)
		sz, cz = -sin(frz), cos(frz)

		p = 1 / (2 ^ (p - 1))
		scale_x = (scale_x / 100) * p
		scale_y = (scale_y / 100) * p

		fax *= scale_x / scale_y
		fay *= scale_y / scale_x

		xshad, yshad = Line.solveShadow l

		x1 = {1, fax, pos[1] - org[1] + xshad + asc * fax}
		y1 = {fay, 1, pos[2] - org[2] + yshad}

		offs_x = org[1] - pos[1] - xshad
		offs_y = org[2] - pos[2] - yshad

		a, b, c = {}, {}, {}
		for i = 1, 3
			x2 = x1[i] * cz - y1[i] * sz
			y2 = x1[i] * sz + y1[i] * cz

			y3 = y2 * cx
			z3 = y2 * sx

			x4 = x2 * cy - z3 * sy
			z4 = x2 * sy + z3 * cy
			z4 += i == 3 and dist or 0

			a[i] = z4 * offs_x + x4 * dist
			b[i] = z4 * offs_y + y3 * dist
			c[i] = z4

		path\map (x, y) ->
			spx = x * scale_x
			spy = y * scale_y

			x = (a[1] * spx) + (a[2] * spy) + a[3]
			y = (b[1] * spx) + (b[2] * spy) + b[3]
			z = (c[1] * spx) + (c[2] * spy) + c[3]

			w = 1 / max z, 0.1
			return x * w, y * w

	-- converts the text to shape
	toShape: (l) -> Font(l.data)\getTextToShape l.text_stripped

	-- converts the text to Path
	toPath: (l) -> Path Line.toShape l

{:Line}