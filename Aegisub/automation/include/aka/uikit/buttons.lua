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

local Table = require("ILL.ILL.Table").Table

local buttons
local overloaded_buttons

buttons = {}
buttons.new = function(name)
    local mt = {}
    mt.__index = overloaded_buttons
    mt.__call = overloaded_buttons.regular
    local self = setmetatable({}, mt)
    self.buttons = {}
    self.button_ids = {}
    if name then
        self(name)
    end
    return self
end
buttons.copy = function(self)
    return Table.deepcopy(self)
end

overloaded_buttons = setmetatable({}, { __index = buttons })
overloaded_buttons.resolve = function(self)
    return self.buttons, self.button_ids
end

local buttons_mt = {}
buttons_mt.__index = function(self, key)
    local target = rawget(buttons, key)
    if target then return target end

    local self = buttons.new()
    return function(...) return self[key](self, ...) end
end
buttons_mt.__call = function(cls, ...)
    return cls.new(...)
end
setmetatable(buttons, buttons_mt)

-----------------------------------------------------------------------
-- Add an apply, ok or confirm button. This button is triggered when
-- the user pressed Enter or return.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.ok = function(self, name)
    table.insert(self.buttons, name)
    self.button_ids["ok"] = name
    return self
end
-----------------------------------------------------------------------
-- Add a close button. This button is triggered when the user pressed
-- escape.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.close = function(self, name)
    table.insert(self.buttons, name)
    if self.button_ids["cancel"] then
        error("[aka.uikit] Close button is mutually exclusive with cancel button\n[aka.uikit] In buttons.close, display will return the name of the button on escape.\n[aka.uikit] In buttons.cancel, display will return false on escape.")
    end
    self.button_ids["close"] = name
    return self
end
-----------------------------------------------------------------------
-- Add a cancel button. This is mutually exclusive with buttons.close.
-- In buttons.close, display will return the name of the button on Esc.
-- In buttons.cancel, display will return false on Esc.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed if the user
--                  clicked the button. If the user pressed escape, 
--                  false will be returned instead. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.cancel = function(self, name)
    table.insert(self.buttons, name)
    if self.button_ids["close"] then
        error("[aka.uikit] Cancel button is mutually exclusive with close button\n[aka.uikit] In buttons.close, display will return the name of the button on escape.\n[aka.uikit] In buttons.cancel, display will return false on escape.")
    end
    self.button_ids["cancel"] = name
    return self
end
-----------------------------------------------------------------------
-- Add a help button.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.help = function(self, name)
    table.insert(self.buttons, name)
    self.button_ids["help"] = name
    return self
end
-----------------------------------------------------------------------
-- Add a regular button. Same as buttons.extra, and buttons.button.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.regular = function(self, name)
    table.insert(self.buttons, name)
    return self
end
-----------------------------------------------------------------------
-- Add an extra regular button. Same as buttons.regular.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.extra = overloaded_buttons.regular
-----------------------------------------------------------------------
-- Add an extra regular button. Same as buttons.regular.
--
-- @param   name    The name of the button, both for display and for
--                  return after dialog is displayed. Supports "&".
-----------------------------------------------------------------------
overloaded_buttons.button = overloaded_buttons.regular

overloaded_buttons.is_ok = function(self, button)
    if self.button_ids["ok"] == nil then
        error("[aka.uikit] buttons.is_ok is called but OK button is never set")
    end
    return button == self.button_ids["ok"]
end
overloaded_buttons.is_close_cancel = function(self, button)
    if self.button_ids["close"] == nil and self.button_ids["cancel"] == nil then
        error("[aka.uikit] buttons.is_close_cancel is called but neither close or cancel button is set")
    end
    return button == false or button == nil or
           button == self.button_ids["close"] or
           button == self.button_ids["cancel"]
end
overloaded_buttons.is_close = overloaded_buttons.is_close_cancel
overloaded_buttons.is_cancel = overloaded_buttons.is_close_cancel
overloaded_buttons.is_help = function(self, button)
    if self.button_ids["help"] == nil then
        error("[aka.uikit] buttons.is_help is called but help button is never set")
    end
    return button == self.button_ids["help"]
end

local functions = {}

functions.buttons = buttons
functions.overloaded_buttons = overloaded_buttons

return functions
