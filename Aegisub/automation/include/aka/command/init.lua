-- aka.command
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

versioning.name = "aka.command"
versioning.description = "Module aka.command"
versioning.version = "1.0.2"
versioning.author = "Akatsumekusa and contributors"
versioning.namespace = "aka.command"

versioning.requiredModules = "[{ \"moduleName\": \"petzku.util\" }, { \"moduleName\": \"aegisub.re\" }]"

local version = require("l0.DependencyControl")({
    name = versioning.name,
    description = versioning.description,
    version = versioning.version,
    author = versioning.author,
    moduleName = versioning.namespace,
    url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
    feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json",
    {
        { "petzku.util", version = "0.1.0" },
        { "aegisub.re" }
    }
})
version:requireModules()

local re = require("aegisub.re")
local re_newline = re.compile([[\s*(?:\n\s*)+]])

local putil = require("petzku.util")
local run_cmd = function(command, quiet)
    if quiet == nil then quiet = true end
    return putil.io.run_cmd(command, quiet)
end

local c = function(command)
    if jit.os == "Windows" then
        local i = 1
        for chunks in re_newline:gsplit(command, true) do
            if i == 1 then
                command = "try { & " .. chunks
            else
                command = command .. " ; if ($LASTEXITCODE -eq 0) {& " .. chunks .. "}"
            end
            i = i + 1
        end
        command = command .. " ; exit $LASTEXITCODE } catch { exit 1 }"
        return "powershell -Command \"" .. command .. "\""
    else
        local i = 1
        for chunks in re_newline:gsplit(command, true) do
            if i == 1 then
                command = chunks
            else
                command = command .. " && " .. chunks
            end
            i = i + 1
        end
        return command
end end
local p = function(path)
    if jit.os == "Windows" then
        path = string.gsub(path, "'", "''")
    else
        path = string.gsub(path, "'", "'\\''")
    end
    return "'" .. path .. "'"
end

local run_cmd_c = function(command, quiet)
    return run_cmd(c(command), quiet)
end
local check_cmd_c = function(command, quiet)
    return table.pack(run_cmd(c(command), quiet))[2]
end

local functions = {}

functions.run_cmd = run_cmd
functions.c = c
functions.p = p
functions.run_cmd_c = run_cmd_c
functions.check_cmd_c = check_cmd_c

functions.version = version
functions.versioning = versioning

return version:register(functions)
