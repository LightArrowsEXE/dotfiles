import Math  from require "ILL.ILL.Math"
import Table from require "ILL.ILL.Table"

class Util

	-- finds the last occurrence of a pattern in a string
	lmatch: (value, pattern, last) ->
		assert type(value) == "string", "expected string"
		for result in value\gmatch pattern
			last = result
		return last

	-- splits a string into two parts based on a delimiter
	headTail: (s, div) ->
		a, b, head, tail = s\find "(.-)#{div}(.*)"
		if a
			return head, tail
		return s, ""

	-- splits a string into multiple parts based on a delimiter
	splitByPattern: (s, div) ->
		t, insert = {}, table.insert
		while s != ""
			head, tail = Util.headTail s, div
			insert t, head
			s = tail
		return t

	-- converts colors from one mode to another
	convertColor: (mode, value) ->
		switch mode
			-- alpha from style
			when "alpha_fs"
				alpha = value\match "&?[Hh](%x%x)%x%x%x%x%x%x&?"
				return "&H#{alpha}&"
			-- color from style
			when "color_fs" 
				color = value\match "&?[Hh]%x%x(%x%x%x%x%x%x)&?"
				return "&H#{color}&"

	-- interpolates values between two times with controlled acceleration
	getTimeInInterval: (currTime, t1, t2, accel = 1) ->
		local t
		if currTime < t1
			t = 0
		elseif currTime >= t2
			t = 1
		else
			t = (currTime - t1) ^ accel / (t2 - t1) ^ accel
		return t

	-- creates animations with smooth transitions between different transparency values over time
	getAlphaInterpolation: (currTime, t1, t2, t3, t4, a1, a2, a3, a = a3) ->
		if currTime < t1
			a = a1
		elseif currTime < t2
			cf = (currTime - t1) / (t2 - t1)
			a = a1 * (1 - cf) + a2 * cf
		elseif currTime < t3
			a = a2
		elseif currTime < t4
			cf = (currTime - t3) / (t4 - t3)
			a = a2 * (1 - cf) + a3 * cf
		return a

	-- gets the correct alpha value according to the tag \fad or \fade
	getTagFade: (currTime, lineDur, dec, ...) ->
		args, a1, a2, a3, t1, t2, t3, t4 = {...}
		if #args == 2
			a1, a2, a3, t1 = 255, 0, 255, 0
			{t2, t3} = args
			t4 = lineDur
			t3 = t4 - t3
		elseif #args == 7
			{a1, a2, a3, t1, t2, t3, t4} = args
		else
			return ""
		return Util.getAlphaInterpolation currTime, t1, t2, t3, t4, a1, dec or a2, a3

	-- gets the correct value of time(t) according to the parameters of the \t tag
	getTagTransform: (currTime, lineDur, ...) ->
		args, t1, t2, accel = {...}, 0, lineDur, 1
		if #args == 3
			{t1, t2, accel} = args
		elseif #args == 2
			{t1, t2} = args
		elseif #args == 1
			{accel} = args
		return Util.getTimeInInterval currTime, t1, t2, accel

	-- gets the correct value of the x and y axes according to the parameters of the \move tag
	getTagMove: (currTime, lineDur, x1, y1, x2, y2, t1, t2) ->
		if t1 and t2
			if t1 > t2
				t1, t2 = t2, t1
		else
			t1, t2 = 0, 0
		if t1 <= 0 and t2 <= 0
			t1, t2 = 0, lineDur
		t = Util.getTimeInInterval currTime, t1, t2
		x = Math.round (1 - t) * x1 + t * x2, 3
		y = Math.round (1 - t) * y1 + t * y2, 3
		return x, y

	-- makes a linear interpolation between several types of values
	interpolation: (t = 0.5, interpolationType = "auto", ...) ->
		values = type(...) == "table" and ... or {...}
		-- interpolation between two alpha values
		interpolate_alpha = (u, f, l) ->
			a = f\match "&?[hH](%x%x)&?"
			b = l\match "&?[hH](%x%x)&?"
			c = Math.lerp u, tonumber(a, 16), tonumber(b, 16)
			return ("&H%02X&")\format c
		-- interpolation between two color values
		interpolate_color = (u, f, l) ->
			a = {f\match "&?[hH](%x%x)(%x%x)(%x%x)&?"}
			b = {l\match "&?[hH](%x%x)(%x%x)(%x%x)&?"}
			c = [Math.lerp u, tonumber(a[i], 16), tonumber(b[i], 16) for i = 1, 3]
			return ("&H%02X%02X%02X&")\format unpack c
		-- interpolation between two shapes values
		interpolate_shape = (u, f, l, j = 0) ->
			a = [tonumber(s) for s in f\gmatch "%-?%d[%.%d]*"]
			b = [tonumber(s) for s in l\gmatch "%-?%d[%.%d]*"]
			assert #a == #b, "The shapes must have the same stitch length"
			f = f\gsub "%-?%d[%.%d]*", (s) ->
				j += 1
				return Math.round Math.lerp(u, a[j], b[j]), 2
			return f
		-- interpolation between two table values
		interpolate_table = (u, f, l, new = {}) ->
			assert #f == #l, "The interpolation depends on tables with the same number of elements"
			for i = 1, #f
				new[i] = Util.interpolation u, nil, f[i], l[i]
			return new
		-- gets function from interpolation type
		fn = switch interpolationType
			when "number" then Math.lerp
			when "alpha"  then interpolate_alpha
			when "color"  then interpolate_color
			when "shape"  then interpolate_shape
			when "table"  then interpolate_table
			when "auto"
				types = {}
				for k, v in ipairs values
					if type(v) == "number"
						types[k] = "number"
					elseif type(v) == "table"
						types[k] = "table"
					elseif type(v) == "string"
						if v\match "&?[hH]%x%x%x%x%x%x&?"
							types[k] = "color"
						elseif v\match "&?[hH]%x%x&?"
							types[k] = "alpha"
						elseif v\match "m%s+%-?%d[%.%-%d mlb]*"
							types[k] = "shape"
					assert types[k] == types[1], "The interpolation must be done on values of the same type"
				return Util.interpolation t, types[1], ...
		t = Math.clamp(t, 0, 1) * (#values - 1)
		u = math.floor t
		return fn t - u, values[u + 1], values[u + 2] or values[u + 1]

	-- fixes the way windows sees the path
	fixPath: (path) ->
		if jit.os == "Windows"
			path = path\gsub "/", "\\"
		else
			path = path\gsub "\\", "/"
		return path

	-- checks if a file or folder exists
	fileExist: (dir, isDir) ->
		a = dir\sub 1, 1
		b = dir\sub -1, -1
		c = "\""
		if a == c and b == c
			dir = dir\sub 2, -2
		dir ..= "/" if isDir
		ok, err, code = os.rename dir, dir
		unless ok
			return true if code == 13
		return ok, err

	-- checks if the text is a blank
	isBlank: (t) ->
		if type(t) == "table"
			with t
				if .duration and .text_stripped
					if .duration <= 0 or .text_stripped\len! <= 0
						return true
					t = .text_stripped
				else
					t = .text\gsub "%b{}", ""
		else
			t = t\gsub "[ \t\n\r]", ""
			t = t\gsub "　", ""
		return t\len! <= 0

	-- checks if the text is a shape
	isShape: (t) ->
		-- checks if the \p tag exists in tag
		a = t\match "%b{}"
		a = a and a\match "\\p%s*%d"
		-- checks whether the text is actually a shape
		b = t\gsub "%b{}", ""
		b = b\match "m%s+%-?%d[%.%-%d mlb]*"
		-- does both vefications and if it is true it is a shape
		return a != nil and b != nil

	-- checks if the instance is a class given its name
	checkClass: (cls, name) ->
		if type(cls) == "table"
			if mt = getmetatable cls
				return mt.__class.__name == name
		return false

{:Util}