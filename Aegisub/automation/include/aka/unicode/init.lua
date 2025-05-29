-- aka.unicode
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

versioning.name = "aka.unicode"
versioning.description = "Module aka.unicode"
versioning.version = "1.0.10"
versioning.author = "Akatsumekusa and contributors"
versioning.namespace = "aka.unicode"

versioning.requiredModules = "[{ \"moduleName\": \"aegisub.unicode\" }, { \"moduleName\": \"bit\" }]"

local version = require("l0.DependencyControl")({
    name = versioning.name,
    description = versioning.description,
    version = versioning.version,
    author = versioning.author,
    moduleName = versioning.namespace,
    url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
    feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json",
    {
        { "aegisub.unicode" },
        { "bit" }
    }
})
local unicode, bit = version:requireModules()

unicode.char = function(codepoint)
    local byte1
    local byte2
    local byte3
    local byte4

    if codepoint < 0 then
        error("[aka.unicode] Invalid UTF-8 codepoint")
    elseif codepoint <= 0x7F then
        return string.char(codepoint)
    elseif codepoint <= 0x7FF then
        byte1 = 0xC0 + bit.rshift(codepoint, 6)
        byte2 = 0x80 + bit.band(codepoint, 0x3F)
        return string.char(byte1, byte2)
    elseif codepoint <= 0xFFFF then
        byte1 = 0xE0 + bit.rshift(codepoint, 12)
        byte2 = 0x80 + bit.band(bit.rshift(codepoint, 6), 0x3F)
        byte3 = 0x80 + bit.band(codepoint, 0x3F)
        return string.char(byte1, byte2, byte3)
    elseif codepoint <= 0x10FFFF then
        byte1 = 0xF0 + bit.rshift(codepoint, 18)
        byte2 = 0x80 + bit.band(bit.rshift(codepoint, 12), 0x3F)
        byte3 = 0x80 + bit.band(bit.rshift(codepoint, 6), 0x3F)
        byte4 = 0x80 + bit.band(codepoint, 0x3F)
        return string.char(byte1, byte2, byte3, byte4)
    else
        error("[aka.unicode] Invalid UTF-8 codepoint")
end end

unicode.version = version
unicode.versioning = versioning

return version:register(unicode)
