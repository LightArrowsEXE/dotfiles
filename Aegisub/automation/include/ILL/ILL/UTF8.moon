-- code taken from the Yutils lib
-- https://github.com/TypesettingTools/Yutils/blob/91a4ac771b08ecffdcc8c084592286961d99c5f2/src/Yutils.lua#L587

class UTF8

	new: (@s) =>

	charrange: (c, i) ->
		byte = c\byte i
		return not byte and 0 or byte < 192 and 1 or byte < 224 and 2 or byte < 240 and 3 or byte < 248 and 4 or byte < 252 and 5 or 6

	charcodepoint: (c) ->
		-- Basic case, ASCII
		b = c\byte 1
		return b if b < 128
		-- Use a naive decoding algorithm, and assume input is valid
		local res, w
		if b < 224 then
			-- prefix byte is 110xxxxx
			res = b - 192
			w = 2
		elseif b < 240 then
			-- prefix byte is 11100000
			res = b - 224
			w = 3
		else
			res = b - 240
			w = 4
		for i = 2, w
			res = res * 64 + c\byte(i) - 128
		return res

	chars: =>
		{:s} = @
		ci, sp, len = 0, 1, #s
		->
			if sp <= len
				cp = sp
				sp += UTF8.charrange s, sp
				if sp - 1 <= len
					ci += 1
					return ci, s\sub cp, sp - 1

	len: =>
		n = 0
		for ci in @chars!
			n += 1
		return n

{:UTF8}