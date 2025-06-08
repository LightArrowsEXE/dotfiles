import TABLE from require "ZF.main.util.table"

-- gets the patterns for ass tags
getPatterns = (get_value) ->
    patterns = {}
    for name, pattern in pairs {
        font:           "[^\\}]*"
        unsigned_int:   "%d+"
        unsigned_float: "%d[%.%d]*"
        float:          "%-?%d[%.%d]*"
        hex:            "&?[Hh]%x+&?"
        bool:           "[0-1]"
        zut:            "[0-3]"
        oun:            "[1-9]"
        braces:         "%b{}"
        bracket:        "%b()"
        shape:          "m%s+%-?%d[ %-%d%.mlb]"
    }
        if name == "braces"
            patterns[name] = get_value and "%{(.-)%}" or pattern
        elseif name == "bracket"
            patterns[name] = get_value and "%((.+)%)" or pattern
        else
            patterns[name] = "%s*" .. (get_value and "(" .. pattern .. ")" or pattern)
    return patterns

-- gets the patterns for ass tags in an extended form
getTagsPatterns = ->
    tagsPatterns = {
        an:    {id: "\\an",       type: "oun",            style_name: "align",    default_value: 7}
        fn:    {id: "\\fn",       type: "font",           style_name: "fontname", default_value: "Arial"}
        fs:    {id: "\\fs",       type: "unsigned_float", style_name: "fontsize", default_value: 20,          transformable: true}
        fsp:   {id: "\\fsp",      type: "float",          style_name: "spacing",  default_value: 0,           transformable: true}
        fscx:  {id: "\\fscx",     type: "unsigned_float", style_name: "scale_x",  default_value: 100,         transformable: true}
        fscy:  {id: "\\fscy",     type: "unsigned_float", style_name: "scale_y",  default_value: 100,         transformable: true}
        frz:   {id: "\\frz",      type: "float",          style_name: "angle",    default_value: 0,           transformable: true}
        bord:  {id: "\\bord",     type: "unsigned_float", style_name: "outline",  default_value: 2,           transformable: true}
        shad:  {id: "\\shad",     type: "unsigned_float", style_name: "shadow",   default_value: 2,           transformable: true}
        alpha: {id: "\\alpha",    type: "hex",            style_name: "alpha",    default_value: "&H00&",     transformable: true}

        ["1c"]: {id: "\\1c",      type: "hex",            style_name: "color1",   default_value: "&HFFFFFF&", transformable: true}
        ["2c"]: {id: "\\2c",      type: "hex",            style_name: "color2",   default_value: "&HFFFFFF&", transformable: true}
        ["3c"]: {id: "\\3c",      type: "hex",            style_name: "color3",   default_value: "&HFFFFFF&", transformable: true}
        ["4c"]: {id: "\\4c",      type: "hex",            style_name: "color4",   default_value: "&HFFFFFF&", transformable: true}
        ["1a"]: {id: "\\1a",      type: "hex",            style_name: "alpha1",   default_value: "&HFFFFFF&", transformable: true}
        ["2a"]: {id: "\\2a",      type: "hex",            style_name: "alpha2",   default_value: "&HFFFFFF&", transformable: true}
        ["3a"]: {id: "\\3a",      type: "hex",            style_name: "alpha3",   default_value: "&HFFFFFF&", transformable: true}
        ["4a"]: {id: "\\4a",      type: "hex",            style_name: "alpha4",   default_value: "&HFFFFFF&", transformable: true}

        b: {id: "\\b",            type: "bool",           style_name: "bold",      default_value: false}
        i: {id: "\\i",            type: "bool",           style_name: "italic",    default_value: false}
        s: {id: "\\s",            type: "bool",           style_name: "strikeout", default_value: false}
        u: {id: "\\u",            type: "bool",           style_name: "underline", default_value: false}

        k: {id: "\\[kK]^*[fo ]*", type: "unsigned_int",                            default_value: 0}
        p: {id: "\\p",            type: "oun",                                     default_value: 1}
        q: {id: "\\q",            type: "zut",                                     default_value: 0}

        t:     {id: "\\t",        type: "bracket"}
        pos:   {id: "\\pos",      type: "bracket"}
        org:   {id: "\\org",      type: "bracket"}
        move:  {id: "\\move",     type: "bracket"}
        fad:   {id: "\\fad",      type: "bracket"}
        fade:  {id: "\\fade",     type: "bracket"}

        clip:  {id: "\\clip",     type: "bracket"}
        iclip: {id: "\\iclip",    type: "bracket"}

        frx: {id: "\\frx",        type: "float",                                   default_value: 0,          transformable: true}
        fry: {id: "\\fry",        type: "float",                                   default_value: 0,          transformable: true}
        fax: {id: "\\fax",        type: "float",                                   default_value: 0,          transformable: true}
        fay: {id: "\\fay",        type: "float",                                   default_value: 0,          transformable: true}

        be:   {id: "\\be",        type: "unsigned_float",                          default_value: 0,          transformable: true}
        blur: {id: "\\blur",      type: "unsigned_float",                          default_value: 0,          transformable: true}

        xbord: {id: "\\xbord",    type: "float",                                   default_value: 0,          transformable: true}
        ybord: {id: "\\ybord",    type: "float",                                   default_value: 0,          transformable: true}
        xshad: {id: "\\xshad",    type: "float",                                   default_value: 0,          transformable: true}
        yshad: {id: "\\yshad",    type: "float",                                   default_value: 0,          transformable: true}
    }

    for name, info in pairs tagsPatterns
        {:id, :type} = info
        info["patterns_none_value"] = id .. AssPatternsNoneValues[type]
        info["patterns_with_value"] = id .. AssPatternsWithValues[type]

    return tagsPatterns

