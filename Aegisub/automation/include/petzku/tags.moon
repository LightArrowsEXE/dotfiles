-- Copyright (c) 2022 petzku <petzku@zku.fi>

-- Load colon-separated tag-value pairs from a line's actor field.
-- Transforms semicolons into commas because of aegisub limitations. Not much to be done there, unfortunately.

-- Takes in either a line table, or a raw string. If passed a line table, reads from the actor field.
-- General usage (assuming "foo=3:bar=4" in actor field):
--  loadtags.str(line)      -> "\foo3\bar4"
--  loadtags.table(line)    -> {foo: "3", bar: "4"}
--  loadtags.table("foo=3") -> {foo: "3"}

-- Key names must be alphanumeric. Values can contain anything except the separator character.

-- Optionally can be configured via the `config´ function. Takes two arguments, both optional:
--  `tenv´      The template execution table. Used to fallback for line content if given.
--              If left nil, remains unchanged. This allows possibly easier configuration
--              during template execution, or usage outside a templater context.
--  `opts´      A table of options to set. Currently supports:
--      sep         string  The symbol to use as a separator. Should be only one character.
--                          Defaults to ":". A space character is another good option.
--      rep_commas  bool    Whether to substitute semicolons "back" to commas.
--                          Defaults to true.
--      read_flags  bool    Whether to read "flag" options, i.e. values that do not have a "=" sign.
--                          These will never be output by `str`, but will be in `table`. You can use "foo=" for that.
--                          Defaults to true.


haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'
if haveDepCtrl
    depctrl = DependencyControl {
        name: 'Tags',
        version: '0.3.0',
        description: [[Read key-value pairs from lines]],
        author: "petzku",
        url: "https://github.com/petzku/Aegisub-Scripts",
        feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
        moduleName: 'petzku.tags'
    }


config = {
    sep: " ",
    rep_commas: true,
    read_flags: true,
}
tenv = {}


configure = (_tenv, opts) ->
    if _tenv
        tenv = _tenv
    if opts
        for k,v in pairs opts
            if config[k] != nil
                config[k] = v


iter_string = (str) ->
    pattern = "(%w+)=([^#{config.sep}]+)"
    str\gmatch pattern

iter_flags = (str) ->
    -- we allow any non-separator character, because... reasons.
    -- this also matches anything with an equals sign, so we'll need to skip those...
    -- this would be "cleaner" to do with a proper lua iterator, but that sounds like pain.
    pattern = "([^#{config.sep}]+)"
    str\gmatch pattern

format_value = (val) ->
    if config.rep_commas
        val = val\gsub ";", ","
    val


tags_table = (str) ->
    t = {}
    for tag, value in iter_string str
        if tag
            t[tag] = format_value value
    -- also parse flags, if desired
    for tag in iter_flags str
        -- = means this is a key-value pair. skip
        if tag and not tag\find "="
            t[tag] = true
    t

tag_string = (str) ->
    out = ""
    -- loop through string manually because table loses ordering
    -- otherwise, we could just call tags_table
    for tag, value in iter_string str
        if tag
            out ..= "\\" .. tag .. format_value value
    out

wrap = (f) -> (line) ->
    str = if not line
        (tenv.line or tenv.orgline).actor
    elseif type(line) == "table"
        line.actor
    else
        line
    f(str)


loadtags = {
    table:  wrap tags_table,
    str:    wrap tag_string,
    config: configure,
}

if haveDepCtrl
    loadtags.version = depctrl
    depctrl\register loadtags
else
    return loadtags
