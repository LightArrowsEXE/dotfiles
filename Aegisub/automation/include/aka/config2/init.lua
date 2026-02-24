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

------------------------------------------------------------------------------
-- Tutorials are available at „docs/Using aka.config.md“.
------------------------------------------------------------------------------

local versioning = {}

versioning.name = "aka.config2"
versioning.description = "Module aka.config2"
versioning.version = "1.0.12"
versioning.author = "Akatsumekusa and contributors"
versioning.namespace = "aka.config2"

versioning.requiredModules = "[{ \"moduleName\": \"aka.outcome\" }, { \"moduleName\": \"aegisub.re\" }, { \"moduleName\": \"aegisub.unicode\" }, { \"moduleName\": \"lfs\" }]"

local version = require("l0.DependencyControl")({
    name = versioning.name,
    description = versioning.description,
    version = versioning.version,
    author = versioning.author,
    moduleName = versioning.namespace,
    url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
    feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json",
    {
        { "aka.outcome", version = "1.0.0" },
        { "aegisub.re" },
        { "aegisub.unicode" },
        { "lfs" }
    }
})
version:requireModules()

local config2 = require("aka.config2.config2")

config2.version = version
config2.versioning = versioning

return version:register(config2)