export AssPatternsNoneValues = getPatterns false
export AssPatternsWithValues = getPatterns true
export AssTagsPatterns = getTagsPatterns!

class LAYER

    version: "1.0.0"

    new: (@layer = "", last = true) =>
        @layer = type(@layer) == "table" and @layer["layer"] or @layer
        -- solves layer
        if l = last and @__lmatch("%b{}") or @__match("%b{}")
            @layer = l
        elseif @layer == ""
            @layer = "{}"
        @layer = @__gsub "\\a(#{AssPatternsNoneValues["oun"]})", "\\an%1"
        @layer = @__gsub "\\c(#{AssPatternsNoneValues["hex"]})", "\\1c%1"
        @layer = @__gsub "\\fr(#{AssPatternsNoneValues["float"]})", "\\frz%1"
        @layer = @__gsub "\\fad(#{AssPatternsNoneValues["bracket"]})", "\\fade%1"
        @animated "relocate"
        for name in *{"t", "pos", "org", "move", "fad", "fade", "i?clip"}
            @layer = @__gsub "\\#{name}%(%s*%)", ""

    -- extends the class with functions from the string lib
    __find:   (pattern, init, plain) => @layer\find pattern, init, plain
    __match:  (pattern, init, plain) => @layer\match pattern, init, plain
    __gsub:   (pattern, repl, n) => @layer\gsub pattern, repl, n
    __gmatch: (pattern) => @layer\gmatch pattern
    __lmatch: (pattern, value = [v for v in @__gmatch pattern]) => value[#value]

    -- checks if the tag is contained in the layer
    -- @param name string
    -- @return bool
    contain: (name) =>
        if @__match AssTagsPatterns[name]["patterns_none_value"]
            return true

    -- gets the tag value if it exists in the layer
    -- @param name string
    -- @return bool
    getTagValue: (name, info = AssTagsPatterns[name]) =>
        def_value = (val) ->
            if name != "t"
                if info["type"] == "bool"
                    return val == "1"
                elseif n = tonumber val
                    return n
                elseif val\match ","
                    return [tonumber v for v in val\gmatch "[^,]+"]
                return val
            else
                s, e, a, transform = val\match "([%.%d]*)%,?([%.%d]*)%,?([%.%d]*)%,?(.+)"
                s = tonumber s
                e = tonumber e
                a = tonumber a
                return {:s, :e, :a, :transform}
        {:patterns_none_value, :patterns_with_value} = info
        if tag = name != "t" and @__lmatch(patterns_none_value) or @__match(patterns_none_value)
            value = def_value tag\match patterns_with_value
            return value, name, info, tag, @__find tag, 1, true

    -- adds or removes the braces from the layer
    -- @param cmd string
    -- @return LAYER
    braces: (cmd = "add") =>
        if cmd == "add"
            unless @__match "%b{}"
                @layer = "{" .. @layer .. "}"
        elseif cmd == "rem"
            if @__match "%b{}"
                @layer = @__gsub "{(.-)}", "%1"
        else
            error "incompatible command"
        return @

    -- hides or unhides the tag \t of the layer
    -- @param cmd string
    -- @return LAYER
    animated: (cmd = "hide") =>
        if cmd == "hide"
            @layer = @__gsub "\\t%b()", (t) -> t\gsub "\\", "\\@"
        elseif cmd == "unhide"
            @layer = @__gsub "\\@", "\\"
        elseif cmd == "relocate"
            move = (val, new = "") ->
                val = val\match "%((.+)%)"
                while val
                    tag = val\gsub "\\t%b()", ""
                    val = val\match "\\t%((.+)%)"
                    new ..= "\\t(#{tag})"
                return new
            @layer = @__gsub "\\t%b()", (t) -> move t
        else
            error "incompatible command"
        return @

    -- removes one or more tags in the layer
    -- @return LAYER
    remove: (...) =>
        for t in *{...}
            if type(t) == "table"
                {a, b, c} = t
                @layer = @__gsub AssTagsPatterns[a]["patterns_none_value"], b or "", c
            elseif type(t) == "string"
                @layer = @__gsub AssTagsPatterns[t]["patterns_none_value"], ""
            else
                error "incompatible value type"
        return @

    -- adds one or more tags to the layer
    -- @return LAYER
    insert: (...) =>
        @braces "rem"
        for t in *{...}
            if type(t) == "table"
                {a, b} = t
                if a
                    @layer = b and a .. @layer or @layer .. a
            elseif type(t) == "string"
                @layer ..= t
            else
                error "incompatible value type"
        @braces "add"
        return @

    -- adds the style tag values in the layer if the tag does not exist in the layer
    -- @param styleref table
    -- @param onlyAnimated bool
    -- @return LAYER
    insertStyleRef: (styleref, onlyAnimated = true) =>
        for name, info in pairs AssTagsPatterns
            if style_name = info["style_name"]
                unless @contain name
                    if onlyAnimated
                        continue unless info["transformable"]
                    value = styleref[style_name]
                    if info["type"] == "bool"
                        value = value and "1" or "0"
                    @insert info["id"] .. value
        return @

    -- removes the style tag values in the layer if the tag exists in the layer and equals the style value
    -- @param styleref table
    -- @return LAYER
    removeStyleRef: (styleref) =>
        for name, info in pairs AssTagsPatterns
            if style_name = info["style_name"]
                if value = @getTagValue name
                    if styleref[style_name] == value
                        @remove name
            elseif info["transformable"]
                if value = @getTagValue name
                    if info["value"] == value or info["default_value"] == value
                        @remove name
        return @

    -- adds pending tags from a previous layer value as a reference
    -- @param prev string || LAYER
    -- @return LAYER
    insertPending: (prev, concat = {}) =>
        for val in *LAYER(prev)\split!
            {:name, :info, :tag} = val
            if info["transformable"]
                TABLE(concat)\push tag
        @insert {table.concat(concat), true}
        return @

    -- removes equal tags from a previous layer value as reference
    -- @param prev string || LAYER
    -- @return LAYER
    removeEquals: (prev) =>
        for val in *LAYER(prev)\split!
            {:name, tag: prev_tag} = val
            infos = {@getTagValue name}
            if infos[1] and prev_tag == infos[4]
                @remove name
        return @

    -- replaces position values in the layer
    -- @param posVals table
    -- @param orgVals table
    -- @return LAYER
    replaceCoords: (posVals, orgVals) =>
        @braces "rem"
        if @__match "\\move%b()"
            if #posVals >= 4
                {a, b, c, d, e, f} = posVals
                e = e and ",#{e}" or ""
                f = f and ",#{f}" or ""
                move = "\\move(#{a},#{b},#{c},#{d .. e .. f})"
                @remove {"move", move, 1}
        elseif #posVals == 2
            {a, b} = posVals
            pos = "\\pos(#{a},#{b})"
            if @__match "\\pos%b()"
                @remove {"pos", pos, 1}
            else
                @insert {pos, true}
        if orgVals and #orgVals == 2
            {a, b} = orgVals
            org = "\\org(#{a},#{b})"
            if @__match "\\org%b()"
                @remove {"org", org, 1}
            else
                @insert {org, true}
        @braces "add"
        return @

    -- splits layer tag by tag
    -- @return table
    split: (split = {}) =>
        copy = LAYER @layer
        -- adds the values to the split table
        push = (name) ->
            value, name, info, tag, i = copy\getTagValue name
            if value
                TABLE(split)\push {:name, :info, :tag, :value, :i}
        -- adds all the \t tags present in the layer
        while copy\__match "\\t%b()"
            push "t"
            copy.layer = copy\__gsub "\\t%b()", "", 1
        -- adds tags other than the \t tag
        @animated "hide"
        [push name for name in pairs AssTagsPatterns]
        @animated "unhide"
        -- gets an already processed value
        split.getTagValue = (name) ->
            for val in *split
                if val["name"] == name
                    return val
        -- converts the split to string
        split.__tostring = (concat = "") ->
            for val in *@split!
                concat ..= val["tag"]
            return "{" .. concat .. "}"
        -- fixes the position of the split tags according to their original position in the layer
        table.sort split, (a, b) -> a.i < b.i
        return split

    -- removes repeated tags and optionally removes values equal to the style values in the layer
    -- @param styleref table
    -- @return LAYER
    clear: (styleref) =>
        @layer = @split!["__tostring"]!
        if styleref
            @removeStyleRef styleref
        return @

    __tostring: => @layer

{:LAYER}