-- aka.Sandbox
-- Copyright (c) Akatsumekusa and contributors

------------------------------------------------------------------------------
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------

local versioning = {}

versioning.name = "Sandbox"
versioning.description = "LuaInterpret but raw"
versioning.version = "1.1.4"
versioning.author = "Akatsumekusa and contributors"
versioning.namespace = "aka.Sandbox"

versioning.requiredModules = "[{ \"moduleName\": \"aegisub.re\" }, { \"moduleName\": \"aka.StackTracePlus\" }, { \"moduleName\": \"aka.outcome\" }, { \"moduleName\": \"aka.config\" }, { \"moduleName\": \"aka.uikit\" }, { \"moduleName\": \"ILL.ILL\" }, { \"moduleName\": \"moonscript\" }, { \"moduleName\": \"a-mo.LineCollection\" }, { \"moduleName\": \"l0.ASSFoundation\" }, { \"moduleName\": \"Yutils\" }, { \"moduleName\": \"arch.Math\" }, { \"moduleName\": \"arch.Perspective\" }, { \"moduleName\": \"arch.Util\" }, { \"moduleName\": \"l0.Functional\" }, { \"moduleName\": \"aka.unicode\" }, { \"moduleName\": \"aegisub.util\" }, { \"moduleName\": \"petzku.util\" }]"

script_name = versioning.name
script_description = versioning.description
script_version = versioning.version
script_author = versioning.author
script_namespace = versioning.namespace

DepCtrl = require("l0.DependencyControl")({
    feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json",
    {
        { "aegisub.re" },
        { "aka.StackTracePlus", version = "1.0.0" },
        { "aka.outcome", version = "1.0.0" },
        { "aka.config", version = "1.0.0" },
        { "aka.uikit", version = "1.0.0" },
        { "ILL.ILL", version = "1.0.0" },
        { "moonscript" },
        { "a-mo.LineCollection", version = "1.0.0" },
        { "l0.ASSFoundation", version = "0.1.0" },
        { "Yutils" },
        { "arch.Math", version = "0.1.0" },
        { "arch.Perspective", version = "0.1.0" },
        { "arch.Util", version = "0.1.0" },
        { "l0.Functional", version = "0.1.0" },
        { "aka.unicode", version = "1.0.0" },
        { "aegisub.util" },
        { "petzku.util", version = "0.1.0" }
    }
})

local re, STP, outcome, config, uikit, ILL, moonscript, LineCollection, ASS, yutils, Math, Perspective, Util, Functional, unicode, util, putil = DepCtrl:requireModules()
local file_extension = re.compile([[.*\.([^\\\/]+)$]])
local clean_traceback = re.compile[[(.*?)(?:\([0-9]+\) Lua upvalue '_ao_xpcall')]]
STP()
local o, ok, err = outcome.o, outcome.ok, outcome.err
local _ao_xpcall = outcome.xpcall
local presets_config = config.make_editor({ display_name = "aka.Sandbox/presets",
                                            presets = { ["Default"] = {}, ["Example"] = { ["Example Preset"] = { ["language"] = "MoonScript", ["command"] = "logger\\dump sub[act]" } } },
                                            default = "Default" })
local preset
local dialog_aconfig = config.make_editor({ display_name = "aka.Sandbox/dialog",
                                            presets = { ["Default"] = { ["err_msg_mode"] = "Compact" } },
                                            default = "Default" })
local dialog_config
local adialog, abuttons, adisplay = uikit.dialog, uikit.buttons, uikit.display

