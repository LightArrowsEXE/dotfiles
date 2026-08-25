export script_name = '0x539\'s Templater'
export script_description = ''
export script_author = 'The0x539'
export script_version = '0.1.0'
export script_namespace = '0x.KaraTemplater'

require 'karaskel'

try_import = (name) ->
	success, module = pcall require, name
	if not success
		-- Create a dummy table that exists, but gives an informative error when accessed.
		accessor = () ->
			-- I cannot for the life of me figure out why no matter what value I pass
			-- as the second argument to `error`, the log window still shows a full stack trace.
			-- This is absurd.
			aegisub.log 0, "This template depends on the `#{name}` module. Please install it."
			aegisub.cancel!

		module = setmetatable {}, {__index: accessor, __newindex: accessor}
	module, success

local print_stacktrace

karaOK, USE_KARAOK = try_import 'ln.kara'
colorlib, USE_COLOR = try_import '0x.color'

-- A magic table that is interested in every style.
all_styles = {}
setmetatable all_styles,
	__index: -> true
	__newindex: ->

check_cancel = () ->
	if aegisub.progress.is_cancelled!
		aegisub.cancel!

-- Try to determine an apppropriate interpolation function for the two values provided.
guess_interp = (tenv, c1, c2) ->
	ctype = type c1
	if ctype != type c2
		error "attempt to interpolate mismatched types: #{ctype} / #{type c2}"

	switch ctype
		when 'number' then tenv.util.lerp
		when 'string'
			-- the assumptions made in this branch are fallible and subject to future improvement
			if c1\match '&H[0-9a-fA-F][0-9a-fA-F]&'
				tenv.colorlib.interp_alpha
			else
				tenv.colorlib.interp_lch
		else error "unknown gradient type: #{ctype}. please pass a custom interpolation function."

