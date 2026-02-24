[[
README

A bunch of different utility functions I use all over the place.
Or maybe I don't. But that's the plan, at least.

Anyone else is free to use this library too, but most of the stuff is specifically for my own stuff.
]]

haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'
local util, re
if haveDepCtrl
    depctrl = DependencyControl {
        name: 'petzkuLib',
        version: '0.5.3',
        description: [[Various utility functions for use with petzku's Aegisub macros]],
        author: "petzku",
        url: "https://github.com/petzku/Aegisub-Scripts",
        feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
        moduleName: 'petzku.util',
        {
            "aegisub.util", "aegisub.re"
        }
    }
    util, re = depctrl\requireModules!
else
    util = require "aegisub.util"
    re = require "aegisub.re"

-- "\" on windows, "/" on any other system
pathsep = package.config\sub 1,1

lib = {}
with lib
    .math = {
        log_n: (base, x) ->
            math.log(x) / math.log(base)

        clamp: (x, low, high) ->
            math.min(math.max(low, x), high)
    }

    .transform = {
        -- Calculate the accel value required to make a transform match the midpoint of an arbitrary function
        --   logic borrowed from logarithm:
        --   Assumed ASS accel curve:
        --     ratio = ((t - t0) / (t1 - t0)) ^ accel
        --     value = val0 + (val1 - val0) * ratio
        --   Ratio range is 0-1 so exponent just curves it.
        --   knowns:
        --     value = valHalf
        --     ((t - t0) / (t1 - t0)) = 0.5
        --   since we're halfway through the timestep, so:
        --     ratio = 0.5 ^ accel
        --   place the knowns into the latter equation:
        --     valHalf = val0 + (val1 - val0) * 0.5 ^ accel
        --     (valHalf - val0) / (val1 - val0) = 0.5 ^ accel
        --     log_0.5( (valHalf - val0) / (val1 - val0) ) = log_0.5(0.5^accel) = accel
        calc_accel: (val0, valhalf, val1) ->
            accel = .math.log_n 0.5, math.abs (valhalf - val0) / (val1 - val0)
            -- clamp to a sensible interval just in case
            .io.trace "Raw computed accel value for %s,%s,%s: %s", val0, valhalf, val1, accel
            .math.clamp accel, 0.01, 100

        -- Retime transforms, move tags and fades
        -- Params:
        --   line: Either a line object or a string.
        --         A line object should be karaskel preproc'd (does it need to be?).
        --         If a string, duration should be given, or simple (line start to line end) tags can't be shifted
        --   delta: Time in milliseconds to shift the transform.
        --          Positive values will shift forward, negative will shift backward.
        --          i.e. delta should be original_start_time - new_start_time
        --   duration: Duration of the line. Ignored if a line object is supplied.
        retime: (line, delta, duration) ->
            str = line
            if type(line) == 'table'
                .io.trace "Given line table, reading properties from line"
                line = util.copy line
                duration = line.end_time - line.start_time
                str = line.text
                .io.trace "Duration: %s", duration
            elseif not duration
                .io.warn "Duration not given for string input, simple tags cannot be shifted"

            -- \t and \move treat t2=0 as "end-of-line" rather than start
            -- no other values get special handling like this (except double-negative \move mentioned below)
            fix_zero_t2 = (t2) ->
                if t2 == "0"
                    duration
                else
                    t2

            -- rt = retime, s = simple, a = accel
            rt_t = (t1, t2) -> string.format "\\t(%d,%d,", t1+delta, fix_zero_t2(t2)+delta
            rt_at = (a) -> rt_t(0, duration) .. a .. ",\\"
            rt_st = () -> rt_t(0, duration) .. "\\"
            rt_move = (x,y,xx,yy,t1,t2) -> string.format "\\move(%s,%s,%s,%s,%d,%d)", x,y,xx,yy, t1+delta, fix_zero_t2(t2)+delta
            rt_smove = (x,y,xx,yy) -> rt_move x,y,xx,yy,0,duration
            rt_fade = (a1,a2,a3,t1,t2,t3,t4) -> string.format "\\fade(%s,%s,%s,%d,%d,%d,%d)", a1,a2,a3, t1+delta, t2+delta, t3+delta, t4+delta
            rt_sfade = (t_start, t_end) -> rt_fade 255,0,255, 0,t_start, duration-t_end,duration

            n = "[-%d.]+"
            -- p = pattern, s = simple, a = accel
            p_t     = "\\t%(("..n.."),("..n.."),"
            p_at    = "\\t%(("..n.."),\\"
            p_st    = "\\t%(\\"
            p_move  = "\\move%(("..n.."),("..n.."),("..n.."),("..n.."),("..n.."),("..n..")%)"
            p_smove = "\\move%(("..n.."),("..n.."),("..n.."),("..n..")%)"
            p_fade  = "\\fade?%(("..n.."),("..n.."),("..n.."),("..n.."),("..n.."),("..n.."),("..n..")%)"
            p_sfade = "\\fade?%(("..n.."),("..n..")%)"

            .io.trace "Shifting: %s", str
            str = str\gsub(p_t, rt_t)\gsub(p_move, rt_move)\gsub(p_fade, rt_fade)
            if duration
                .io.trace "Shifting simple tags: %s", str
                str = str\gsub(p_at, rt_at)\gsub(p_st, rt_st)\gsub(p_smove, rt_smove)\gsub(p_sfade, rt_sfade)

            -- if move has two negative times, it behaves as if the times were both omitted.
            -- i.e. \move(x,y,xx,yy,-123,-456) is treated the same as \move(x,y,xx,yy).
            -- it _should_ just act the same as `\pos(xx,yy)`, so replace it with that.
            if str\match "\\move%([^)]+%-%d+,%-%d+%)"
                .io.trace "Replacing negative-times move with pos: %s", str
                str = str\gsub "\\move%("..n..","..n..",("..n.."),("..n.."),%-%d+,%-%d+%)", "\\pos(%1,%2)"

            .io.trace "Result: %s", str

            if type(line) == 'table'
                .io.trace "Returning modified line"
                line.text = str
                line
            else
                .io.trace "Returning line text only"
                str
    }

    .io = {
        :pathsep,
        run_cmd: (cmd, quiet) ->
            -- if quiet, we want to silence debug logs
            -- but trace output is always good to have
            LOG = quiet and .io.trace or .io.debug
            LOG 'Running: %s', cmd

            local runner_path
            output_path = os.tmpname()
            .io.trace "Using output file: %s", output_path
            if pathsep == '\\'
                -- windows
                -- command lines over 256 bytes don't get run correctly, make a temporary file as a workaround
                runner_path = aegisub.decode_path('?temp/petzku.bat')
                wrapper_path = aegisub.decode_path('?temp/petzku-wrapper.bat')
                exit_code_path = os.tmpname()
                -- provided by https://sourceforge.net/projects/unxutils/
                tee_path = "#{re.match(debug.getinfo(1).source, '@?(.*[/\\\\])')[1].str}util/tee"
                -- create wrapper
                f = io.open wrapper_path, 'w'
                f\write "@echo off\n"
                f\write "call %*\n"
                f\write "echo %errorlevel% >\"#{exit_code_path}\"\n"
                f\close!
                -- create batch script
                f = io.open runner_path, 'w'
                f\write "@echo off\n"
                f\write "call \"#{wrapper_path}\" #{cmd} 2>&1 | \"#{tee_path}\" \"#{output_path}\"\n"
                f\write "set /p errorlevel=<\"#{exit_code_path}\"\n"
                f\write "exit /b %errorlevel%\n"
                f\close!
            else
                runner_path = aegisub.decode_path('?temp/petzku.sh')
                -- create shell script
                f = io.open runner_path, 'w'
                f\write "#!/bin/sh\n"
                f\write "#{cmd} >\"#{output_path}\" 2>&1\n"
                f\write "exit $?\n"
                f\close!
                -- make the script executable
                os.execute "chmod +x \"#{runner_path}\""

            .io.trace "Using runner file: %s", runner_path
            
            -- status is true if **successful**, unlike with system(3)
            status, reason, exit_code = os.execute runner_path

            f = io.open output_path
            output = f\read '*a'
            f\close!

            LOG = .io.error unless status
            LOG "Command Logs:"
            LOG ""
            LOG output
            if status
                LOG "Status: success"
            else
                LOG "Status: failed"
                LOG "Reason: #{reason}"
                LOG "Exit Code: #{exit_code}"
                LOG ""
            LOG 'Finished: %s', cmd

            output, status, reason, exit_code

        -- handy helper functions for less effort console output
        fatal: (s, ...) -> aegisub.log 0, s.."\n", ...
        error: (s, ...) -> aegisub.log 1, s.."\n", ...
        warn:  (s, ...) -> aegisub.log 2, s.."\n", ...
        hint:  (s, ...) -> aegisub.log 3, s.."\n", ...
        debug: (s, ...) -> aegisub.log 4, s.."\n", ...
        trace: (s, ...) -> aegisub.log 5, s.."\n", ...

        -- function akin to lua's internal "print", separating entries by tabs
        print: (...) -> aegisub.log (string.rep "%s\t", #{...}-1).."%s\n", ...

    }

if haveDepCtrl
    lib.version = depctrl
    return depctrl\register lib
else
    return lib
