import Table from require "ILL.ILL.Table"

-- https://aegi.vmoe.info/docs/3.1/ASS_Tags/
export ASS_TAGS = {
	["an"]: {
		["ass"]: "\\an"
		["pattern"]: "%s*[1-9]"
		["pattern_value"]: "%s*([1-9])"
		["style_name"]: "align"
		["typer"]: "unsigned int"
		["first_category"]: true
		["value"]: 7
	}
	["fn"]: {
		["ass"]: "\\fn"
		["pattern"]: "%s*[^\\}]*"
		["pattern_value"]: "%s*([^\\}]*)"
		["style_name"]: "fontname"
		["typer"]: "string"
		["value"]: "Arial"
	}
	["fs"]: {
		["ass"]: "\\fs"
		["pattern"]: "%s*%d[%.%d]*"
		["pattern_value"]: "%s*(%d[%.%d]*)"
		["style_name"]: "fontsize"
		["typer"]: "unsigned float"
		["transformable"]: true
		["value"]: 60
	}
	["fscx"]: {
		["ass"]: "\\fscx"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["style_name"]: "scale_x"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 100
	}
	["fscy"]: {
		["ass"]: "\\fscy"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["style_name"]: "scale_y"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 100
	}
	["fsp"]: {
		["ass"]: "\\fsp"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["style_name"]: "spacing"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["i"]: {
		["ass"]: "\\i"
		["pattern"]: "%s*[0-1]"
		["pattern_value"]: "%s*([0-1])"
		["style_name"]: "italic"
		["typer"]: "bool"
		["value"]: false
	}
	["b"]: {
		["ass"]: "\\b"
		["pattern"]: "%s*[0-1]"
		["pattern_value"]: "%s*([0-1])"
		["style_name"]: "bold"
		["typer"]: "bool"
		["value"]: false
	}
	["u"]: {
		["ass"]: "\\u"
		["pattern"]: "%s*[0-1]"
		["pattern_value"]: "%s*([0-1])"
		["style_name"]: "underline"
		["typer"]: "bool"
		["value"]: false
	}
	["s"]: {
		["ass"]: "\\s"
		["pattern"]: "%s*[0-1]"
		["pattern_value"]: "%s*([0-1])"
		["style_name"]: "strikeout"
		["typer"]: "bool"
		["value"]: false
	}
	["c"]: {
		["ass"]: "\\c"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "color1"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&HFFFFFF&"
	}
	["2c"]: {
		["ass"]: "\\2c"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "color2"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&HFFFFFF&"
	}
	["3c"]: {
		["ass"]: "\\3c"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "color3"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&HFFFFFF&"
	}
	["4c"]: {
		["ass"]: "\\4c"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "color4"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&HFFFFFF&"
	}
	["alpha"]: {
		["ass"]: "\\alpha"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "alpha"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&H00&"
	}
	["1a"]: {
		["ass"]: "\\1a"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "alpha1"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&H00&"
	}
	["2a"]: {
		["ass"]: "\\2a"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "alpha2"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&H00&"
	}
	["3a"]: {
		["ass"]: "\\3a"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "alpha3"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&H00&"
	}
	["4a"]: {
		["ass"]: "\\4a"
		["pattern"]: "%s*&?[Hh]%x+&?"
		["pattern_value"]: "%s*(&?[Hh]%x+&?)"
		["style_name"]: "alpha4"
		["typer"]: "string"
		["transformable"]: true
		["value"]: "&H00&"
	}
	["bord"]: {
		["ass"]: "\\bord"
		["pattern"]: "%s*%d[%.%d]*"
		["pattern_value"]: "%s*(%d[%.%d]*)"
		["style_name"]: "outline"
		["typer"]: "unsigned float"
		["transformable"]: true
		["value"]: 0
	}
	["shad"]: {
		["ass"]: "\\shad"
		["pattern"]: "%s*%d[%.%d]*"
		["pattern_value"]: "%s*(%d[%.%d]*)"
		["style_name"]: "shadow"
		["typer"]: "unsigned float"
		["transformable"]: true
		["value"]: 0
	}
	["frz"]: {
		["ass"]: "\\frz"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["style_name"]: "angle"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["be"]: {
		["ass"]: "\\be"
		["pattern"]: "%s*%d[%.%d]*"
		["pattern_value"]: "%s*(%d[%.%d]*)"             
		["typer"]: "unsigned float"
		["transformable"]: true
		["value"]: 0
	}
	["blur"]: {
		["ass"]: "\\blur"
		["pattern"]: "%s*%d[%.%d]*"
		["pattern_value"]: "%s*(%d[%.%d]*)"                
		["typer"]: "unsigned float"
		["transformable"]: true
		["value"]: 0
	}
	["xbord"]: {
		["ass"]: "\\xbord"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["ybord"]: {
		["ass"]: "\\ybord"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["xshad"]: {
		["ass"]: "\\xshad"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["yshad"]: {
		["ass"]: "\\yshad"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["frx"]: {
		["ass"]: "\\frx"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["fry"]: {
		["ass"]: "\\fry"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"          
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["fax"]: {
		["ass"]: "\\fax"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["fay"]: {
		["ass"]: "\\fay"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["transformable"]: true
		["value"]: 0
	}
	["pos"]: {
		["ass"]: "\\pos"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
	}
	["move"]: {
		["ass"]: "\\move"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
	}
	["org"]: {
		["ass"]: "\\org"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
	}
	["clip"]: {
		["ass"]: "\\clip"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
		["transformable"]: true
	}
	["iclip"]: {
		["ass"]: "\\iclip"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
		["transformable"]: true
	}
	["fad"]: {
		["ass"]: "\\fad"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
	}
	["fade"]: {
		["ass"]: "\\fade"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "coords"
		["first_category"]: true
	}
	["t"]: {
		["ass"]: "\\t"
		["pattern"]: "%b()"
		["pattern_value"]: "%((.+)%)"
		["typer"]: "string"
		["first_category"]: true
	}
	["q"]: {
		["ass"]: "\\q"
		["pattern"]: "%s*[0-3]"          
		["pattern_value"]: "%s*([0-3])"                            
		["typer"]: "unsigned int"
	}
	["r"]: {
		["ass"]: "\\r"
		["pattern"]: "%s*[^\\}]*"
		["pattern_value"]: "%s*([^\\}]*)"
		["typer"]: "string"
	}
	["p"]: {
		["ass"]: "\\p"
		["pattern"]: "%s*%d"
		["pattern_value"]: "%s*(%d+)"
		["typer"]: "unsigned int"
		["value"]: 1
	}
	["pbo"]: {
		["ass"]: "\\pbo"
		["pattern"]: "%s*%-?%d[%.%d]*[eE%-%+%d]*"
		["pattern_value"]: "%s*(%-?%d[%.%d]*[eE%-%+%d]*)"
		["typer"]: "float"
		["value"]: 0
	}
	["k"]: {
		["ass"]: "\\k"
		["pattern"]: "%s*%d+"
		["pattern_value"]: "%s*(%d+)"
		["typer"]: "unsigned int"
		["value"]: 0
	}
	["K"]: {
		["ass"]: "\\K"
		["pattern"]: "%s*%d+"
		["pattern_value"]: "%s*(%d+)"
		["typer"]: "unsigned int"
		["value"]: 0
	}
	["kf"]: {
		["ass"]: "\\kf"
		["pattern"]: "%s*%d+"
		["pattern_value"]: "%s*(%d+)"
		["typer"]: "unsigned int"
		["value"]: 0
	}
	["ko"]: {
		["ass"]: "\\ko"
		["pattern"]: "%s*%d+"
		["pattern_value"]: "%s*(%d+)"
		["typer"]: "unsigned int"
		["value"]: 0
	}
	["fe"]: {
		["ass"]: "\\fe"
		["pattern"]: "%s*[^\\}]*"
		["pattern_value"]: "%s*([^\\}]*)"
		["typer"]: "string"
	}
}

class Tag

	-- sets the value of the tag
	setValue: (@name, @value, @i) =>
		@tag = Table.copy ASS_TAGS[name]
		@tag.value = value
		return @

	-- gets the value of the tag
	getValue: => @tag.value

	-- sets the value of the tag but automatically
	set: (@raw, name, value, i) =>
		@setValue name, value, i

		{:typer} = @tag
		unless typer != "string" and typer != "bool" and typer != "coords"
			if typer == "bool"
				@tag.value = value == "1"
			elseif typer == "coords" and value and value\match ","
				@tag.value = [tonumber v for v in value\gmatch "[^,]+"]
				if name == "clip" or name == "iclip"
					@tag.isRect = true
			elseif name == "t"
				s, e, a, transform = value\match "([%.%d]*)%,?([%.%d]*)%,?([%.%d]*)%,?(.+)"
				@tag.value = {s: tonumber(s), e: tonumber(e), a: tonumber(a), :transform}
		else
			@tag.value = tonumber value

	get: => @raw, @name, @value, @i

	new: (...) => @set ...

	copy: => Tag @__tostring!

	-- gets the tag pattern, optional pattern to get only the value
	getPattern: (name, with_value) ->
		{:ass, :pattern, :pattern_value} = ASS_TAGS[name]
		return with_value and ass .. pattern_value or ass .. pattern

	-- converts the tag back to string
	__tostring: =>
		{:ass, :value, :typer} = @tag
		if value
			if typer == "bool"
				return ass .. (value and "1" or "0")
			elseif typer == "coords"
				if type(value) == "table"
					return ass .. "(#{table.concat([v .. "," for v in *value])\gsub ",$", ""})"
				return ass .. "(#{value})"
			elseif @name == "t"
				{:s, :e, :a, :transform} = value
				if a
					return "\\t(#{s},#{e},#{a},#{transform})"
				elseif not a and e
					return "\\t(#{s},#{e},#{transform})"
				elseif not e and s
					return "\\t(#{s},#{transform})"
				return "\\t(#{transform})"
			return ass .. value
		return ""

{:Tag}