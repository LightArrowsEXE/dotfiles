-- aka.unsemantic
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

versioning.name = "aka.unsemantic"
versioning.description = "Module aka.unsemantic"
versioning.version = "1.1.2"
versioning.author = "Akatsumekusa and contributors"
versioning.namespace = "aka.unsemantic"

versioning.requiredModules = "[{ \"moduleName\": \"lpeg\" }]"

local version = require("l0.DependencyControl")({
    name = versioning.name,
    description = versioning.description,
    version = versioning.version,
    author = versioning.author,
    moduleName = versioning.namespace,
    url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
    feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json",
    {
        { "lpeg" }
    }
})
local lpeg = version:requireModules()
local C, P, R = lpeg.C, lpeg.P, lpeg.R

local number = C(R"09"^1)/tonumber
local dot = P"."
local version_match = number*dot*number*dot*number
local two_number_version_match = number*dot*number

local mt
local V
mt = {
    __index = mt,
    __eq = function(lhs, rhs)
        return lhs.major == rhs.major and
               lhs.minor == rhs.minor and
               lhs.patch == rhs.patch
    end,
    __lt = function(lhs, rhs)
        return lhs.major < rhs.major or
               (lhs.major == rhs.major and lhs.minor < rhs.minor) or
               (lhs.major == rhs.major and lhs.minor == rhs.minor and lhs.patch < rhs.patch)
    end,
    __le = function(lhs, rhs)
        return lhs.major < rhs.major or
               (lhs.major == rhs.major and lhs.minor < rhs.minor) or
               (lhs.major == rhs.major and lhs.minor == rhs.minor and lhs.patch <= rhs.patch)
    end
}
V = function(version_str)
    local t

    t = {}
    t.major, t.minor, t.patch = version_match:match(version_str)
    if not t.major then
        t.major, t.minor = two_number_version_match:match(version_str)
        t.patch = -1

        if not t.major then
            error("[aka.unsemantic] Invalid version format.")
    end end

    setmetatable(t, mt)

    return t
end

local unsemantic = {}

unsemantic.V = V

unsemantic.version = version
unsemantic.versioning = versioning

return version:register(unsemantic)