local Sandbox = function(sub, sel, act)
    local presets = presets_config:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("aka.Sandbox", "presets", function(config)
        for k, v in pairs(config) do
            if not (type(k) == "string" and
                    type(v) == "table" and
                    (v["language"] == "Lua" or v["language"] == "MoonScript") and
                    type(v["command"] == "string")) then
                return err("Error occurs when parsing key \"" .. tostring(k) .. "\".\nView Preset „Example“ below for an example of the format.")
        end end
        return ok(config) end)
        :ifErr(aegisub.cancel)
        :unwrap()
    if not dialog_config then
        dialog_config = dialog_aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("aka.Sandbox", "dialog", function(config)
            if not (config["err_msg_mode"] == "Compact" or config["err_msg_mode"] == "Bottom" or config["err_msg_mode"] == "Bottom Extended") then
                return err("Error occurs when parsing key \"err_msg_mode\".\nValue „Compact“, „Bottom“, „Bottom Extended“ are supported.")
            end
            return ok(config) end)
            :ifErr(aegisub.cancel)
            :unwrap()
    end

    local dialog = adialog.new({ width = 57 })
    dialog:load_data(dialog_config)

    local left, right = dialog:columns({ widths = { 55, 2 } })
    local full = left:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and data["err_msg_mode"] == "Bottom" end })
    full:textbox({ height = 31, name = "command" })
    local reduced = left:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and data["err_msg_mode"] == "Bottom" end })
    reduced:textbox({ height = 21, name = "command" })

    local err_dialog = right:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and data["err_msg_mode"] == "Compact" end })
    err_dialog:label({ label = "𝗘𝗿𝗿𝗼𝗿 𝗼𝗰𝗰𝘂𝗿𝗿𝗲𝗱 during previous operation:" })
              :textbox({ height = 11, name = "err_msg" })

    right:label({ label = "Select Language:" })
         :dropdown({ name = "language", items = { "Lua", "MoonScript" }, value = "Lua" })

    right:label({ label = "Available variables:" })
    local full = right:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    local fvar, fexp = full:columns({ widths = { 1, 1 } })
    fvar:label({ label = "│ sub:" })                fexp:label({ label = "Subtitle object" })
    fvar:label({ label = "│ sel:" })                fexp:label({ label = "Selected lines" })
    fvar:label({ label = "│ act:" })                fexp:label({ label = "Active line" })
    local brief = right:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    local bvar, bexp = brief:columns({ widths = { 1, 1 } })
    bvar:label({ label = "│ sub, sel, act:" })      bexp:label({ label = "Subtitle object" })

    right:label({ label = "Required libraries:" })
    local var, exp = right:columns({ widths = { 1, 1 } })
    var:label({ label = "│ Ass, Line, Aegi, …:" })  exp:label({ label = "All ILL.ILL classes" })
    var:label({ label = "│ ass:" })                 exp:label({ label = "Ass loaded with subtitle" })
    local full = right:ifable({ name = "language", value = "Lua" })
    local full = full:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    full:label({ label = "─ Remember to ass:getNewSelection()" })
    local full = right:ifable({ name = "language", value = "MoonScript" })
    local full = full:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    full:label({ label = "─ Remember to ass\\getNewSelection!" })
    local var, exp = right:columns({ widths = { 1, 1 } })
    var:label({ label = "│ LineCollection:" })      exp:label({ label = "a-mo.LineCollection" })
    var:label({ label = "│ lines:" })               exp:label({ label = "LineCollection loaded" })
    var:label({ label = "│ ASS:" })                 exp:label({ label = "l0.ASSFoundation" })
    local full = right:ifable({ name = "language", value = "Lua" })
    local full = full:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    full:label({ label = "─ Rmbr data:commit() n lines:replaceLines()" })
    local full = right:ifable({ name = "language", value = "MoonScript" })
    local full = full:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    full:label({ label = "─ Rmbr data\\commit! n lines\\replaceLines!" })
    local var, exp = right:columns({ widths = { 1, 1 } })
    var:label({ label = "│ logger:" })              exp:label({ label = "logger from l0.DepCtrl" })
    var:label({ label = "│ aegisub:" })             exp:label({ label = "aegisub object" })
    var:label({ label = "│ yutils:" })              exp:label({ label = "Yutils" })
    local full = right:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and data["err_msg_mode"] == "Compact" end })
    local fvar, fexp = full:columns({ widths = { 1, 1 } })
    fvar:label({ label = "│ Math:" })               fexp:label({ label = "arch.Math" })
    fvar:label({ label = "│ Perspective:" })        fexp:label({ label = "arch.Perspective" })
    fvar:label({ label = "│ Util:" })               fexp:label({ label = "arch.Util" })
    local brief = right:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and data["err_msg_mode"] == "Compact" end })
    local bvar, bexp = brief:columns({ widths = { 1, 1 } })
    bvar:label({ label = "│ Math, Util, …:" })      bexp:label({ label = "arch1t3cht modules" })
    local full = right:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    local fvar, fexp = full:columns({ widths = { 1, 1 } })
    fvar:label({ label = "│ re:" })                 fexp:label({ label = "aegisub.re (ext)" })
    fvar:label({ label = "│ unicode:" })            fexp:label({ label = "aegisub.unicode (ext)" })
    fvar:label({ label = "│ util:" })               fexp:label({ label = "aegisub.util (ext)" })
    full:label({ label = "─ re and util extended with l0.Functional" })
    full:label({ label = "─ unicode ext with l0.Functional and aka.u" })
    local brief = right:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    local bvar, bexp = brief:columns({ widths = { 1, 1 } })
    bvar:label({ label = "│ re, unicode, util:" })  bexp:label({ label = "Aegisub modules (ext)" })
    local var, exp = right:columns({ widths = { 1, 1 } })
    var:label({ label = "│ list, List:" })          exp:label({ label = "list from l0.Functional" })
    var:label({ label = "│ transform:" })           exp:label({ label = "transform in petzku.util" })

    right:label({ label = "Vanilla libraries:" })
    local full = right:unlessable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    full:label({ label = "─ table and string ext with l0.Functional" })
    full:label({ label = "─ math ext with l0.Functional and petzku.util" })
    full:label({ label = "─ io extended with petzku.util" })
    local brief = right:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Compact" or data["err_msg_mode"] == "Bottom") end })
    local bvar, bexp = brief:columns({ widths = { 1, 1 } })
    bvar:label({ label = "│ table, math, io, …:" }) bexp:label({ label = "(extended)" })

    local err_dialog = dialog:ifable({ name = "err_msg", value = function(err_msg, data) return err_msg and (data["err_msg_mode"] == "Bottom" or data["err_msg_mode"] == "Bottom Extended") end })
    err_dialog:textbox({ height = 10, name = "err_msg" })

    local buttons = abuttons.ok("&Run"):extra("&Load Preset"):extra("&Save As Preset"):extra("&Delete Preset"):extra("Open Sn&ippet"):extra("Save As Snipp&et"):extra("Config"):close("Close")

    local r = adisplay(dialog, buttons)
        :loadRepeatUntilAndSave("aka.Sandbox", "dialog_preset", function(button, result)
            result["err_msg"] = false

            if button == "Config" then
                local dialog = adialog.new({ width = 16 })
                                      :label_dropdown({ label = "Error message display:", name = "err_msg_mode", items = { "Compact", "Bottom", "Bottom Extended" }, value = dialog_config["err_msg_mode"] })
                local buttons = abuttons.ok("Set"):close("Back")
                local b, r = adisplay(dialog, buttons):resolve()
                if buttons:is_ok(b) then
                    dialog_config = r
                    config.write_config("aka.Sandbox", "dialog", dialog_config)
                        :ifErr(function()
                            aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                            aegisub.debug.out("[aka.config] " .. error .. "\n") end)
                    for k, v in pairs(dialog_config) do
                        result[k] = v
                end end
                return err(result)
            elseif button == "&Load Preset" then
                local items = {}
                local preset_available
                for k, _ in pairs(presets) do
                    table.insert(items, k)
                    if not preset_available then preset_available = k end
                    if preset == k then preset_available = preset end
                end
                table.sort(items)
                preset = preset_available
                local dialog = adialog.new({ width = 16 })
                                      :label({ label = "Load preset:" })
                                      :label_dropdown({ label = "Preset:", name = "preset", items = items, value = preset })
                local buttons = abuttons.ok("Load"):close("Back")
                local b, r = adisplay(dialog, buttons):resolve()
                if buttons:is_ok(b) then
                    preset = r["preset"]
                    result["language"] = presets[preset]["language"]
                    result["command"] = presets[preset]["command"]
                end
                return err(result)
            elseif button == "&Delete Preset" then
                local items = {}
                local preset_available
                for k, _ in pairs(presets) do
                    table.insert(items, k)
                    if not preset_available then preset_available = k end
                    if preset == k then preset_available = preset end
                end
                table.sort(items)
                preset = preset_available
                local dialog = adialog.new({ width = 16 })
                                      :label({ label = "Delete preset:" })
                                      :label_dropdown({ label = "Preset:", name = "preset", items = items, value = preset })
                local buttons = abuttons.ok("Delete"):close("Back")
                local b, r = adisplay(dialog, buttons):resolve()
                if buttons:is_ok(b) then
                    presets[r["preset"]] = nil
                    presets_config.write_config("aka.Sandbox", "presets", presets)
                        :ifErr(function(msg)
                            result["err_msg"] = "Error occurred when updating presets:\n" ..
                                                msg end)
                end
                return err(result)
            elseif button == "&Save As Preset" then
                local items = {}
                local preset_available
                for k, _ in pairs(presets) do
                    table.insert(items, k)
                    if not preset_available then preset_available = k end
                    if preset == k then preset_available = preset end
                end
                table.sort(items)
                preset = preset_available
                local dialog = adialog.new({ width = 16 })
                dialog:label({ label = "S͟a͟v͟e as preset:" })
                dialog:label_edit({ label = "Preset name:", name = "save_preset" })
                dialog:label({ label = "O͟v͟e͟r͟w͟r͟i͟t͟e selected preset:" })
                dialog:label_dropdown({ label = "Preset:", name = "overwrite_preset", items = items, value = preset })
                local buttons = abuttons.ok("Save"):button("Overwrite"):close("Back")
                local b, r = adisplay(dialog, buttons):resolve()
                if not buttons:is_close(b) then
                    if b == "Save" then preset = r["save_preset"]
                    else preset = r["overwrite_preset"] end
                    presets[preset] = {}
                    presets[preset]["language"] = result["language"]
                    presets[preset]["command"] = result["command"]
                    presets_config.write_config("aka.Sandbox", "presets", presets)
                        :ifErr(function(msg)
                            result["err_msg"] = "Error occurred when saving presets:\n" ..
                                                msg end)
                end
                return err(result)
            elseif button == "Open Sn&ippet" then
                o(aegisub.dialog.open("Opening snippet...", "", "", ""))
                    :ifOk(function(path)
                        o(io.open(path, "r"))
                            :andThen(function(f)
                                local r = o(f:read("*a"))
                                    :ifOk(function(t)
                                        result["command"] = t
                                        local ext = file_extension:match(path)[2]["str"]
                                        if string.lower(ext) == "lua" then
                                            result["language"] = "Lua"
                                        elseif string.lower(ext) == "moon" then
                                            result["language"] = "MoonScript"
                                        end end)
                                f:close() return
                                r end)
                            :ifErr(function(msg)
                                result["err_msg"] = "Error occurred when opening snippet:\n" ..
                                                    msg end) end) return
                err(result)
            elseif button == "Save As Snipp&et" then
                o(aegisub.dialog.save("Saving as snippet...", "", "", ""))
                    :ifOk(function(f)
                        o(io.open(f, "w"))
                            :andThen(function(f)
                                local r = o(f:write(result["command"]))
                                f:close() return
                                r end)
                            :ifErr(function(msg)
                                result["err_msg"] = "Error occurred when saving snippet:\n" ..
                                                    msg end) end) return
                err(result)
            else -- button == "Run"
                local gt = setmetatable({}, { __index = _G })
                local mmt = function(...)
                    local t = table.pack(...)
                    return { __index = function(self, key)
                        for _, v in ipairs(t) do
                            if v[key] then
                                return v[key]
                        end end end }
                end
                gt.sub = sub
                gt.sel = sel
                gt.act = act
                for k, v in pairs(ILL) do
                    if not string.find(k, "version") then
                        gt[k] = v
                end end
                gt.ass = ILL.Ass(sub, sel, act)
                gt.LineCollection = LineCollection
                gt.lines = LineCollection(sub, sel)
                gt.ASS = ASS
                gt.logger = DepCtrl:getLogger()
                gt.aegisub = aegisub
                gt.yutils = yutils
                gt.Math = Math
                gt.Perspective = Perspective
                gt.Util = Util
                gt.re = setmetatable({}, mmt(re, Functional.re))
                gt.unicode = setmetatable({}, mmt(unicode, Functional.unicode))
                gt.util = setmetatable({}, mmt(util, Functional.util))
                gt.List = Functional.List
                gt.list = Functional.list
                gt.transform = putil.transform
                gt.table = setmetatable({}, mmt(table, Functional.table))
                gt.string = setmetatable({}, mmt(string, Functional.string))
                gt.math = setmetatable({}, mmt(math, Functional.math, putil.math))
                gt.io = setmetatable({}, mmt(io, putil.io))

                local r
                if result["language"] == "Lua" then
                    r = o(loadstring(result["command"]))
                else
                    r = o(moonscript.loadstring(result["command"]))
                end
                if r:isErr() then
                    result["err_msg"] = "Error occurred during loadstring():\n" ..
                                        r:unwrapErr()
                    return err(result)
                end
                local f = r:unwrap()
                setfenv(f, gt)

                r = _ao_xpcall(f, function(err)
                    local traceback = debug.traceback(err)
                    local match = clean_traceback:match(traceback)
                    if match then
                        traceback = match[2]["str"]
                    end
                    result["err_msg"] = "Error occurred during execution:\n" .. traceback end)
                if r:isOk() then
                    r = r:unwrap()
                    if type(r) == "table" then
                        result[1] = r[1] result[2] = r[2]
                    end
                    return ok(result)
                else
                    if r:unwrapErr() ~= nil then
                        result["err_msg"] = "Error occured in aka.Sandbox's code.\n" ..
                                            "For this error message to display, this is what has happened:\n" ..
                                            "First, an error occured during execution of the provided script.\n" ..
                                            "At this point, aka.Sandbox cancelled the execution and started collecting debug info such as where exactly the error occured in the provided script.\n" ..
                                            "However, a new error occured in the code that's responsible for collecting debug info:\n" ..
                                            tostring(r:unwrapErr())
                    end
                    return err(result)
            end end end)

    if r:isOk() then
        r = r:unwrap()
        if type(r) == "table" then
            return r[1], r[2]
end end end

DepCtrl:registerMacro(Sandbox)
