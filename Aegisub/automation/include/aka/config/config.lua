-- aka.config
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

local config = require("aka.config2")
local outcome = require("aka.outcome")
local ok, err, some, none, o = outcome.ok, outcome.err, outcome.some, outcome.none, outcome.o
local unicode = require("aka.unicode")
local re = require("aegisub.re")

local config_methods = {}
config_methods.__index = config_methods
setmetatable(config_methods, { __index = config })

-------------------------------------------------
-- Create config GUI.
--
-- config itself is setmetatable to config2 so all the config2 functions will be able to used without initialising config GUI
-- 
-- @param table param:
--     display_name: The display name of your script / config
--     width [32]: The width for a column (two columns in total)
--     height [20]: The height of a column
--     presets: Every presets in a key-value table
--     default: The name (key) of the default preset
-- 
-- @return table: an instance of config with GUI functions
config.make_editor = function(param)
    local codepoint
    
    local self = setmetatable({}, config_methods)
    self.display_name = param.display_name
    self.display_name_b = ""
    for char in unicode.chars(param.display_name) do
        codepoint = unicode.codepoint(char)
        if 0x0041 <= codepoint and codepoint <= 0x005A then
            codepoint = codepoint + 0x1D593
        elseif 0x0061 <= codepoint and codepoint <= 0x007A then
            codepoint = codepoint + 0x1D58D
        elseif 0x0030 <= codepoint and codepoint <= 0x0039 then
            codepoint = codepoint + 0x1D7BC
        end
        self.display_name_b = self.display_name_b .. unicode.char(codepoint)
    end
    self.width = param.width or 32
    self.height = param.height or 20
    self.presets = param.presets
    self.preset_names = {}
    for k, _ in pairs(param.presets) do
        table.insert(self.preset_names, k)
    end
    self.default = param.default

    return self
end

