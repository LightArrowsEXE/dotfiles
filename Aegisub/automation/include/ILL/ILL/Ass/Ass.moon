import Table from require "ILL.ILL.Table"
import Util  from require "ILL.ILL.Util"
import Aegi  from require "ILL.ILL.Aegi"
import Text  from require "ILL.ILL.Ass.Text.Text"

class Ass

	set: (@sub, @sel, @activeLine, @remLine = true) =>
		-- sets the selection information
		@i, @fi, @newSelection = 0, 0, {}
		for l, i in @iterSub!
			if l.class == "dialogue"
				-- number of the first line of the dialog
				@fi = i
				break
		-- gets meta and styles values
		@collectHead!

	get: (index) => index and @[index] or @

	getActiveLine: => @activeLine

	new: (...) => @set ...

	-- iterates over all the lines of the ass file
	iterSub: (copy) =>
		i = 0
		n = #@sub
		->
			i += 1
			if i <= n
				l = @sub[i + @i]
				if l.class == "dialogue"
					l.isShape = Util.isShape l.text
				if copy
					if l.class == "dialogue"
						line = Table.deepcopy l
						unless l.isShape
							line.text = Text line.text, line.isShape
					return l, line, i, n
				return l, i, n

	-- iterates over all the selected lines of the ass file
	iterSel: (copy) =>
		i = 0
		n = #@sel
		->
			i += 1
			if i <= n
				s = @sel[i]
				l = @sub[s + @i]
				l.isShape = Util.isShape l.text
				if copy
					line = Table.deepcopy l
					unless l.isShape
						line.text = Text line.text, line.isShape
					return l, line, s, i, n
				return l, s, i, n

	-- gets the meta and styles values from the ass file
	collectHead: =>
		@meta, @styles = {res_x: 0, res_y: 0, video_x_correct_factor: 1}, {}
		for l in @iterSub!
			if aegisub.progress.is_cancelled!
				error "User cancelled", 2

			if l.class == "style"
				@styles[l.name] = l
			elseif l.class == "info"
				@meta[l.key\lower!] = l.value
			else
				break

		-- check if there are any styles present in the ass file
		if Table.isEmpty @styles
			error "ERROR: No styles were found in the file, bug?!", 2

		-- fix resolution data
		with @meta
			if pcall -> @sub.script_resolution
				.res_x, .res_y = @sub.script_resolution!
			else
				if .playresx
					.res_x = math.floor .playresx
				if .playresy
					.res_y = math.floor .playresy
				if .res_x == 0 and _res_y == 0
					.res_x = 384
					.res_y = 288
				elseif .res_x == 0
					if .res_y == 1024
						.res_x = 1280
					else
						.res_x = .res_y / 3 * 4
				elseif .res_y == 0
					if .res_x == 1280
						.res_y = 1024
					else
						.res_y = .res_x * 3 / 4

		video_x, video_y = aegisub.video_size!
		if video_y
			@meta.video_x_correct_factor = (video_y / video_x) / (@meta.res_y / @meta.res_x)

		Aegi.debug 4, "ILL: Video X correction factor = %f\n\n", @meta.video_x_correct_factor
		return @

	-- gets the real number of the current line
	lineNumber: (s) => s - @fi + 1

	-- sets the value of the line in the dialog
	setLine: (l, s) =>
		-- makes updating the text more dynamic
		instance = Ass.setText l
		-- sets the value of the line
		@sub[s + @i] = l
		if instance
			l.text = instance

	-- inserts a line in dialogs
	insertLine: (l, s) =>
		i = s + @i + 1
		-- makes updating the text more dynamic
		instance = Ass.setText l
		-- adds a dialogue line in subtitle
		@sub.insert i, l
		if instance
			l.text = instance
		-- inserts the index of this new line in the selected lines box
		table.insert @newSelection, i
		@i += 1
		@activeLine += 1

	-- removes a line in dialogs
	removeLine: (l, s) =>
		i = s + @i
		l.comment = true
		if Util.checkClass l.text, "Text"
			l.text = l.text\__tostring!
		@sub[i] = l
		l.comment = false
		if @remLine
			@sub.delete i
			@i -= 1
			@activeLine -= 1

	-- deletes a line in dialogs
	deleteLine: (l, s) => @removeLine l, s

	-- deletes a line or more in dialogs
	deleteLines: (l, ...) =>
		for i, n in ipairs type(...) == "table" and ... or {...}
			@deleteLine l, n

	-- gets the index values of the lines that were added
	getNewSelection: =>
		if #@newSelection > 0
			return @newSelection, @activeLine < @fi and 1 or @activeLine

	-- the subtitle that will appear on the progress screen
	progressLine: (s, i, n) =>
		Aegi.progressSet i, n
		Aegi.progressTask "Processing Line: #{@lineNumber s} - #{i} / #{n}"
		Aegi.progressCancelled!

	-- sets an error on the line
	error: (s, msg = "not specified") =>
		Aegi.debug 0, "———— [Error] ➔ Line #{@lineNumber s}\n"
		Aegi.debug 0, "—— [Cause] ➔ " .. msg .. "\n\n"
		Aegi.progressCancel!

	-- sets a warning on the line
	warning: (s, msg = "not specified") =>
		Aegi.debug 2, "———— [Warning] ➔ Line #{@lineNumber s} skipped\n"
		Aegi.debug 2, "—— [Cause] ➔ " .. msg .. "\n\n"

	-- sets the final value of the text
	setText: (l) ->
		if Util.checkClass l.text, "Text"
			if l.isShape
				l.text = l.tags\__tostring! .. l.shape
				return
			copyInstance = Table.copy l.text
			l.text = l.text\__tostring!
			return copyInstance
		elseif l.tags
			local tags
			if Util.checkClass l.tags, "Tags"
				tags = Table.copy l.tags
				tags\clear l.styleref
				tags = tags\__tostring!
			else
				tags = l.tags
			if l.isShape
				l.text = tags .. l.shape
			else
				l.text = tags .. l.text_stripped
		elseif l.isShape and l.shape
			l.text = l.shape

{:Ass}