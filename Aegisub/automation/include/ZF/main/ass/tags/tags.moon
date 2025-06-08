import TABLE from require "ZF.main.util.table"
import UTIL  from require "ZF.main.util.util"
import LAYER from require "ZF.main.ass.tags.layer"

class TAGS

    version: "1.0.0"

    new: (@text = "") =>
        if type(@text) != "table"
            @text = @blank text, "both"
            @text = @text\find("%b{}") != 1 and "{}#{@text}" or @text
            if shape = UTIL\isShape @text\gsub "%b{}", ""
                @isShape = true
                @between = {shape}
            else
                @between = UTIL\headsTails @text, "%b{}"
                if #@between > 1 and @between[1] == ""
                    TABLE(@between)\shift!
                n = #@between
                if n >= 1
                    @between[1] = @blank @between[1], "start"
                    if n > 1
                        @between[n] = @blank @between[n], "end"
            @split!
        else
            @layers = TABLE(@text["layers"])\copy!
            @layers_data = TABLE(@text["layers_data"])\copy!
            @between = TABLE(@text["between"])\copy!

    -- splits the text by the amount of tag layer
    -- @param txt string
    -- @return TAGS
    split: (txt = @text, layers = {}, layers_data = {}) =>
        unless @isShape
            for l in txt\gmatch "%b{}"
                l = LAYER l
                TABLE(layers)\push l
                TABLE(layers_data)\push l\split!
            n = #@between
            if (#layers - n) == 1
                @between[n] = @blank @between[n], "end"
                TABLE(@between)\push ""
        else
            layer = LAYER @text\match "%b{}"
            TABLE(layers)\push layer
            TABLE(layers_data)\push layer\split!
        @layers, @layers_data = layers, layers_data
        return @

    -- blank space caps
    -- @param txt string
    -- @param where string
    -- @return string
    blank: (txt, where = "both") =>
        switch where
            when "both"   then txt\match "^%s*(.-)%s*$"
            when "start"  then txt\match "^%s*(.-%s*)$"
            when "end"    then txt\match "^(%s*.-)%s*$"
            when "spaceL" then txt\match "^(%s*).-%s*$"
            when "spaceR" then txt\match "^%s*.-(%s*)$"
            when "spaces" then txt\match "^(%s*).-(%s*)$"

    -- adds tags that should be in the first layer to the first layer
    -- @return TAGS
    firstCategory: (values = {}, once = {"an", "b", "i", "s", "u", "org", "pos", "move", "fade", "fad"}) =>
        values[t] = {} for t in *once
        -- gets the first category tags
        for l, layer in ipairs @layers
            for t in *once
                if layer\contain t
                    TABLE(values[t])\push layer\__match AssTagsPatterns[t]["patterns_none_value"]
                    if l > 1
                        layer\remove t
        -- adds the first category tags
        for name, value in pairs values
            layer = @layers[1]
            if layer\contain name
                layer\remove {name, value[1]}
            else
                layer\insert value[1]
        @split @__tostring!
        return @

    -- adds tags from the current layer into the next layer if it does not exist in the next layer
    -- @param add_all bool
    -- @param animation bool
    -- @param fade bool
    -- @return TAGS
    insertPending: (add_all = true, animation = false, fade = false) =>
        {:layers, :layers_data} = @
        for i = 2, #layers
            layer = layers[i]
            lprev = TABLE(layers_data[i - 1])\copy!
            for j = #lprev, 1, -1
                {:name, :info, :tag} = lprev[j]
                if add_all
                    layer\insert {tag, not ((name == "fad" or name == "fade") and fade)}
                else
                    if info["transformable"]
                        unless layer\contain name
                            layer\insert {tag, true}
                    else
                        if name == "t" and animation
                            layer\insert {tag, true}
                        elseif (name == "fad" or name == "fade") and fade
                            layer\insert tag
            layers_data[i] = layer\split!
        @split @__tostring!
        return @

    -- adds one or more tags into layers
    -- @return TAGS
    insert: (...) =>
        layer\insert ... for l, layer in ipairs @layers
        return @

    -- removes one or more tags on the layers
    -- @return TAGS
    remove: (...) =>
        layer\remove ... for l, layer in ipairs @layers
        return @

    -- removes equal tags between a current and previous value
    -- @return TAGS
    removeEquals: =>
        for i = 2, #@layers
            @layers[i]\removeEquals @layers[i - 1]
        return @

    -- adds style tags into layers
    -- @param line table
    -- @param onlyAnimated bool
    -- @return TAGS
    insertStyleRef: (line, onlyAnimated) =>
        for l, layer in ipairs @layers
            style = l > 1 and line.styleref or line.styleref_old
            layer\insertStyleRef style, onlyAnimated
        @split @__tostring!
        return @

    -- removes style tags on layers
    -- @param line table
    -- @return TAGS
    removeStyleRef: (line) =>
        for l, layer in ipairs @layers
            style = l > 1 and line.styleref or line.styleref_old
            layer\removeStyleRef style
        @split @__tostring!
        return @

    -- removes repeated tags and style tags with values equal to the style's
    -- @param line table
    -- @return TAGS
    clear: (line) =>
        for l, layer in ipairs @layers
            layer\clear line and (l > 1 and line.styleref or line.styleref_old) or nil
        @split @__tostring!
        return @

    -- splits text into line breaks
    -- @return table
    breaks: =>
        @insertPending true
        breaks = UTIL\headsTails @__tostring!, "\\N"
        breaks[1] = TAGS(breaks[1])\insertPending(false)\__tostring!
        for i = 2, #breaks
            solver = (LAYER(breaks[i - 1])["layer"] .. breaks[i])\gsub "}%s*{", ""
            breaks[i] = TAGS(solver)\insertPending(false)\__tostring!
        return breaks

    __tostring: (concat = "") =>
        {:layers, :between} = @
        for i = 1, #layers
            concat ..= layers[i]["layer"] .. between[i]
        return concat

{:TAGS}