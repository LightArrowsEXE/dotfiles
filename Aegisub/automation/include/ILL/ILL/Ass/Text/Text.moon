import Util from require "ILL.ILL.Util"
import Tags from require "ILL.ILL.Ass.Text.Tags"
import Aegi from require "ILL.ILL.Aegi"

class Text

	set: (@text, isShape) =>
		local tagsBlocks, textBlocks, n

		-- checks if the text is a shape and if so,
		-- arrange it individually to avoid slowness
		if isShape
			-- tags and text layer
			tagsBlock = Tags text\match "%b{}"
			textBlock = text\gsub "%b{}", ""

			-- inserts the values to the layers
			tagsBlocks = {tagsBlock}
			textBlocks = {textBlock}
			n = 1
		else
			-- removes the useless spaces contained in the
			-- beginning and end of the text, and adds an
			-- empty tag layer if the text does not have a
			-- tag at the beginning
			text = text\match "^%s*(.-)%s*$"
			text = text\find("%b{}") != 1 and "{}" .. text or text

			-- gets the raw from the tag and text layers
			tagsBlocks = [Tags tags for tags in text\gmatch "%b{}"]
			textBlocks = Util.splitByPattern text, "%b{}"

			-- fixing the first situation
			-- situation: the function Util.splitByPattern returns a
			-- table that always contains an empty string value,
			-- so it must be removed if there are one or more
			-- tags in the text
			if #textBlocks > 1 and textBlocks[1] == ""
				table.remove textBlocks, 1

			-- correction of the second situation
			-- situation: libass completely ignores the final part
			-- of the text that simply has no text, even if it has tags,
			-- it will not change the final result, knowing this it is
			-- necessary to remove these tags or spaces that would only
			-- inder the process of obtaining metrics
			-- "{\fs1}ABC {\fs2}  {\fs3}  " --> "{\fs1}ABC "
			n = #textBlocks
			if #tagsBlocks - n == 1
				unless tagsBlocks[#tagsBlocks]\existsTagOr "an", "pos", "move", "org", "clip", "iclip", "fad", "fade"
					table.remove tagsBlocks
				else
					table.insert textBlocks, ""
				for i = n, 1, -1
					if Util.isBlank textBlocks[i]
						table.remove textBlocks
						table.remove tagsBlocks
					else
						break
			-- correction of the third situation
			-- situation: libass ignores whitespace at the beginning and end
			-- of the text, so that we don't have problems with metrics,
			-- we need to remove these spaces
			-- "{\fs1}   ABC  {\fs2}DEF    " --> "{\fs1}ABC  {\fs2}DEF"
			n = #textBlocks
			if n >= 1
				textBlocks[1] = textBlocks[1]\match "^%s*(.-%s*)$"
				if n > 1
					textBlocks[n] = textBlocks[n]\match "^(%s*.-)%s*$"

		-- sets values
		@tagsBlocks = tagsBlocks
		@textBlocks = textBlocks
		@n = n

	get: => @text

	new: (text, isShape) => @set text, isShape

	stripped: => @text\gsub "%b{}", ""

	update: =>
		@text = @__tostring!
		return @

	iter: =>
		i = 0
		{:tagsBlocks, :textBlocks, :n} = @
		->
			i += 1
			if i <= n
				return tagsBlocks[i], textBlocks[i], i, n

	callBack: (fn) =>
		{:tagsBlocks, :textBlocks, :n} = @
		for tags, text, i, n in @iter!
			tags, text = fn tags, text, i, n
			if tags and text
				tagsBlocks[i], textBlocks[i] = tags, text
		@update!

	-- modifies the value of the defined tag block
	modifyBlock: (newTags, newText, i = 1) =>
		@callBack (tags, text, j) ->
			if i == j
				return newTags, newText or text
		@update!

	-- tags known as first category tags can only appear once in a line,
	-- so to solve problems of repeated or misplaced tags, the functional
	-- tag is moved to the first tag block
	-- "{\fs200}AB{\pos(0,0)}C" --> "{\pos(0,0)\fs200}AB{}C"
	moveToFirstLayer: =>
		firstCategory = {an: {}, pos: {}, move: {}, org: {}, clip: {}, iclip: {}, fad: {}, fade: {}}
		@callBack (tags, text, i, n) ->
			for name, obj in pairs firstCategory
				tag = tags\getTag name
				if tag and not obj.value
					obj.value = tag.value
				if i > 1
					tags\animated "hide"
					tags\remove name
					tags\animated "unhide"
			return tags, text
		for name, obj in pairs firstCategory
			if v = obj.value
				@tagsBlocks[1]\insert {{name, v}, true}
		@update!

	-- inserts tags that do not exist in layers after the current layer
	-- "{\fs100}ABC{\bord0.5}DEF" --> "{\fs100}ABC{\fs100\bord0.5}DEF"
	insertPendingTags: (add_all = false, add_transforms = false) =>
		{:tagsBlocks, :n} = @
		for i = 2, n
			curr = tagsBlocks[i]
			prev = tagsBlocks[i - 1]\split!
			addt = ""
			for j = #prev, 1, -1
				{:raw, :name, :tag} = prev[j]
				unless curr\existsTag name
					if add_all
						addt = raw .. addt
					else
						unless tag.coords
							if name == "t" and not add_transforms
								continue
							addt = raw .. addt
			tagsBlocks[i]\insert {addt, true}
		@update!

	-- checks if the tag exists in the tags blocks
	existsTag: (...) =>
		for tags, text in @iter!
			if tags\existsTag ...
				return true
		return false

	-- checks if the tag exists in the tags blocks
	-- if any all tags exists returns true
	existsTagAnd: (...) =>
		for tags, text in @iter!
			if tags\existsTagAnd ...
				return true
		return false

	-- checks if the tag exists in the tags blocks
	-- if any of the tags exists returns true
	existsTagOr: (...) =>
		for tags, text in @iter!
			if tags\existsTagOr ...
				return true
		return false

	-- splits the text according to the positioning of the line breaks present in it
	getLineBreaks: (text) ->
		new = ""

		-- to make life easier for a human being the simplest way
		-- was to simply define the line break as a tag layer,
		-- so we can insert the pending tags in a simple way
		txt = text\gsub("\\N", "{\\N}")\gsub "\\i?clip%b()", ""
		txt = Text txt
		txt\insertPendingTags true

		-- now we have to make these line breaks come out
		-- from within the tag layers to split them later
		{:tagsBlocks, :textBlocks, :n} = txt
		for i = 1, n
			tagsBlock = tagsBlocks[i]
			textBlock = textBlocks[i]
			new ..= tostring(tagsBlock)\gsub("{(.-)\\N}", "\\N{%1}") .. textBlock
			-- new = new\gsub "}{", ""

		-- gets the line breaks
		breaks = Util.splitByPattern new, "\\N"
		n = #breaks

		return breaks, n

	__tostring: =>
		concat = ""
		for tags, text in @iter!
			concat ..= tostring(tags) .. text
		return concat

{:Text}