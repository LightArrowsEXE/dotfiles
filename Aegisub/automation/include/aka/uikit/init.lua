-- aka.uikit
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

versioning.name = "aka.uikit"
versioning.description = "Module aka.uikit"
versioning.version = "1.0.14"
versioning.author = "Akatsumekusa and contributors"
versioning.namespace = "aka.uikit"

versioning.requiredModules = "[{ \"moduleName\": \"aka.outcome\" }, { \"moduleName\": \"aegisub.re\" }, { \"moduleName\": \"ILL.ILL\" }, { \"moduleName\": \"aka.config2\" }]"

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
        { "ILL.ILL", version = "1.0.0" },
        { "aka.config2", version = "1.0.0" }
    }
})

local functions = {}

functions.dialog = require("aka.uikit.dialog").dialog
functions.buttons = require("aka.uikit.buttons").buttons
functions.display = require("aka.uikit.display").display

functions.error = function(str) error(str) end

functions.version = version
functions.versioning = versioning

return version:register(functions)
