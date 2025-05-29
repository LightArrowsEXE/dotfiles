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

import ok, err from require "aka.outcome"
read_data = nil
save_data = nil
with require "aka.config2"
  read_data = .read_config
  save_data = .write_config

class display
  ---------------------------------------------------------------------
  -- Start a display
  --
  -- @param   dialog  dialog from aka.uikit.dialog
  -- @param   buttons buttons from aka.uikit.buttons
  --
  -- @return  display
  ---------------------------------------------------------------------
  new: (@dialog, @buttons) =>

  ---------------------------------------------------------------------
  -- Display and dialog and get button and result
  --
  -- @return  button  Same as in vanilla aegisub.dialog.display
  -- @return  result  Same as in vanilla aegisub.dialog.display
  ---------------------------------------------------------------------
  resolve: =>
    return aegisub.dialog.display @dialog\resolve!, @buttons\resolve!

  ---------------------------------------------------------------------
  -- Load the content from previous run, display the dialog and save
  -- the content for next run.
  -- This will only save the content if a button other than close or
  -- cancel is triggered.
  --
  -- @param   [name]    The subfolder you would want to put the config
  -- @param   name_supp The name for the config file without the file
  --                    extension.
  --                    The subfolder name is an optional parameter and
  --                    can be ommited in place. Calling the method as
  --                    `display\loadResolveAndSave filename` is A-OK.
  --
  -- @return  button    Same as in vanilla aegisub.dialog.display
  -- @return  result    Same as in vanilla aegisub.dialog.display
  ---------------------------------------------------------------------
  loadResolveAndSave: (name, name_supp) =>
    with read_data name, name_supp
      \ifOk (data) -> @dialog\load_data data

    button, result = aegisub.dialog.display @dialog\resolve!, @buttons\resolve!

    unless @buttons\is_close_cancel button
      save_data name, name_supp, result

    return button, result

  ---------------------------------------------------------------------
  -- Repeatly display the dialog until f returns ok(result)
  -- 
  -- @param   f       Function that takes in button and result.
  --                  It shall returns ok() if the dialog is accepted.
  --                  Any contents in the ok() is returns out of
  --                  `repeatUntil()` so you could possibly preprocess
  --                  the data inside this function.
  --                  It shall returns err() if the dialog is rejected
  --                  and the dialog is redisplayed to the user.
  --                  If you want to display an error message or modify
  --                  the dialog, you can pass data inside err() and it
  --                  will be loaded using `dialog:loadData()`.
  --
  -- @return  Result  Ok if the dialog is accepted by f. Contains the
  --                  data returned from f.
  --                  Err if the user cancel the operation.
  ---------------------------------------------------------------------
  repeatUntil: (f) =>
    while true
      button, result = aegisub.dialog.display @dialog\resolve!, @buttons\resolve!

      if @buttons\is_close_cancel button
        return err "[aka.uikit] User cancels display.repeatUntil"
        
      result = f button, result
      if result\isOk!
        return result

      @dialog\load_data result\unwrapErr!

  ---------------------------------------------------------------------
  -- Load the contents from previous run, repeatly display the dialog
  -- until f returns ok(result), and then save the result for next run.
  -- 
  -- @param   [name]    The subfolder you would want to put the config
  -- @param   name_supp The name for the config file without the file
  --                    extension.
  --                    The subfolder name is an optional parameter and
  --                    can be ommited in place. Calling the method as
  --                    `display\loadRepeatUntilAndSave filename, f` is
  --                    A-OK.
  -- @param   f         Function that takes in button and result.
  --                    It shall returns ok(result) if the dialog is
  --                    You may preprocess the data for further use since
  --                    the contents inside ok() will be returned out of
  --                    `loadRepeatUntilAndSave`. However, you also need
  --                    to return the key-value pairs necessay for the
  --                    next dialog run.
  --                    It shall returns err() if the dialog is rejected
  --                    and the dialog is redisplayed to the user.
  --                    If you want to display an error message or modify
  --                    the dialog, you can pass data inside err() and it
  --                    will be loaded using `dialog:loadData()`.
  --
  -- @return  Result    Ok if the dialog is accepted by f. Contains the
  --                    data returned from f.
  --                    Err if the user cancel the operation.
  ---------------------------------------------------------------------
  loadRepeatUntilAndSave: (name, name_supp, f) =>
    f, name_supp = name_supp, nil if f == nil
    name_supp, name = name, nil if name_supp == nil

    with read_data name, name_supp
      \ifOk (data) -> @dialog\load_data data

    while true
      button, result = aegisub.dialog.display @dialog\resolve!, @buttons\resolve!

      if @buttons\is_close_cancel button
        return err "[aka.uikit] User cancels display.repeatUntil"
        
      result_ = f button, result
      if result_\isOk!
        if (type result_\unwrap!) == "table"
          save_data name, name_supp, result_\unwrap!
        else
          save_data name, name_supp, result
        return result_

      @dialog\load_data result_\unwrapErr!

{:display}