util = (tenv) -> {
	tag_or_default: (tag, default) ->
		value = karaOK.line.tag tag
		if value == '' then default else value

	fad: (t_in, t_out) -> tenv.util.tag_or_default {'fad', 'fade'}, "\\fad(#{t_in},#{t_out})"

	-- "x fraction": first obj gets 0.0, last gets 1.0, and the rest get appropriate fractional values based on their center
	xf: (obj=tenv.char, objs=tenv.orgline.chars, field='center') ->
		x = obj[field]
		x0 = objs[1][field]
		x1 = objs[#objs][field]

		if x1 == x0 then return 0

		(x - x0) / (x1 - x0)

	lerp: (t, v0, v1) -> (v1 * t) + (v0 * (1 - t))

	gbc: (c1, c2, interp, t=tenv.util.xf!) ->
		interp or= guess_interp tenv, c1, c2
		interp t, c1, c2

	multi_gbc: (cs, interp, t=tenv.util.xf!) ->
		if t == 0 then return cs[1]
		if t == 1 then return cs[#cs]

		-- Without these parens, moonc outputs incorrect Lua.
		-- This is deeply disturbing.
		t *= (#cs - 1)

		c1, c2 = cs[1 + math.floor t], cs[2 + math.floor t]
		tenv.util.gbc c1, c2, interp, t % 1

	make_grad: (v1, v2, dv=1, vertical=true, loopname='grad', extend=true, index=nil) ->
		tenv.maxloop loopname, math.ceil((v2 - v1) / dv), index

		loopctx, meta = tenv.loopctx, tenv.meta
		loopval = loopctx.state[loopname]

		w1 = v1 + dv * (loopval - 1)
		w2 = v1 + dv * loopval
		if extend
			if loopval == 1 then w1 = 0
			if loopval == loopctx.max[loopname]
				w2 = if vertical then meta.res_y else meta.res_x
		else
			w2 = math.min w2, v2

		-- TODO:(?) some super overkill thing where you can specify all intended usages of this gradient,
		-- then it checks if the "next step" will be the same.
		-- while so, "take an extra step" in the tenv loop and extend the clip accordingly
		-- basically an ahead-of-time "combine gradient lines" action

		ftoa = tenv.util.ftoa
		if vertical
			"\\clip(0,#{ftoa w1},#{meta.res_x},#{ftoa w2})"
		else
			"\\clip(#{ftoa w1},0,#{ftoa w2},#{meta.res_y})"

	get_grad: (c1, c2, interp, loopname='grad', offset=0) ->
		interp or= guess_interp tenv, c1, c2
		-- TODO: expose this calculation somewhere, because it's handy
		t = (tenv.loopctx.state[loopname] - 1 + offset) / (tenv.loopctx.max[loopname] - 1)
		interp t, c1, c2

	get_multi_grad: (cs, interp, loopname='grad') ->
		t = (tenv.loopctx.state[loopname] - 1) / (tenv.loopctx.max[loopname] - 1)
		if t == 0 then return cs[1]
		if t == 1 then return cs[#cs]

		t *= (#cs - 1)
		c1, c2 = cs[1 + math.floor t], cs[2 + math.floor t]

		interp or= guess_interp tenv, c1, c2
		interp t % 1, c1, c2

	ftoa: (n, digits=2) ->
		assert digits >= 0 and digits == math.floor digits
		if n == math.floor n
			tostring n
		elseif digits == 0
			tostring tenv.util.math.round n
		else
			"%.#{digits}f"\format(n)\gsub('(%.%d-)0+$', '%1')\gsub('%.$', '')

	fbf: (mode='line', start_offset=0, end_offset=0, frames=1, loopname='fbf', index=1) ->
		tenv.retime mode, start_offset, end_offset

		first_frame = aegisub.frame_from_ms tenv.line.start_time
		last_frame = aegisub.frame_from_ms tenv.line.end_time

		n_frames = last_frame - first_frame
		loop_count = math.ceil(n_frames / frames)
		tenv.maxloop loopname, loop_count, index

		i = tenv.loopctx.state[loopname]
		start_time = aegisub.ms_from_frame(first_frame + (i - 1) * frames)
		if i == 1
			start_time = tenv.line.start_time
		end_time = aegisub.ms_from_frame(math.min(first_frame + i * frames, last_frame))
		if i == tenv.loopctx.max[loopname]
			end_time = tenv.line.end_time

		tenv.retime 'abs', start_time, end_time

	rand: {
		-- Either -1 or 1, randomly.
		sign: -> math.random(0, 1) * 2 - 1

		-- A random entry from a list, or a random code point from a string.
		item: (list) ->
			if type(list) == 'string'
				len = unicode.len list
				idx = math.random 1, len
				i = 1
				for c in unicode.chars list
					if i == idx
						return c
					i += 1

				error 'unreachable'
			else
				list[math.random 1, #list]

		-- A boolean with a truth probability of p.
		bool: (p=0.5) -> math.random! < p

		-- Either of two things, with p chance of picking the first.
		choice: (a, b, p) -> if tenv.util.rand.bool p then a else b
	}

	math: {
		round: (n) -> math.floor(n + 0.5)
	}
}

-- The shared global scope for all template code.
class template_env
	:_G, :math, :table, :string, :unicode, :tostring, :tonumber, :aegisub, :error, :karaskel, :require
	:colorlib

	printf: aegisub.log

	print: (...) ->
		args = {...}
		aegisub.log table.concat(args, '\t')
		aegisub.log '\n'

	-- Given a self object, returns an actual retime function, which cannot require a self parameter
	_retime = => (mode, start_offset=0, end_offset=0) ->
		return if @line == nil
		syl = @syl
		if syl == nil and @char != nil
			syl = @char.syl
		start_base, end_base = switch mode
			when 'syl'       then syl.start_time, syl.end_time
			when 'presyl'    then syl.start_time, syl.start_time
			when 'postsyl'   then syl.end_time, syl.end_time
			when 'line'      then 0, @orgline.duration
			when 'preline'   then 0, 0
			when 'postline'  then @orgline.duration, @orgline.duration
			when 'start2syl' then 0, syl.start_time
			when 'syl2end'   then syl.end_time, @orgline.duration
			when 'presyl2postline' then syl.start_time, @orgline.duration
			when 'preline2postsyl' then 0, syl.end_time
			when 'delta'
				@line.start_time += start_offset
				@line.end_time += end_offset
				@line.duration = @line.end_time - @line.start_time
				return
			when 'set', 'abs'
				@line.start_time = start_offset
				@line.end_time = end_offset
				@line.duration = end_offset - start_offset
				return
			when 'clamp'
				@line.start_time = math.max @line.start_time, @orgline.start_time + start_offset
				@line.end_time = math.min @line.end_time, @orgline.end_time + end_offset
				@line.duration = @line.end_time - @line.start_time
				return
			when 'clampsyl'
				@line.start_time = math.max @line.start_time, syl.start_time + start_offset
				@line.end_time = math.min @line.end_time, syl.end_time + end_offset
				@line.duration = @line.end_time - @line.start_time
				return
			else error "Unknown retime mode: #{mode}", 2

		orig_start = @orgline.start_time
		@line.start_time = orig_start + start_base + start_offset
		@line.end_time = orig_start + end_base + end_offset
		@line.duration = @line.end_time - @line.start_time

	_relayer = => (new_layer) -> @line.layer = new_layer

	_maxloop = (name) => (var, val, index) ->
		error "Missing maxloop value. Did you forget to specify a loop name?" if val == nil
		with @[name]
			if .max[var] == nil
				if index
					table.insert .vars, index, var
				else
					table.insert .vars, var
			.max[var] = val
			.state[var] or= 1
			-- BUG: there are unaccounted-for situations in which .done should be set to true
			unless .state[var] > .max[var]
				.done = false
		return -- returns the loopctx otherwise, which we don't want

	_set = => (key, val) -> @[key] = val

	new: (@subs, @meta, @styles) =>
		@_ENV = @
		@tenv = @
		@subtitles = @subs

		@ln = karaOK
		if USE_KARAOK
			@ln.init @
			-- some monkey-patching to address some execution environment differences from karaOK
			monkey_patch = (f) -> (...) ->
				patched_syl, patched_line = false, false
				if @syl == nil and @char != nil
					@syl = @char
					patched_syl = true
				elseif @syl == nil and @word != nil
					@syl = @word
					patched_syl = true
				if @line == nil and @orgline != nil
					@line = @orgline
					patched_line = true
				retvals = {f ...}
				@syl = nil if patched_syl
				@line = nil if patched_line
				table.unpack retvals

			@ln.tag.pos = monkey_patch @ln.tag.pos
			@ln.tag.move = monkey_patch @ln.tag.move

		@util = util @
		-- Not the best place to put an alias, but I don't want to mess up how the body of the util constructor is just a table literal.
		@util.cx = @util.xf

		@retime = _retime @
		@relayer = _relayer @
		@maxloop = _maxloop @, 'loopctx'
		@maxmloop = _maxloop @, 'mloopctx'
		@set = _set @

		@__private =
			compilation_cache: {}

-- Iterate over all sub lines, collecting those that are code chunks, templates, or mixins.
parse_templates = (subs, tenv) ->
	components =
		code: {once: {}, line: {}, word: {}, syl: {}, char: {}}
		template: {line: {}, word: {}, syl: {}, char: {}}
		mixin: {line: {}, word: {}, syl: {}, char: {}}

	interested_styles = {}

	aegisub.progress.set 0

	dialogue_index = 0

	for i, line in ipairs subs
		check_cancel!

		continue unless line.class == 'dialogue'
		dialogue_index += 1
		continue unless line.comment

		error = (msg) ->
			tenv.print "Error parsing component on line #{dialogue_index}:"
			tenv.print '\t' .. msg
			tenv.print!

			tenv.print 'Line text:'
			tenv.print '\t' .. line.raw
			tenv.print!

			print_stacktrace!
			aegisub.cancel!

		effect = line.effect\gsub('^ *', '')\gsub(' *$', '')
		first_word = effect\gsub(' .*', '')
		continue unless components[first_word] != nil

		modifiers = [word for word in effect\gmatch '[^ ]+']
		line_type, classifier = modifiers[1], modifiers[2]

		if classifier == 'once' and line_type != 'code'
			error 'The `once` classifier is only valid on `code` lines.'

		interested_styles[line.style] = true unless classifier == 'once'

		component =
			interested_styles: {[line.style]: true}
			interested_layers: nil
			interested_actors: nil
			disinterested_actors: nil
			interested_template_actors: nil
			disinterested_template_actors: nil
			interested_inline_fx: nil
			interested_syl_fx: nil
			repetitions: {}
			repetition_order: {}
			condition: nil
			cond_is_negated: false
			keep_tags: false
			multi: false
			noblank: false
			nok0: false
			notext: false
			merge_tags: true
			strip_trailing_space: true
			layer: line.layer
			template_actor: line.actor
			is_prefix: false

			func: nil -- present on `code` lines
			text: nil -- present on `template` and `mixin` lines

		if line_type == 'code'
			func, err = load line.text, 'code line', 't', tenv
			error err if err != nil

			component.func = func
		else
			component.text = line.text

		j = 3
		while j <= #modifiers
			modifier = modifiers[j]
			j += 1
			switch modifier
				when 'cond', 'if', 'unless'
					if component.condition != nil
						error 'Encountered multiple `cond` modifiers on a single component.'
					path = modifiers[j]
					j += 1
					for pattern in *{'[^A-Za-z0-9_.]', '%.%.', '^[0-9.]', '%.$'}
						if path\match pattern
							error "Invalid condition path: #{path}"
					component.condition = path
					if modifier == 'unless'
						component.cond_is_negated = true

				when 'loop', 'repeat'
					loop_var, loop_count = modifiers[j], tonumber modifiers[j + 1]
					j += 2
					if component.repetitions[loop_var] != nil
						error "Encountered multiple `#{loop_var}` repetitions on a single component."
					component.repetitions[loop_var] = loop_count
					table.insert component.repetition_order, loop_var

				when 'style'
					style_name = modifiers[j]
					j += 1
					interested_styles[style_name] = true
					component.interested_styles[style_name] = true

				when 'anystyle'
					interested_styles = all_styles
					component.interested_styles = all_styles

				when 'noblank'
					if classifier == 'once'
						error 'The `noblank` modifier is invalid for `once` components.'
					component.noblank = true

				when 'nok0'
					unless classifier == 'syl' or classifier == 'char'
						error 'The `nok0` modifier is only valid for `syl` and `char` components.'
					component.nok0 = true

				when 'keeptags', 'multi'
					unless classifier == 'syl'
						error "The `#{modifier}` modifier is only valid for `syl` components."
					error "The `#{modifier}` modifier is not yet implemented."

				when 'notext'
					unless line_type == 'template'
						error 'The `notext` modifier is only valid for templates.'
					component.notext = true

				when 'layer'
					unless line_type == 'mixin'
						error 'The `layer` modifier is only valid for mixins.'
					layer = tonumber modifiers[j]
					if layer == nil
						error "Invalid layer number: `#{modifiers[j]}`"
					j += 1
					component.interested_layers or= {}
					component.interested_layers[layer] = true

				when 'actor', 'noactor', 'sylfx', 'inlinefx'
					if classifier == 'once'
						error "The `#{modifier}` modifier is invalid for `once` components."

					if (modifier == 'sylfx' or modifier == 'inlinefx') and not (classifier == 'syl' or classifier == 'char')
						error "The `#{modifier}` modifier is only valid for `syl` and `char` components."

					name = modifiers[j]
					j += 1

					field = switch modifier
						when 'noactor' then 'disinterested_actors'
						when 'actor' then 'interested_actors'
						when 'sylfx' then 'interested_syl_fx'
						when 'inlinefx' then 'interested_inline_fx'

					component[field] or= {}
					component[field][name] = true

				when 't_actor', 'no_t_actor'
					unless line_type == 'mixin'
						error "The `#{modifier}` modifier is only valid for mixins."
					actor = modifiers[j]
					j += 1

					field = switch modifier
						when 't_actor' then 'interested_template_actors'
						when 'no_t_actor' then 'disinterested_template_actors'

					component[field] or= {}
					component[field][actor] = true

				when 'nomerge'
					unless line_type == 'template'
						error 'The `nomerge` modifier is only valid for templates.'
					component.merge_tags = false

				when 'keepspace'
					unless line_type == 'template'
						error 'The `keepspace` modifier is only valid for templates.'
					component.strip_trailing_space = false

				when 'prefix'
					unless line_type == 'mixin'
						error 'The `prefix` modifier is only valid for mixins.'
					component.is_prefix = true

				else
					error "Unhandled modifier: `#{modifier}`"


		category = components[line_type]
		if category == nil
			error "Unhandled line type: `#{line_type}`"

		group = category[classifier]
		if group == nil
			error "Unhandled classifier: `#{line_type} #{classifier}`"

		table.insert group, component

		aegisub.progress.set 100 * i / #subs

	components, interested_styles

-- Delete subtitle lines generated by previous templater invocations.
remove_old_output = (subs) ->
	is_fx = (line) ->
		return false unless line.class == 'dialogue'
		return false unless line.effect == 'fx'
		return false if line.comment
		true

	in_range = false
	ranges = {}
	for i, line in ipairs subs
		check_cancel!
		if is_fx line
			if in_range
				ranges[#ranges][2] = i
			else
				in_range = true
				table.insert ranges, {i, i}
		else
			in_range = false

	for i = #ranges, 1, -1
		check_cancel!
		subs.deleterange ranges[i][1], ranges[i][2]

-- Collect all lyrics that are fed into templates.
collect_template_input = (subs, interested_styles) ->
	is_kara = (line) ->
		return false unless line.class == 'dialogue'
		return false unless line.effect == 'karaoke' or line.effect == 'kara'
		return false unless interested_styles[line.style]
		true

	lines = {}
	for i, line in ipairs subs
		if is_kara line
			line.comment = true
			subs[i] = line
			line.li = i
			table.insert lines, line
	lines

-- Add additional data to the syls generated by karaskel.
preproc_syls = (line) ->
	assert line.syls == nil, 'karaskel populated line.syls (this is unexpected)'
	line.syls = line.kara
	for syl in *line.syls
		with syl
			.is_blank = (#.text_stripped == 0)
			.is_space = (#.text_spacestripped == 0 and not .is_blank)

			-- This pattern is flawed, but matches karaskel's treatment
			if .inline_fx != '' and .inline_fx == .text\match('%{.*\\%-([^}\\]+)')
				.syl_fx = .inline_fx
			else
				.syl_fx = ''

-- Generate word objects resembling the syl objects karaskel makes.
preproc_words = (line) ->
	line.words = {}
	current_word = {chars: {}}

	local seen_space, only_space
	seen_space = false
	only_space = true

	for char in *line.chars
		if char.is_space and #line.words > 0
			seen_space = true

		if seen_space and not char.is_space and not only_space
			table.insert line.words, current_word
			current_word = {chars: {}}
			seen_space = false
			only_space = true

		char.word = current_word
		table.insert current_word.chars, char

		if char.is_space
			seen_space = true
		else
			seen_space = false
			only_space = false

	if #line.chars > 0
		assert #current_word.chars > 0, 'there should always be a word left over when the loop ends'
		table.insert line.words, current_word

	for i, word in ipairs line.words
		with word
			-- we want spaces to be a part of the text, but not contribute to metrics
			.wchars = [char for char in *.chars when not char.is_space]
			first_char = .wchars[1]
			last_char = .wchars[#.wchars]

			.text = table.concat [char.text for char in *.chars]
			.text_stripped = table.concat [char.text_stripped for char in *.chars]
			-- being a sibling of syl, kdur might not make sense if syls span words
			-- .kdur = 0
			.line = line
			.i = i
			pre, post = .text_stripped\match("(%s*)%S+(%s*)$")
			.prespace = pre or ''
			.postspace = post or ''
			.text_spacestripped = .text_stripped\gsub('^[ \t]*', '')\gsub('[ \t]*$', '')
			.width = 0
			.height = 0
			.prespacewidth = aegisub.text_extents line.styleref, .prespace
			.postspacewidth = aegisub.text_extents line.styleref, .postspace
			.left = first_char.left
			.right = last_char.right
			.center = (.left + .right) / 2

			for char in *.wchars
				.width += char.width
				.height = math.max .height, char.height

			.is_blank = (#.text_stripped == 0)
			.is_space = (#.text_spacestripped == 0 and not .is_blank)

-- Generate char objects resembling the syl objects karaskel creates.
preproc_chars = (line) ->
	line.chars = {}
	i = 1
	left = 0
	for syl in *line.syls
		syl.chars = {}
		for ch in unicode.chars syl.text_stripped
			char = {:syl, :line, :i}
			char.text = ch
			char.is_space = (ch == ' ' or ch == '\t') -- matches karaskel behavior
			char.chars = {char}

			char.width, char.height, char.descent, _ = aegisub.text_extents line.styleref, ch
			char.left = left
			char.center = left + char.width/2
			char.right = left + char.width

			left += char.width

			table.insert syl.chars, char
			table.insert line.chars, char

			i += 1

	-- TODO: more karaskel-esque info for char objects

-- Give all objects within a line information about their position in terms of words, syls, and chars.
populate_indices = (line) ->
	line.wi, line.si, line.ci = 1, 1, 1

	wi, ci = 1, 1
	for word in *line.words
		-- TODO: figure out how to give words syl-indices? might not be reasonably possible
		word.wi, word.ci = wi, ci
		for char in *word.chars
			char.wi, char.ci = wi, ci
			ci += 1
		wi += 1

	si, ci = 1, 1
	for syl in *line.syls
		syl.wi, syl.si, syl.ci = wi, si, ci
		for char in *syl.chars
			char.si = si
			ci += 1
		si += 1

-- Given a list of tables, populate the `next` and `prev` fields of each to form an ad-hoc doubly linked list.
link_list = (list) ->
	for i = 1, #list
		if i > 1
			list[i].prev = list[i - 1]
		if i < #list
			list[i].next = list[i + 1]

-- Populate lines with extra information necessary for template evaluation.
-- Includes both karaskel preprocessing and some additional custom data.
preproc_lines = (subs, meta, styles, lines) ->
	link_list lines
	aegisub.progress.set 0
	for i, line in ipairs lines
		check_cancel!
		aegisub.progress.task "Preprocessing template input: line #{i}/#{#lines}"
		karaskel.preproc_line subs, meta, styles, line

		line.is_blank = (#line.text_stripped == 0)
		line.is_space = (line.text_stripped\find('[^ \t]') == nil)

		preproc_syls line
		preproc_chars line
		preproc_words line
		populate_indices line

		link_list line.syls
		link_list line.chars
		link_list line.words

		aegisub.progress.set 100 * i / #lines

-- Traverse a path such as foo.bar.baz within a table.
traverse_path = (path, root) ->
	node = root
	for segment in path\gmatch '[^.]+'
		node = node[segment]
		break if node == nil
	node

-- If a component has a `cond` predicate, determine whether that predicate is satisfied.
eval_cond = (path, tenv) ->
	return true if path == nil
	cond = traverse_path(path, tenv)
	switch cond
		when nil then error "Condition not found: #{path}", 2
		when true, false then cond
		else not (not cond!)

-- In case of multiple (space-separated) values in the actor field, check for a match with any
test_multi_actor = (interested_actors, actor_field) ->
	for actor in actor_field\gmatch '[^ ]+'
		return true if interested_actors[actor]
	false

-- Determine whether a component should be executed at all.
-- If using `loop`, runs on every iteration.
should_eval = (component, tenv, obj, base_component) ->
	if tenv.orgline != nil
		-- `orgline` is nil iff the component is a `once` component.
		-- Style filtering is irrelevant for `once` components.
		return false unless component.interested_styles[tenv.orgline.style]

	-- man this syntax looks like a mistake compared to rust's `if let Some(...) = ... {`
	if layers = component.interested_layers
		-- Only mixins can have a `layer` modifier.
		return false unless layers[tenv.line.layer]

	if actors = component.interested_actors
		-- Actor filtering is irrelevant for `once` components.
		return false unless test_multi_actor actors, tenv.orgline.actor

	if actors = component.disinterested_actors
		return false if test_multi_actor actors, tenv.orgline.actor

	if actors = component.interested_template_actors
		-- Only mixins can have a `t_actor` modifier.
		return false unless test_multi_actor actors, base_component.template_actor

	if actors = component.disinterested_template_actors
		return false if test_multi_actor actors, base_component.template_actor

	if fxs = component.interested_syl_fx
		syl = tenv.syl or tenv.char.syl
		return false unless fxs[syl.syl_fx]

	if fxs = component.interested_inline_fx
		syl = tenv.syl or tenv.char.syl
		return false unless fxs[syl.inline_fx]

	if component.noblank
		-- `obj` is nil iff the component is a `once` component.
		-- No-blank filtering is irrelevant for `once` components.
		return false if obj.is_blank or obj.is_space

	if component.nok0
		-- syl objects have direct access to their duration
		-- char objects need to fetch it from their containing syl
		-- zero-length filtering is irrelevant for line, word, and once components
		return false if (obj.duration or obj.syl.duration) <= 0

	cond_val = eval_cond component.condition, tenv
	if component.cond_is_negated
		return false if cond_val
	else
		return false unless cond_val

	true

-- Evaluate a dollar-variable.
eval_inline_var = (tenv) -> (var) ->
	local syl
	if tenv.syl
		syl = tenv.syl
	elseif tenv.char
		syl = tenv.char.syl

	strip_prefix = (str, prefix) ->
		len = prefix\len!
		if str\sub(1, len) == prefix then str\sub(len + 1) else nil

	val = switch var
		when '$sylstart' then syl.start_time
		when '$sylend' then syl.end_time
		when '$syldur' then syl.duration
		when '$kdur', '$sylkdur' then syl.duration / 10
		when '$ldur' then tenv.orgline.duration
		when '$li' then tenv.orgline.li
		when '$si' then (tenv.syl or tenv.char or tenv.orgline).si
		when '$wi' then (tenv.word or tenv.char or tenv.orgline).wi
		when '$ci' then (tenv.char or tenv.syl or tenv.word or tenv.orgline).ci
		when '$cxf' then tenv.util.xf(tenv.char, tenv.orgline.chars)
		when '$sxf' then tenv.util.xf(tenv.syl or tenv.char.syl, tenv.orgline.syls)
		when '$wxf' then tenv.util.xf(tenv.word or tenv.char.word, tenv.orgline.words)
		else
			if name = strip_prefix var, '$loop_'
				tenv.loopctx.state[name] or 1
			elseif name = strip_prefix var, '$maxloop_'
				tenv.loopctx.max[name] or 1
			elseif name = strip_prefix var, '$mloop_'
				tenv.mloopctx.state[name] or 1
			elseif name = strip_prefix var, '$maxmloop_'
				tenv.mloopctx.max[name] or 1
			elseif name = strip_prefix var, '$env_'
				tenv[name] -- this turned out to be less useful than I expected
			else
				error "Unrecognized inline variable: #{var}"

	tostring val

-- Evaluate an inline Lua expression.
eval_inline_expr = (tenv) -> (expr) ->
	cache = tenv.__private.compilation_cache
	func = cache[expr]
	if func == nil
		actual_expr = expr\sub 2, -2 -- remove the `!`s
		func_body = "return (#{actual_expr});"
		func, err = load func_body, "inline expression `#{func_body}`", 't', tenv
		if err != nil
			aegisub.log 0, "Syntax error in inline expression `#{func_body}`: #{err}"
			aegisub.cancel!

		cache[expr] = func

	val = func!
	if val == nil then '' else tostring(val)

-- Expand dollar-variables and inline Lua expressions within a template or mixin.
eval_body = (text, tenv) ->
	text\gsub('%$[a-z_]+', eval_inline_var tenv)\gsub('!.-!', eval_inline_expr tenv)

-- A collection of variables to iterate over in a particular order.
class loopctx
	new: (component) =>
		@vars = [var for var in *component.repetition_order]
		@state = {var, 1 for var in *@vars}
		@max = {var, max for var, max in pairs component.repetitions}
		@done = false

	incr: =>
		if #@vars == 0
			@done = true
			return

		@state[@vars[1]] += 1
		for i, var in ipairs @vars
			next_var = @vars[i + 1]
			if @state[var] > @max[var]
				if next_var != nil
					@state[var] = 1
					@state[next_var] += 1
				else
					@done = true
					return

-- Given a map of char indices to prepended text, evaluate the each mixin's body and insert its text at the appropriate index.
apply_mixins = (template, mixins, objs, tenv, tags, cls) ->
	for obj in *objs
		did_insert = false
		if tenv[cls] == nil
			tenv[cls] = obj
			did_insert = true

		for mixin in *mixins
			tenv.mloopctx = loopctx mixin
			while not tenv.mloopctx.done
				check_cancel!
				if should_eval mixin, tenv, obj, template
					ci = if (cls == 'line' or mixin.is_prefix) then 0 else obj.ci
					tags[ci] or= {}

					mskipped = false
					tenv.mskip = (using mskipped) -> mskipped = true
					tenv.unmskip = (using mskipped) -> mskipped = false

					tag = eval_body mixin.text, tenv

					unless mskipped
						table.insert tags[ci], tag

				tenv.mloopctx\incr!
			tenv.mloopctx = nil

		if did_insert
			tenv[cls] = nil

-- Combine the prefix generated from the `template` with the results of `apply_mixins` and the line's text itself.
build_text = (prefix, chars, tags, template) ->
	segments = {prefix}
	if tags[0]
		table.insert segments, tag for tag in *tags[0]
	for char in *chars
		if tags[char.ci] != nil
			table.insert segments, tag for tag in *tags[char.ci]
		unless template.notext
			table.insert segments, char.text

	table.concat segments

-- Where the magic happens. Run code, run templates, run components.
apply_templates = (subs, lines, components, tenv) ->
	run_code = (cls, orgobj) ->
		for code in *components.code[cls]
			tenv.loopctx = loopctx code
			while not tenv.loopctx.done
				check_cancel!
				if should_eval code, tenv, orgobj
					code.func!
				tenv.loopctx\incr!
			tenv.loopctx = nil

	run_mixins = (classes, template) ->
		tags = {}
		for cls in *classes
			mixins = components.mixin[cls]
			objs = if cls == 'line' then {tenv.line} else tenv.line[cls .. 's']
			apply_mixins template, mixins, objs, tenv, tags, cls
		tags

	run_templates = (cls, orgobj) ->
		for template in *components.template[cls]
			tenv.template_actor = template.template_actor
			tenv.loopctx = loopctx template
			while not tenv.loopctx.done
				check_cancel!
				if should_eval template, tenv, orgobj
					with tenv.line = table.copy tenv.orgline
						.comment = false
						.effect = 'fx'
						.layer = template.layer
						-- TODO: all this mutable access to the original is super sketchy. do something about it?
						.chars = orgobj.chars
						.words, .syls = switch cls
							when 'line' then .words, .syls
							when 'word' then {orgobj}, nil
							when 'syl' then nil, {orgobj}
							when 'char' then nil, nil

						-- I have no idea what I'm doing.
						--ci_offset = orgobj.chars[1].ci - 1
						--char.i -= ci_offset for char in *.chars

						--if .syls
						--	si_offset = .syls[1].si - 1
						--	syl.i -= si_offset for syl in *.syls

						--if .words
						--	wi_offset = .words[1].wi - 1
						--	word.i -= wi_offset for word in *.words

					skipped = false
					tenv.skip = (using skipped) -> skipped = true
					tenv.unskip = (using skipped) -> skipped = false

					prefix = eval_body template.text, tenv
					mixin_classes = switch cls
						when 'line' then {'line', 'word', 'syl', 'char'}
						when 'word' then {'line', 'word', 'char'}
						when 'syl' then {'line', 'syl', 'char'}
						when 'char' then {'line', 'char'}

					tags = run_mixins mixin_classes, template
					tenv.line.text = build_text prefix, tenv.line.chars, tags, template

					if template.merge_tags
						-- A primitive way of doing this. Patches welcome.
						-- Otherwise, if you're doing something fancy enough that this breaks it and `nomerge` isn't acceptable, you're on your own.
						tenv.line.text = tenv.line.text\gsub '}{', ''

					if template.strip_trailing_space
						-- Less primitive than the above thing, but still primitive. Might have worst-case quadratic performance.
						tenv.line.text = tenv.line.text\gsub ' *$', ''

					unless skipped
						subs.append tenv.line

					tenv.skip = nil
					tenv.unskip = nil

					tenv.line = nil
				tenv.loopctx\incr!
			tenv.loopctx = nil

	run_code 'once'

	aegisub.progress.set 0

	for i, orgline in ipairs lines
		aegisub.progress.task "Applying templates: line #{i}/#{#lines}"

		tenv.orgline = orgline
		run_code 'line', orgline
		run_templates 'line', orgline

		for orgword in *orgline.words
			tenv.word = orgword
			run_code 'word', orgword
			run_templates 'word', orgword
			tenv.word = nil

		for orgsyl in *orgline.syls
			tenv.syl = orgsyl
			-- TODO: `multi` support
			run_code 'syl', orgsyl
			run_templates 'syl', orgsyl
			tenv.syl = nil

		for orgchar in *orgline.chars
			tenv.char = orgchar
			run_code 'char', orgchar
			run_templates 'char', orgchar
			tenv.char = nil

		tenv.orgline = nil
		aegisub.progress.set 100 * i / #lines

-- Entry point
main = (subs, sel, active) ->
	math.randomseed os.time!

	task = aegisub.progress.task

	task 'Collecting header data...'
	meta, styles = karaskel.collect_head subs, false

	tenv = template_env subs, meta, styles

	check_cancel!
	task 'Parsing templates...'
	components, interested_styles = parse_templates subs, tenv

	check_cancel!
	task 'Removing old template output...'
	remove_old_output subs

	check_cancel!
	task 'Collecting template input...'
	lines = collect_template_input subs, interested_styles

	check_cancel!
	task 'Preprocessing template input...'
	preproc_lines subs, meta, styles, lines

	task 'Applying templates...'
	apply_templates subs, lines, components, tenv

	aegisub.set_undo_point 'apply karaoke template'

remove_fx_main = (subs, _sel, _active) ->
	remove_old_output subs
	aegisub.set_undo_point 'remove generated fx'

can_apply = (subs, _sel, _active) ->
	for line in *subs
		if line.comment == true and line.class == 'dialogue'
			effect = line.effect
			if #effect >= #'code syl'
				word = effect\match('(%l+) ')
				-- can't have a template that's just mixins
				if word == 'code' or word == 'template'
					return true
	return false

can_remove = (subs, _sel, _active) ->
	for line in *subs
		if line.effect == 'fx' and line.comment == false and line.class == 'dialogue'
			return true
	return false

aegisub.register_macro script_name, 'Run the templater', main, can_apply
aegisub.register_macro 'Remove generated fx', 'Remove non-commented lines whose Effect field is `fx`', remove_fx_main, can_remove

print_stacktrace = ->
	moon =
		errors: require 'moonscript.errors'
		posmaps: require 'moonscript.line_tables'

	cache = {}

	aegisub.log 'Stack trace:\n'

	current_source = nil

	for i = 1, 30
		info = debug.getinfo i, 'fnlS'
		break unless info

		with info
			posmap = moon.posmaps[.source]
			if .name == nil
				if .func == main
					.name = 'main'
				else
					.name = '<anonymous>'

			.currentline = moon.errors.reverse_line_number .source, posmap, .currentline, cache
			.linedefined = moon.errors.reverse_line_number .source, posmap, .linedefined, cache

			if .source != current_source
				current_source = .source
				short_path = .source\gsub '.*automation', 'automation'
				aegisub.log "    #{short_path}\n"

			aegisub.log "\tline #{.currentline} \t(in function #{.name}, defined on line #{.linedefined})\n"

	aegisub.log '\n'
