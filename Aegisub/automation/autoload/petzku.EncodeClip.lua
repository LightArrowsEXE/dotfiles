-- Copyright (c) 2020, petzku <petzku@zku.fi>
-- Copyright (c) 2020, The0x539 <the0x539@gmail.com>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED 'AS IS' AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

--[[ README

# Encode Clip

Uses mpv to encode a clip of the current selection.
The mpv executable *must* be either on your PATH, or specified in the configuration dialog!

Macros and GUI should be self-explanatory.

Video and audio are taken from the file(s) loaded into Aegisub, and subtitles from the active script.

I don't know of a way to get the currently active audio track's ID from Aegisub, so dual audio may not work correctly.
You can remedy this by specifying the audio track in the configuration dialog. For example:
`--aid=2` to select the second audio track, or `--alang=jpn` to select the first japanese audio track

]]

local tr = aegisub.gettext

script_name = tr'Encode Clip'
script_description = tr'Encode various clips from the current selection'
script_author = 'petzku'
script_namespace = "petzku.EncodeClip"
script_version = '1.2.2'


local haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
local ConfigHandler, config, petzku
if haveDepCtrl then
    depctrl = DependencyControl {
        feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json",
        {
            {"petzku.util", version="0.5.2", url="https://github.com/petzku/Aegisub-Scripts",
             feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"},
            {"a-mo.ConfigHandler", version="1.1.4", url="https://github.com/TypesettingTools/Aegisub-Motion",
             feed="https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"}
        }
    }
    petzku, ConfigHandler = depctrl:requireModules()
else
    petzku = require 'petzku.util'
end

local config_diag = {
    main = {
        exe_label = {
            class='label', label="mpv path:",
            x=0, y=0, width=2, height=1
        },
        mpv_exe = {
            class='edit', value="", config=true,
            x=2, y=0, width=18, height=1,
            hint=[[Path to the mpv executable.
If left blank, searches system PATH.]]
        },
        audio_encoder_label = {
            class='label', label='Audio encoder. Defaults to best available AAC.',
            x=0, y=1, width=10, height=1
        },
        audio_encoder = {
            class='edit', value="", config=true,
            x=10, y=1, width=10, height=1,
            hint=[[Audio encoder to use.
If left blank, automatically picks the best available AAC encoder.
Note that you may need to change --oacopts if you use a non-AAC encoder.]]
        },
        use_aid = {
            class='checkbox', value=false, config=true,
            label='&Audio track to use (only applies if checkbox checked)',
            x=0, y=2, width = 15, height = 1,
            hint=[[Enable forcing audio track.
If unset, mpv will fallback to its defaults (which might decide based on user locale), unless the settings above override it.
If set, the value given to the right will be supplied to --aid.]]
        },
        aid = {
            class='intedit', value=2, config=true, min=1, max=128,
            x=15, y=2, width=5, height=1,
            hint=[[Audio track ID to use.
Supplied to mpv as --aid, so this is indexed starting from 1. Supplying an out-of-bounds track ID will cause no audio to be included.
If you want to consistently select by language, just use --alang in the config sections above.]]
        },
        context_duration_label = {
            class='label', label='Extra context duration for clips (in seconds):',
            x=0, y=3, width=10, height=1
        },
        context_duration = {
            class='floatedit', value=2, config=true, min=0, max=30,
            x=10, y=3, width=10, height=1,
            hint=[[Extra duration (in seconds) to add at the start and end of a clip. Limited to 30 seconds.]]
        },
        video_command_label = {
            class='label', label='Custom mpv options for video clips:',
            x=0, y=4, width=10, height=1
        },
        video_command = {
            class='textbox', value="", config=true,
            x=0, y=5, width=20, height=3,
            hint=[[Custom command line options passed to mpv when encoding video.
You can put options on separate lines, but all options must be prefixed with --. (e.g. "--aid=2" to pick the second audio track in the file)]]
        },
        audio_command_label = {
            class='label', label='Custom mpv options for audio-only clips:',
            x=0, y=8, width=10, height=1
        },
        audio_command = {
            class='textbox', value="", config=true,
            x=0, y=9, width=20, height=3,
            hint=[[Custom command line options passed to mpv when encoding only audio.
Options here do NOT get applied when encoding video, whether it has audio or not.]]
        }
    }
}
local GUI = {
    main = {
        settings_label = {
            class='label', label=tr"Settings for video clip: ",
            x=0, y=0
        },
        subs = {
            class='checkbox', label=tr"&Subs", value=true, name='subs',
            x=1, y=0,
            hint=tr[[Enable subtitles in output]]
        },
        audio = {
            class='checkbox', label=tr"&Audio", value=true, name='audio',
            x=2, y=0,
            hint=tr[[Enable audio in output]]
        },
        context = {
            class='checkbox', label=tr"Conte&xt", value=false, name='context',
            x=3, y=0,
            hint=tr[[Include a few seconds of context at the start and end of the clip]]
        }
    },
    -- constants for the buttons
    BUTTONS = {
        AUDIO = tr"Audio-&only clip",
        VIDEO = tr"&Video clip",
        CONFIG = tr"&Config",
        CANCEL = tr"Ca&ncel"
    },
    -- varargs to add potential other buttons. OK (`proceed`) is still the default in the displayed box
    show_user_warning = function(title, desc, proceed, ...)
        return aegisub.dialog.display(
            {
                {class="label", label=title, x=0, y=0},
                {class="label", label=desc, x=0, y=1}
            },
            {proceed, ..., "Ca&ncel"},
            {ok = proceed, cancel = "Ca&ncel"}
        )
    end
}
-- IO functions
local LOGGER = petzku.io

if haveDepCtrl then
    config = ConfigHandler(config_diag, depctrl.configFile, false, script_version, depctrl.configDir)
end

local function get_configuration()
    if haveDepCtrl then
        config:read()
        config:updateInterface("main")
    end
    -- this seems hacky, maybe use depctrl's confighandler instead
    local opts = {}
    for key, values in pairs(config_diag.main) do
        if values.config then
            opts[key] = values.value
        end
    end
    return opts
end

local function get_mpv()
    local user_opts = get_configuration()
    local mpv_exe
    if user_opts.mpv_exe and user_opts.mpv_exe ~= '' then
        mpv_exe = user_opts.mpv_exe
        LOGGER.trace("Found user-configured mpv: %s", mpv_exe)
        if mpv_exe:match(" ") and not mpv_exe:match("['\"]") then
            -- spaces but no quotes
            mpv_exe = '"'..mpv_exe..'"'
            LOGGER.trace("Added quotes around executable path: %s", mpv_exe)
        end
    else
        mpv_exe = 'mpv'
    end
    return mpv_exe
end

-- query mpv for `mpv --<option>=help`. makes no attempt to sanitize option, being an internal function
local function get_help_lines(option)
    local t = {}
    local mpv = get_mpv()
    for line in petzku.io.run_cmd(mpv .. " --"..option.."=help", true):gmatch("[^\r\n]+") do
        table.insert(t, line)
    end
    -- return an iterator because it's nicer
    local i = 0
    return function()
        i = i + 1
        if i < #t then return t[i] end
    end
end

-- Use user-specified encoder, if one exists.
-- Otherwise, find the best AAC encoder available to us, since ffmpeg-internal is Bad
-- mpv *should* support --oac="aac_at,aac_mf,libfdk_aac,aac", but it doesn't so we do this
local audio_encoder = nil
local function get_audio_encoder()
    if audio_encoder ~= nil then
        LOGGER.trace("Found preferred encoder: %s", audio_encoder)
        return audio_encoder
    end

    local opt = get_configuration()
    if opt.audio_encoder and opt.audio_encoder ~= "" then
        LOGGER.trace("Using user-specified encoder: %s", opt.audio_encoder)
        return opt.audio_encoder
    end

    local priorities = {aac = 0, libfdk_aac = 1, aac_mf = 2, aac_at = 3}
    local best = "aac"
    for line in get_help_lines("oac") do
        local enc = line:match("--oac=(%S*aac%S*)")
        if enc then
            LOGGER.trace("Found AAC encoder: %s", enc)
            if priorities[enc] and priorities[enc] > priorities[best] then
                LOGGER.trace("Better than previous best (%s)", best)
                best = enc
            end
        end
    end
    audio_encoder = best
    return best
end

local _should_encode_libx264 = nil
local function check_libx264_support()
    LOGGER.trace("Checking libx264 support...")
    if _should_encode_libx264 then
        LOGGER.trace("Supported or prior user override, skipping")
        return _should_encode_libx264
    end
    for line in get_help_lines("ovc") do
        if line:match("--ovc=libx264") then
            LOGGER.trace("Found libx264 encoder")
            _should_encode_libx264 = true
            return _should_encode_libx264
        end
    end

    LOGGER.trace("No libx264 encoder found! Warning user...")

    btn, _ = GUI.show_user_warning("Warning: libx264 not found!", [[Encoded clips will likely be broken.
Please install a version of mpv that supports libx264.]], "Encode &anyway")
    if btn then
        LOGGER.trace("User overriding encoding for this session")
        _should_encode_libx264 = true
    end

    return _should_encode_libx264
end

local function get_base_outfile(t1, t2, ext)
    LOGGER.trace("Generating base outfile name")
    local outfile, cant_hardsub
    if aegisub.decode_path("?script") == "?script" then
        -- no script file to work with, save next to source video instead
        outfile = aegisub.project_properties().video_file
        cant_hardsub = true
        LOGGER.trace("No script loaded, using loaded video path: %s", outfile)
    else
        outfile = aegisub.decode_path("?script") .. petzku.io.pathsep .. aegisub.file_name()
    end
    outfile = outfile:gsub('%.[^.]+$', '') .. string.format('_%.3f-%.3f', t1, t2) .. '.' .. ext

    return outfile, cant_hardsub
end

local function calc_start_end(subs, sel, ctx)
    local t1, t2 = math.huge, 0
    for _, i in ipairs(sel) do
        t1 = math.min(t1, subs[i].start_time)
        t2 = math.max(t2, subs[i].end_time)
    end
    if ctx then
        local ctx_dur = math.floor(get_configuration().context_duration * 1000)
        t1 = math.max(0, t1 - ctx_dur)
        t2 = t2 + ctx_dur
    end
    return t1/1000, t2/1000
end

local function gen_lavfi_cmd(dummystr)
    -- sample dummy string: ?dummy:24000\1001:140000:640:480:47:163:254:c
    -- syntax: ?dummy:<fps>:<duration>:<width>:<height>:<R:G:B>:<checkerboard?>
    -- "c" if checker, "" if not. we ignore that entirely as lavfi can't nicely generate it.

    local fps, w, h, r, g, b = dummystr:match("dummy:([^:]+):[^:]+:([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):")

    local color = string.format("0x%02x%02x%02x", r,g,b)

    -- aegisub uses \ instead of / for the fps divisor on windows for the exact reason you would think
    fps = fps:gsub("\\", "/")

    return string.format("av://lavfi:color=c=%s:s=%dx%d:r=%s", color, w, h, fps)
end

local function is_ascii(str)
    for i=1, #str do
        if str:byte(i) > 128 then
            return false
        end
    end
    return true
end

local function run_cmd(cmd)
    -- run the encode command, alerting with possible fixes in the case of an error
    local output = petzku.io.run_cmd(cmd)

    local WINDOWS_ASCII_ERROR_TEXT = "No such file or directory"
    if output:find(WINDOWS_ASCII_ERROR_TEXT) and not is_ascii(cmd) then
        LOGGER.warn("")
        LOGGER.warn("It looks like some of your input or output file names contain non-ASCII characters, which can break on some systems.")
        LOGGER.warn("Setting your system to use UTF-8 codepages may solve this issue; see https://superuser.com/a/1451686.")
        LOGGER.warn("")
    end
end

local function build_cmd(user_opts, ...)

    local opts = {}
    for _, optset in ipairs(table.pack(...)) do
        for _, o in ipairs(optset) do
            table.insert(opts, o)
        end
    end

    if #opts > 0 then
        LOGGER.trace("Building command with options: %s", table.concat(opts, ' '))
    end

    -- format strings will be handled by caller
    local cmd_table = {
        get_mpv(),
        '--no-config',
        '--start=%.3f',
        '--end=%.3f',
        '"%s"',
        '--o="%s"',
        -- all options supplied as varargs
        table.concat(opts, ' ')
    }

    -- force audio track
    local cfg = get_configuration()
    if cfg.use_aid then
        table.insert(cmd_table, "--aid=" .. cfg.aid)
        LOGGER.trace("Specifying audio track number %d", cfg.aid)
    end

    -- user options, if relevant. these are allowed to override aid setting above
    if user_opts and user_opts ~= "" then
        -- these extra parentheses are required to drop the "made X replacements" return value of gsub.
        -- which gives table.insert a third argument, and makes it error since the second argument is an optional index.
        -- in the middle of a function call, from what should by all rights be a single argument.
        -- this is the worst feature ever.
        table.insert(cmd_table, (user_opts:gsub("\n", " ")))
        LOGGER.trace("Added user options: %s", cmd_table[#cmd_table])
    end

    return table.concat(cmd_table, ' ')
end

function make_clip(subs, sel, hardsub, audio, context)
    if audio == nil then audio = true end --encode with audio by default

    -- check user's libx264 support. only happens once if the user says to proceed, but reminds on every restart
    if not check_libx264_support() then return end

    local t1, t2 = calc_start_end(subs, sel, context)

    local props = aegisub.project_properties()
    local vidfile = props.video_file
    local subfile = aegisub.decode_path("?script") .. petzku.io.pathsep .. aegisub.file_name()

    local outfile, cant_hardsub = get_base_outfile(t1, t2, 'mp4')
    if cant_hardsub then hardsub = false end

    -- if using dummy video, parse the props into a lavfi command
    if vidfile:sub(1,7) == "?dummy:" then
        -- if we have no sub file to work with, can't use video file as output name either
        if cant_hardsub then
            LOGGER.warn("Cannot encode clip from dummy video and no subtitle file!")
            LOGGER.warn("Exiting...")
            return
        end
        vidfile = gen_lavfi_cmd(vidfile)
        LOGGER.trace("Dummy video loaded, generated lavfi filtergraph: %s", vidfile)
    end

    if hardsub and aegisub.gui and aegisub.gui.is_modified and aegisub.gui.is_modified() then
        -- warn user about script not being saved
        if not GUI.show_user_warning("File not saved!", [[Current script file has not been saved.
You probably wanted to save first.
Press Enter to proceed anyway, or Escape to cancel.]], "Encode &anyway") then
            return
        end
    end

    local postfix = ""

    local audio_opts
    if audio then
        -- If audio is not loaded, this property is blank (an empty string).
        -- We assume the user is more likely to want audio from the video file than none at all, if they requested a clip with audio.
        local audiofile = props.audio_file ~= "" and props.audio_file or props.video_file

        audio_opts = {
            '--oac=' .. get_audio_encoder(),
            '--oacopts="b=256k,frame_size=1024"'
        }
        if audiofile ~= vidfile then
            table.insert(audio_opts, string.format('--audio-file="%s"', audiofile))
        end
    else
        audio_opts = { '--audio=no' }
        postfix = postfix .. "_noaudio"
    end

    local sub_opts
    if hardsub then
        sub_opts = {
            string.format('--sub-file="%s"', subfile)
        }
    else
        sub_opts = { '--sid=no' }
        postfix = postfix .. "_nosub"
    end

    -- we force libx264 as this is generally the fastest and most reliable encoder available
    -- to my knowledge, only some macos mpv builds do not come with bundled support
    -- user gets warned at the start of make_clip if they do not have mpv with support
    local video_opts = {
        '--vf=format=yuv420p',
        '--ovc=libx264',
        '--ovcopts="profile=main,level=4.1,crf=23"',
    }

    local user_opts = get_configuration().video_command

    if postfix ~= '' then
        outfile = outfile:sub(1, -5) .. postfix .. '.mp4'
    end
    local cmd = build_cmd(user_opts, video_opts, audio_opts, sub_opts)
                :format(t1, t2, vidfile, outfile)
    run_cmd(cmd)
end

function make_audio_clip(subs, sel, context)
    local t1, t2 = calc_start_end(subs, sel, context)

    local props = aegisub.project_properties()
    local audiofile = props.audio_file

    local outfile = get_base_outfile(t1, t2, 'm4a')

    local user_opts = get_configuration().audio_command

    local video_opts = { '--video=no' }
    local audio_opts = {
        '--oac=' .. get_audio_encoder(),
        '--oacopts="b=256k,frame_size=1024"'
    }

    local cmd = build_cmd(user_opts, video_opts, audio_opts)
                :format(t1, t2, audiofile, outfile)
    run_cmd(cmd)
end

function show_dialog(subs, sel)
    local buttons = haveDepCtrl and {
        GUI.BUTTONS.AUDIO, GUI.BUTTONS.VIDEO, GUI.BUTTONS.CONFIG, GUI.BUTTONS.CANCEL
    } or {
        GUI.BUTTONS.AUDIO, GUI.BUTTONS.VIDEO, GUI.BUTTONS.CANCEL
    }
    local btn, values = aegisub.dialog.display(GUI.main, buttons, {ok=GUI.BUTTONS.VIDEO, cancel=GUI.BUTTONS.CANCEL})

    if btn == GUI.BUTTONS.AUDIO then
        make_audio_clip(subs, sel, values.context)
    elseif btn == GUI.BUTTONS.VIDEO then
        make_clip(subs, sel, values.subs, values.audio, values.context)
    elseif btn == GUI.BUTTONS.CONFIG then
        show_config_dialog()
        -- once config is done, re-open this dialog
        show_dialog(subs, sel)
    end
end

function show_config_dialog()
    config:read()
    config:updateInterface("main")
    local button, result = aegisub.dialog.display(config_diag.main)
    if button then
        config:updateConfiguration(result, 'main')
        config:write()
        config:updateInterface('main')
    end
end

function make_hardsub_clip(subs, sel, _)
    make_clip(subs, sel, true, true)
end

function make_raw_clip(subs, sel, _)
    make_clip(subs, sel, false, true)
end

function make_hardsub_clip_muted(subs, sel, _)
    make_clip(subs, sel, true, false)
end

function make_raw_clip_muted(subs, sel, _)
    make_clip(subs, sel, false, false)
end

local macros = {
    {tr'Clip with subtitles',   tr'Encode a hardsubbed clip encompassing the current selection', make_hardsub_clip},
    {tr'Clip raw video',        tr'Encode a clip encompassing the current selection, but without subtitles', make_raw_clip},
    {tr'Clip with subtitles (no audio)',tr'Encode a hardsubbed clip encompassing the current selection, but without audio', make_hardsub_clip_muted},
    {tr'Clip raw video (no audio)',     tr'Encode a clip encompassing the current selection of the video only', make_raw_clip_muted},
    {tr'Clip audio only',       tr'Clip just the audio for the selection', make_audio_clip},
    {tr'Clipping GUI',          tr'GUI for all your video/audio clipping needs', show_dialog}
}
if haveDepCtrl then
    -- configuration support for depctrl only
    table.insert(macros, {tr'Config', tr'Open configuration menu', show_config_dialog})
    depctrl:registerMacros(macros)
else
    for _,macro in ipairs(macros) do
        local name, desc, fun = unpack(macro)
        aegisub.register_macro(script_name .. '/' .. name, desc, fun)
    end
end
