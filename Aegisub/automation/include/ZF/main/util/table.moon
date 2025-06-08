class TABLE

    version: "1.0.0"

    new: (@t = t) =>

    -- makes arithmetic operations on a table
    -- @param fn function
    -- @return table
    arithmeticOp: (fn = ((v) -> v), operation = "+") =>
        result = 0
        for k, v in ipairs @t
            switch operation
                when "+", "sum" then result += fn v
                when "-", "sub" then result -= fn v
                when "*", "mul" then result *= fn v
                when "/", "div" then result /= fn v
                when "%", "rem" then result %= fn v
                when "^", "exp" then result = result ^ fn v
        return result

    -- removes duplicate elements in a table
    -- @return table
    clean: =>
        f, n = {}, {}
        for k, v in pairs @t
            if type(v) == "table"
                TABLE(n)\push TABLE(v)\clean v
            else
                unless f[v]
                    TABLE(n)\push v
                    f[v] = 0
        return n

    -- makes a shallow copy of an table
    -- http://lua-users.org/wiki/CopyTable
    -- @return table
    shallowcopy: =>
        shallowcopy = (t) ->
            copy = {}
            if type(t) == "table"
                for key, value in pairs t
                    copy[key] = value
            else
                copy = t
            return copy
        return shallowcopy @t

    -- makes a deep copy of an table
    -- http://lua-users.org/wiki/CopyTable
    -- @return table
    deepcopy: =>
        deepcopy = (t, copies = {}) ->
            copy = {}
            if type(t) == "table"
                if copies[t]
                    copy = copies[t]
                else
                    copies[t] = copy
                    for key, value in next, t, nil
                        copy[deepcopy key, copies] = deepcopy value, copies
                    setmetatable copy, deepcopy getmetatable(t), copies
            else
                copy = t
            return copy
        return deepcopy @t

    -- makes a deep or shallow copy of a table
    -- @param deepcopy boolean
    -- @return table
    copy: (deepcopy = true) => deepcopy and @deepcopy! or @shallowcopy!

    -- concatenates values to the end of the table
    -- @param ... any
    -- @return table
    concat: (...) =>
        t = @copy!
        for val in *{...}
            if type(val) == "table"
                for k, v in pairs val
                   TABLE(t)\push(v) if type(k) == "number"
            else
                TABLE(t)\push(val)
        return t

    -- creates a new table populated with the results of calling a provided function on every element in the calling table
    -- @param fn function
    -- @return table
    map: (fn) => {k, fn(v, k, @t) for k, v in pairs @t}

    -- removes the last element from the table
    -- @return integer
    pop: => table.remove @t

    -- adds one or more elements to the end of the table
    -- @param ... any
    -- @return integer
    push: (...) =>
        arguments, insert = {...}, table.insert
        for i = 1, #arguments
            insert @t, arguments[i]
        return #arguments

    -- executes a reducer function on each element of the table
    -- @param fn function
    -- @param ... any
    -- @return table
    reduce: (fn, ...) =>
        arguments, init, len, acc = {...}, 1, #@t, nil
        if #arguments != 0
            acc = arguments[1]
        elseif len > 0
            init, acc = 2, @t[1]
        for i = init, len
            acc = fn acc, @t[i], i, @t
        return acc

    -- Reverses all table values
    -- @return table
    reverse: => [@t[#@t + 1 - i] for i = 1, #@t]

    -- returns a copy of part of an table from a subarray created between the start and end positions
    -- @param f integer
    -- @param l integer
    -- @param s integer
    -- @return table
    slice: (f, l, s) => [@t[i] for i = f or 1, l or #@t, s or 1]

    -- changes the contents of an table by removing or replacing existing elements and/or adding new elements
    -- @param start integer
    -- @param delete integer
    -- @param ... any
    -- @return table
    splice: (start, delete, ...) =>
        arguments, removes, t_len = {...}, {}, #@t
        n_args, i_args = #arguments, 1
        start = start < 1 and 1 or start
        delete = delete < 0 and 0 or delete
        if start > t_len
            start = t_len + 1
            delete = 0
        delete = start + delete - 1 > t_len and t_len - start + 1 or delete
        for pos = start, start + math.min(delete, n_args) - 1
            TABLE(removes)\push @t[pos]
            @t[pos] = arguments[i_args]
            i_args += 1
        i_args -= 1
        for i = 1, delete - n_args
            TABLE(removes)\push table.remove(@t, start + i_args)
        for i = n_args - delete, 1, -1
            @push start + delete, arguments[i_args + i]
        return removes

    -- removes the first element from the table
    -- @return integer
    shift: => table.remove @t, 1

    -- inserts new elements at the start of an table, and returns the new length of the table
    -- @param ... any
    -- @return integer
    unshift: (...) =>
        arguments = {...}
        for k = #arguments, 1, -1
            table.insert @t, 1, arguments[k]
        return #@t

    -- checks if the table is empty
    -- @return boolean
    isEmpty: => next(@t) == nil

    -- returns a string with the contents of the table
    -- @param table_name string
    -- @param indent string
    -- @return string
    view: (table_name = "table_unnamed", indent = "") =>
        cart, autoref = "", ""
        basicSerialize = (o) ->
            so = tostring o
            if type(o) == "function"
                info = debug.getinfo o, "S"
                return format "%q", so .. ", C function" if info.what == "C"
                format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
            elseif (type(o) == "number") or (type(o) == "boolean")
                return so
            format "%q", so
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
                    if TABLE(value)\isEmpty!
                        cart ..= " = {};\n"
                    else
                        cart ..= " = {\n"
                        for k, v in pairs value
                            k = basicSerialize k
                            fname = "#{table_name}[ #{k} ]"
                            field = "[ #{k} ]"
                            addtocart v, fname, indent .. "	", saved, field
                        cart = "#{cart}#{indent}};\n"
        return "#{table_name} = #{basicSerialize @t}" if type(@t) != "table"
        addtocart @t, table_name, indent
        return cart .. autoref

{:TABLE}