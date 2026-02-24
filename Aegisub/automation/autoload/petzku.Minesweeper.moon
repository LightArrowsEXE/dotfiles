-- Copyright (c) 2023 petzku <petzku@zku.fi>

export script_name =        "Minesweeper"
export script_description = "Play Minesweeper. Why? Who knows."
export script_author =      "petzku"
export script_namespace =   "petzku.Minesweeper"
export script_version =     "0.4.0"

DIFFICULTIES = {
    "&Trivial":         {w:  4, h:  4, m:  3}
    "&Beginner":        {w:  9, h:  9, m: 10}
    "&Intermediate":    {w: 16, h: 16, m: 40}
    "&Expert":          {w: 30, h: 16, m: 99}
}

WIDTH = 9
HEIGHT = 9
MINES = 10

math.randomseed os.time!

_rev = (field, x, y) ->
    tile = field[x][y]
    return unless tile.hidden
    tile.hidden = false
    if tile.n == 0 and not tile.mine
        -- cascade
        for i = -1,1
            for j = -1,1
                continue if i == 0 and j == 0
                xx = x + i
                yy = y + j
                continue if xx < 1 or yy < 1 or xx > WIDTH or yy > HEIGHT
                _rev field, xx, yy

select_diff = ->
    btn = aegisub.dialog.display {
        {x: 0, y: 0, height: 1, width: 10, class: "label", label: "Choose your difficulty:"}
    }, [name for name, v in pairs DIFFICULTIES]
    diff = DIFFICULTIES[btn]
    export WIDTH, HEIGHT, MINES = if diff
        diff.w, diff.h, diff.m
    else
        -- user clicked X or something
        return false
    true

build_field = ->
    t = {}
    for i = 1,WIDTH
        table.insert t, {}
        for j = 1,HEIGHT
            table.insert t[i], {hidden: true, mine: false, n: 0, flag: false}

    -- place mines
    free_tiles = [{x,y} for x=1,WIDTH for y=1,HEIGHT]
    for m = 1, MINES
        i = math.random 1, #free_tiles
        x, y = unpack free_tiles[i]
        t[x][y].mine = true
        for i = -1,1
            for j = -1,1
                continue if i == 0 and j == 0
                xx = x + i
                yy = y + j
                continue if xx < 1 or yy < 1 or xx > WIDTH or yy > HEIGHT
                t[xx][yy].n += 1
        -- prevent double selection
        table.remove free_tiles, i

    -- reveal starting square
    do
        -- prioritize picking an empty square, if possible
        zeros = [{x,y} for x=1,WIDTH for y=1,HEIGHT when t[x][y].n == 0 and not t[x][y].mine]
        starts = if #zeros > 0 then zeros else
            [{x,y} for x=1,WIDTH for y=1,HEIGHT when not t[x][y].mine]
        i = math.random 1, #starts
        x, y = unpack starts[i]
        _rev t, x, y
    t

_count_flags = (field) ->
    flags = 0
    for row in *field
        for tile in *row
            flags += 1 if tile.flag
    flags

build_gui = (field, reveal) ->
    flags = _count_flags field
    t = {{
        x: 0, y: 0, height: 1, width: 10, class: "label",
        label: if reveal
            reveal
        elseif flags == 0
            "Let's play minesweeper!"
        else "Mines left: #{MINES-flags} / #{MINES}"
    }}
    for c, col in ipairs field
        for r, cell in ipairs col
            x = if cell.flag
                {x: c-1, y: r, height: 1, width: 1, class: "label", label: "🚩"}
            elseif cell.hidden
                unless reveal
                    {x: c-1, y: r, height: 1, width: 1, class: "checkbox", value: false, name: "#{c}-#{r}", hint: "#{c}-#{r}"}
                else
                    {x: c-1, y: r, height: 1, width: 1, class: "label", label: cell.mine and "💣" or " - "}
            else
                {x: c-1, y: r, height: 1, width: 1, class: "label", label: cell.mine and "💥" or "#{cell.n == 0 and '  ' or string.format "%2d ", cell.n}"}
            table.insert t, x
    t

reveal = (field, res) ->
    cells = {}
    for k, v in pairs res
        if v
            table.insert cells, k
    return field, true, "Open at least one cell!" unless #cells > 0
    -- try to open cell
    boom = false
    for cell in *cells
        x, y = cell\match "(%d+)%-(%d+)"
        x = tonumber x
        y = tonumber y

        -- we might have cascaded into this cell
        continue unless field[x][y].hidden
        aegisub.log 5, "revealing #{x},#{y}\n"

        -- reveal, cascading if this is zero
        _rev field, x, y
        boom or= field[x][y].mine
    field, boom

flag = (field, res) ->
    cells = {}
    for k, v in pairs res
        if v
            table.insert cells, k
    return field, true, "Flag at least one cell!" unless #cells > 0
    for cell in *cells
        x, y = cell\match "(%d+)%-(%d+)"
        x = tonumber x
        y = tonumber y
        field[x][y].flag = true
    field

remove_flags = (field) ->
    for row in *field
        for tile in *row
            tile.flag = false
    field

check_win = (field) ->
    for col in *field
        for x in *col
            return false if x.hidden and not x.mine
    return true

main = ->
    f = build_field!
    win = false
    while not win
        btn, res = aegisub.dialog.display (build_gui f), {"&Reveal", "&Flag", "&Clear flags", "&Quit"}, {ok: "&Reveal", cancel: "&Quit"}
        -- cancel = quit game
        break unless btn
        f, quit, msg = if btn == "&Reveal"
            reveal f, res
        elseif btn == "&Flag"
            flag f, res
        elseif btn == "&Clear flags"
            remove_flags f
        else
            f
        aegisub.log 3, msg if msg
        break if quit

        win = check_win f
    aegisub.dialog.display (build_gui f, win and "You won!" or "You lost!"), {"&Close"}

start = ->
    -- select difficulty and play; if user presses X, quit immediately
    main! if select_diff!

aegisub.register_macro script_name, script_description, start
