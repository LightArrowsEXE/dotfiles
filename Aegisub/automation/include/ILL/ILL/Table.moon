{:insert, :remove} = table

class Table

	-- checks if the table is empty
	isEmpty: (tb) -> next(tb) == nil

	-- makes a shallow copy of the table
	shallowcopy: (tb) ->
		shallowcopy = (t) ->
			copy = {}
			if type(t) == "table"
				for k, v in pairs t
					copy[k] = v
			else
				copy = t
			return copy
		return shallowcopy tb

	-- makes a deep copy of the table
	deepcopy: (tb) ->
		deepcopy = (t, copies = {}) ->
			copy = {}
			if type(t) == "table"
				if copies[t]
					copy = copies[t]
				else
					copies[t] = copy
					for k, v in next, t, nil
						copy[deepcopy k, copies] = deepcopy v, copies
					setmetatable copy, deepcopy getmetatable(t), copies
			else
				copy = t
			return copy
		return deepcopy tb

	-- makes a copy of the table
	copy: (tb, deepcopy = true) -> deepcopy and Table.deepcopy(tb) or Table.shallowcopy(tb)

	-- inserts one or more values at the end of an array
	push: (tb, ...) ->
		arguments = {...}
		for i = 1, #arguments
			insert tb, arguments[i]
		return #arguments

	-- removes the last value from the array
	pop: (tb) -> remove tb

	-- reverses the array values
	reverse: (tb) -> [tb[#tb + 1 - i] for i = 1, #tb]

	-- removes the first value from the array
	shift: (tb) -> remove tb, 1

	-- inserts one or more values at the beginning of an array
	unshift: (tb, ...) ->
		arguments = {...}
		for i = #arguments, 1, -1
			insert tb, 1, arguments[i]
		return #tb

	-- slices the array according to the given arguments
	slice: (tb, f, l, s) -> [tb[i] for i = f or 1, l or #tb, s or 1]

	-- changes the contents of a array, adding new elements while removing old ones
	splice: (tb, start, delete, ...) ->
		arguments, removes, t_len = {...}, {}, #tb
		n_args, i_args = #arguments, 1
		start = start < 1 and 1 or start
		delete = delete < 0 and 0 or delete
		if start > t_len
			start = t_len + 1
			delete = 0
		delete = start + delete - 1 > t_len and t_len - start + 1 or delete
		for pos = start, start + math.min(delete, n_args) - 1
			insert removes, tb[pos]
			tb[pos] = arguments[i_args]
			i_args += 1
		i_args -= 1
		for i = 1, delete - n_args
			insert removes, remove tb, start + i_args
		for i = n_args - delete, 1, -1
			insert tb, start + delete, arguments[i_args + i]
		return removes

	-- returns the contents of a table to a string
	view: (tb, table_name = "table_unnamed", indent = "") ->
		cart, autoref = "", ""
		basicSerialize = (o) ->
			so = tostring o
			if type(o) == "function"
				info = debug.getinfo o, "S"
				return string.format "%q", so .. ", C function" if info.what == "C"
				string.format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
			elseif (type(o) == "number") or (type(o) == "boolean")
				return so
			string.format "%q", so
		addtocart = (value, table_name, indent, saved = {}, field = table_name) ->
			cart ..= indent .. field
			if type(value) != "table"
				cart ..= " = " .. basicSerialize(value) .. ";\n"
			else
				if saved[value]
					cart ..= " = {}; -- #{saved[value]}(self reference)\n"
					autoref ..= "#{table_name} = #{saved[value]};\n"
				else
					saved[value] = table_name
					if Table.isEmpty value
						cart ..= " = {};\n"
					else
						cart ..= " = {\n"
						for k, v in pairs value
							k = basicSerialize k
							fname = "#{table_name}[ #{k} ]"
							field = "[ #{k} ]"
							addtocart v, fname, indent .. "	", saved, field
						cart = "#{cart}#{indent}};\n"
		return "#{table_name} = #{basicSerialize tb}" if type(tb) != "table"
		addtocart tb, table_name, indent
		return cart .. autoref

{:Table}