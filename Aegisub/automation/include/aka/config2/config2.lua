-- aka.config2
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

local json = require("aka.config2.json")
local outcome = require("aka.outcome")
local ok, err, some, none, o = outcome.ok, outcome.err, outcome.some, outcome.none, outcome.o
local re = require("aegisub.re")
local unicode = require("aegisub.unicode")
local lfs = require("lfs")
local hasDepCtrl, DepCtrl = pcall(require, "l0.DependencyControl")

local config_dir
local read_config
local read_config_string
local write_config
local write_config_string

json.error = none()
json.onDecodeError = function(self, message, text, location, etc)
    local matches
    local i

    if not message or not text or not location then return end

    text = "\n" .. text .. "\n"
    location = location + 1
    matches = re.find(text, "(\\r|\\n|\\r\\n)")
    i = 1
    while matches[i + 1] do
        if location == 2 then
            json.error = json.error:mapOr(message, function(prev) return prev .. "\n" .. message end)
            return
        elseif location > matches[i]["last"] and location <= matches[i + 1]["first"] then
            message = message .. " in line " .. tostring(i) .. " column " .. tostring(unicode.len(string.sub(text, matches[i]["last"] + 1, location - 1)) + 1) .. "\n" ..
                      "`" .. string.sub(text, matches[i]["last"] + 1, matches[i + 1]["first"] - 1) .. "`"
            json.error = json.error:mapOr(message, function(prev) return prev .. "\n" .. message end)
            return
        end
        i = i + 1
    end
    error("[aka.config2] Error")
end
json.reset_error = function(self) self.error = none() end
json.decode2 = function(self, text, etc, options) self:reset_error() return self:decode(text, etc, options) end
json.decode3 = function(self, config_string)
    local config_data = self:decode2(config_string)
    if self.error:isNone() then return
        ok(config_data)
    else return
        err(json.error:unwrap())
end end

config_dir = aegisub.decode_path(hasDepCtrl and DepCtrl.config.c.configDir or "?user/config")

------------------------------------------------
-- Read the specified config and return a table.
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- 
-- @return outcome.result<table, string>
read_config = function(config, config_supp)
    if config_supp == nil then config_supp = config config = nil end
    return
    read_config_string(config, config_supp)
        :andThen(function(config_string) return
            json:decode3(config_string) end)
end
------------------------------------------------
-- Read the specified config and return a string.
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- 
-- @return outcome.result<string, string>
read_config_string = function(config, config_supp)
    if config_supp == nil then config_supp = config config = nil end
    return
    o(io.open(config_dir .. "/" .. (config and config .. "/" or "") .. config_supp .. ".json", "r"))
        :andThen(function(file)
            local config_string = file:read("*all")
            file:close() return
            ok(config_string) end)
end

-------------------------------------------------
-- Overwrite the specified config with the table.
--
-- Optional arguments can be omitted in place as write_config(config, config_data)
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- @param table config_data: The table to save to the config
-- 
-- @return outcome.result<table, string>: Return the same config table back if success
write_config = function(config, config_supp, config_data)
    if config_data == nil then config_data = config_supp config_supp = nil end
    if config_supp == nil then config_supp = config config = nil end
    return
    o(json:encode_pretty(config_data))
        :andThen(function(config_string) return
            write_config_string(config, config_supp, config_string) end)
        :andThen(function(_) return
            ok(config_data) end)
end
-------------------------------------------------
-- Overwrite the specified config with the string.
--
-- Optional arguments can be omitted in place as write_config(config, config_data)
-- 
-- @param str config [nil]: The subfolder where the config is in
-- @param str config_supp: The name for the config file without the file extension
-- @param table config_string: The string to save to the config
-- 
-- @return outcome.result<table, string>: Return the same config string back if success
write_config_string = function(config, config_supp, config_string)
    if config_string == nil then config_string = config_supp config_supp = nil end
    if config_supp == nil then config_supp = config config = nil end
    return
    o(lfs.attributes(config_dir .. (config and "/" .. config or ""), "mode"))
        :orElseOther(function(_) return
            o(lfs.mkdir(config_dir .. (config and "/" .. config or ""))) end)
        :andThen(function(_) return
            o(io.open(config_dir .. (config and "/" .. config or "") .. "/" .. config_supp .. ".json", "w")) end)
        :andThen(function(file)
            file:write(config_string)
            file:close() return
            ok(config_string) end)
end

local functions = {}

functions.read_config = read_config
functions.read_config_string = read_config_string
functions.write_config = write_config
functions.write_config_string = write_config_string

functions.json = json
functions.config_dir = config_dir

return functions
