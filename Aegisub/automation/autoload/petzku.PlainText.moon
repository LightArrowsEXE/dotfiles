-- Copyright (c) 2025, petzku <petzku@zku.fi>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

export script_name = "PlainText"
export script_author = "petzku"
export script_description = "Copy script text in plaintext format"
export script_version = "0.2.0"
export script_namespace = "petzku.PlainText"

havedc, DependencyControl, dep = pcall require, "l0.DependencyControl"
dep = DependencyControl{feed: "https://raw.githubusercontent.com/petzku/Aegisub-Scripts/stable/DependencyControl.json"} if havedc


get_text = (subs) ->
    text = {}

    for line in *subs
        continue unless line.class == 'dialogue'
        continue if line.comment
        t = line.text\gsub("%b{}", "")\gsub("%s*\\[Nn]%s*", " ")
        table.insert(text, t) unless text[#text] == t

    text

main = (subs) ->
    text = get_text subs
    plain = table.concat text, "\n"
    aegisub.log 5, plain
    dialog = {
        {class:'textbox', x:0, y:0, width:50, height:40, text: plain}
    }
    aegisub.dialog.display dialog

if havedc
    dep\registerMacro main
else
    aegisub.register_macro script_name, script_description, main