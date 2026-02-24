export script_name = "SmartQuotify"
export script_description = [[Change all your "normal" quotes into “smart” ones]]
export script_author = "petzku"
export script_namespace = "petzku.SmartQuotify"
export script_version = "0.1.0"

re = require 'aegisub.re'

main = =>
    for i, line in ipairs @
        continue unless line.class == "dialogue" and not line.comment
        aegisub.log(5, "dialogue line: %s\n", line.text)

        continue unless line.text\find "['\"]"
        aegisub.log(5, "... has quotes\n")

        -- Apostrophes are always supposed to be right quotes, even at the start of a word.
        -- This makes converting them correctly impossible without NLP, as this can't be distinguished from a starting single quote.
        -- Instead, we leave the user a warning and have them check it themself.
        text = re.sub line.text, [[(?<!\w)'(?=\w)]], "’"
        apos_found = line.text != text and #re.find text, "’"
        -- We can, however, assume that any cases where another quotation mark appears between the quote and the word, it's not an apostrophe.
        text = re.sub text, [[(?<!\w)'(?=['"]+\w)]], "‘"
        text = re.sub text, "'", "’"

        -- First, we replace any pairs of double quotes. This _will_ break triply nested quotes, but those are very rare, so we can probably ignore that.
        text = re.sub text, [["(.-)"]], [[“\1”]]
        -- Then, we handle any remaining, unpaired double-quotes heuristically. This could be e.g. quotes extending over two (or more) lines.
        -- Simply put, we assume any quote directly before a word is opening, and everything else is closing.
        text = re.sub text, [[(?<!\w)"(?=[‘’"]*\w)]], "“"
        text = re.sub text, '"', "”"
        line.text = text

        -- nil if none found
        if apos_found
            line.effect ..= "[check possible starting single quote#{apos_found > 1 and 's' or ''} -- assumed apostrophe]"

        aegisub.log(5, "... is now %s\n", line.text)
        @[i] = line

aegisub.register_macro script_name, script_description, main