-------------------------------------------------
-- Edit config GUI.
--
-- This function will only return with valid JSON (before validation function) or the user click cancel
-- 
-- @param outcome.Option<string, string> config_string: config JSON
-- @param outcome.Option<string, string> error: Errors probably coming from validation function
-- @param function validation_func [optional]: Validation function
-- 
-- @return outcome.result<string, string>: Return the new config_string
config_methods.edit_config = function(self, config_string, error, validation_func)
    local dialog
    local buttons
    local button_ids
    local button
    local result_table
    local config_text
    local preset_name
    local config_data

    if not validation_func then validation_func = function(config_data) return ok(config_data) end end

    config_text = config_string:unwrapOr("")
    preset_name = self.default
    while true do
        error = error
            :mapOr({}, function(error) return
                re.split(error, "\n") end)
            :unwrap()
        dialog = { { class = "label",                           x = 0, y = 0, width = self.width,
                                                                label = (config_string:isSome() and "𝗘𝗱𝗶𝘁" or "𝗖𝗿𝗲𝗮𝘁𝗲") .. " 𝗖𝗼𝗻𝗳𝗶𝗴 𝗳𝗼𝗿 " .. self.display_name_b .. ":" },
                   { class = "textbox", name = "config_text",   x = 0, y = 1, width = self.width, height = self.height - 1,
                                                                text = config_text },
                   { class = "label",                           x = self.width, y = #error > 0 and #error + 1 or 0, width = self.width,
                                                                label = "𝗣𝗿𝗲𝘀𝗲𝘁:" },
                   { class = "textbox", name = "preset_text",   x = self.width, y = 1 + (#error > 0 and #error + 1 or 0), width = self.width, height = self.height - 2 - (#error > 0 and #error + 1 or 0),
                                                                text = type(self.presets[preset_name]) == "string" and self.presets[preset_name] or self.json:encode_pretty(self.presets[preset_name]) },
                   { class = "label",                           x = self.width, y = self.height - 1, width = 8,
                                                                label = "Select Preset:" },
                   { class = "dropdown", name = "preset",       x = self.width + 8, y = self.height - 1, width = 24,
                                                                items = self.preset_names, value = preset_name } }
        if #error > 0 then
            table.insert(dialog, { class = "label",             x = self.width, y = 0, width = self.width,
                                                                label = "𝗘𝗿𝗿𝗼𝗿 𝗗𝗲𝘁𝗲𝗰𝘁𝗲𝗱:" })
            for i, v in ipairs(error) do
                table.insert(dialog, { class = "label",         x = self.width, y = i, width = self.width,
                                                                label = v })
        end end
        buttons = { "&Apply", "&Beautify", "&View Preset", "Apply &Preset", "Cancel" }
        button_ids = { ok = "&Apply", yes = "&Apply", save = "&Apply", apply = "&Apply", close = "Cancel", no = "Cancel", cancel = "Cancel" }

        button, result_table = aegisub.dialog.display(dialog, buttons, button_ids)

        if button == false or button == "Cancel" then
            return err("[aka.config] Operation cancelled by user")
        elseif button == "&Apply" then
            config_text = result_table["config_text"]

            config_data = self.json:decode2(config_text)
            if self.json.error:isNone() then
                config_data = validation_func(config_data)
                if config_data:isOk() then
                    return ok(config_text), config_data
                else
                    error = config_data:errOption()
                end
            else
                error = self.json.error
            end
        elseif button == "&Beautify" then
            config_text = result_table["config_text"]

            config_data = self.json:decode2(config_text)
            error = self.json.error
            if self.json.error:isNone() then
                config_text = self.json:encode_pretty(config_data)
            end
        elseif button == "&View Preset" then
            config_text = result_table["config_text"]
            preset_name = result_table["preset"]
            error = none()
        elseif button == "Apply &Preset" then
            if (self.presets[result_table["preset"]]) == "string" then
                return ok(self.presets[result_table["preset"]]), self.json:decode3(self.presets[result_table["preset"]])
            else
                return ok(self.json:encode_pretty(self.presets[result_table["preset"]])), ok(self.presets[result_table["preset"]])
            end
        else
            error("[aka.config] Unspecified error")
end end end

-------------------------------------------------
-- Read, edit and validate and then save config.
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- @param function validation_func [function(config_data) return ok(config_data)]: The validation function that takes the config_data and returns either ok(config_data) or err(error_message)
-- 
-- @return outcome.result<table, string>: Return the config table back if success, or return err() if the user cancel the option
--
-- @aegisub.debug.out: This will print message to aegisub.debug.out and return ok(config_data) if the save process failed
config_methods.read_edit_validate_and_save_config = function(self, config, config_supp, validation_func)
    local config_string
    local error
    local config_data
    
    if type(validation_func) == "function" then
    elseif type(config_supp) == "function" then
        validation_func = config_supp config_supp = nil
    else
        validation_func = function(config_data) return ok(config_data) end
    end
    
    config_string = self.read_config_string(config, config_supp)
    if config_string:isOk() then
        error = config_string
            :andThen(function(config_string) return
                self.json:decode3(config_string) end)
            :andThen(validation_func)
            :errOption()
        config_string = config_string
            :okOption()
    else
        config_string = none()
        error = none()
    end

    config_string, config_data = self:edit_config(config_string, error, validation_func)
    if config_string:isErr() then
        return config_string
    end

    self.write_config_string(config, config_supp, config_string:unwrap())
        :ifErr(function(error) return
            aegisub.debug.out(1, error) end)
    return config_data
end

-------------------------------------------------
-- Read and validate config. If anything happens, edit, validate and save config
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- @param function validation_func [function(config_data) return ok(config_data)]: The validation function that takes the config_data and returns either ok(config_data) or err(error_message)
-- 
-- @return outcome.result<table, string>: Return the config table back if success, or return err() if the user cancel the option
--
-- @aegisub.debug.out: This will print message to aegisub.debug.out and return ok(config_data) if the save process failed
config_methods.read_and_validate_config_or_else_edit_and_save = function(self, config, config_supp, validation_func)
    local config_string
    local config_data
    local error
    
    if type(validation_func) == "function" then
    elseif type(config_supp) == "function" then
        validation_func = config_supp config_supp = nil
    else
        validation_func = function(config_data) return ok(config_data) end
    end
    
    config_string = self.read_config_string(config, config_supp)
    if config_string:isOk() then
        config_data = config_string
            :andThen(function(config_string) return
                self.json:decode3(config_string) end)
            :andThen(validation_func)
        if config_data:isOk() then
            return config_data
        end
        
        config_string = config_string
            :okOption()
        error = config_data
            :errOption()
    else
        config_string = none()
        error = none()
    end

    config_string, config_data = self:edit_config(config_string, error, validation_func)
    if config_string:isErr() then
        return config_string
    end

    self.write_config_string(config, config_supp, config_string:unwrap())
        :ifErr(function(error) return
            aegisub.debug.out(1, error) end)
    return config_data
end

-------------------------------------------------
-- Read and validate config. If it is empty, save and return the default config happens; Or else edit, validate and save config
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- @param function validation_func [function(config_data) return ok(config_data) end]: The validation function that takes the config_data and returns either ok(config_data) or err(error_message)
-- 
-- @return outcome.result<table, string>: Return the config table back if success, or return err() if the user cancel the option
--
-- @aegisub.debug.out: This will print message to aegisub.debug.out and return ok(config_data) if the save process failed
config_methods.read_and_validate_config_if_empty_then_default_or_else_edit_and_save = function(self, config, config_supp, validation_func)
    local config_string
    local error
    local config_data
    
    if type(validation_func) == "function" then
    elseif type(config_supp) == "function" then
        validation_func = config_supp config_supp = nil
    else
        validation_func = function(config_data) return ok(config_data) end
    end

    config_string = self.read_config_string(config, config_supp)
    if config_string:isOk() then
        config_data = config_string
            :andThen(function(config_string) return
                self.json:decode3(config_string) end)
            :andThen(validation_func)
        if config_data:isOk() then
            return config_data
        end
        
        config_string = config_string
            :okOption()
        error = config_data
            :errOption()
    else
        if type(self.presets[self.default]) == "string" then
            self.write_config_string(config, config_supp, self.presets[self.default])
                :ifErr(function(error) return
                    aegisub.debug.out(1, error) end)
            return self.json:decode3(self.presets[self.default])
        else
            self.write_config(config, config_supp, self.presets[self.default])
                :ifErr(function(error) return
                    aegisub.debug.out(1, error) end)
            return ok(self.presets[self.default])
        end
    end

    config_string, config_data = self:edit_config(config_string, error, validation_func)
    if config_string:isErr() then
        return config_string
    end

    self.write_config_string(config, config_supp, config_string:unwrap())
        :ifErr(function(error) return
            aegisub.debug.out(1, error) end)
    return config_data
end

return config
