export script_name = "Remove Tags"
export script_description = "Dynamically remove tags based on selection"
export script_version = "1.0.3"
export script_author = "PhosCity"
export script_namespace = "phos.RemoveTags"


DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
        {"phos.AssfPlus", version: "1.0.4", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    }
}
LineCollection, ASS, Functional, AssfPlus = depctrl\requireModules!
{:list} = Functional


collectTags = (lines) ->

    collection = AssfPlus.lineCollection.collectTags lines, true

    with collection

        .buttons = {"Remove Tags", "Remove All", "Cancel"}

        .removeGroup = {color: false, alpha: false, rotation: false, scale: false, perspective: false, inline_except_last: .multiple_inline_tags}

        .removeGroupTags = {
            color: {"color1", "color2", "color3", "color4"}
            alpha: {"alpha", "alpha1", "alpha2", "alpha3", "alpha4"}
            rotation: {"angle", "angle_x", "angle_y"}
            scale: {"fontsize", "scale_x", "scale_y"}
            perspective: {"angle", "angle_x", "angle_y", "shear_x", "shear_y"}
        }

        .hint = {
            color: "c, 1c, 2c, 3c, 4c"
            alpha: "alpha, 1a, 2a, 3a, 4a"
            rotation: "frz, frx, fry"
            scale: "fs, fscx, fscy"
            perspective: "frz, frx, fry, fax, fay, org"
            inline_except_last: "Remove all inline tags except the last one"
            start_tag: "Remove from start tags only"
            inline_tags: "Remove from inline tags only"
            transform: "Remove from transform only"
            invert: "Remove all except selected"
        }

        .tagTypes.invert = true

    for tag in *collection.tagList
        with collection.removeGroup
            if tag\match "color"
                .color = true
            elseif tag\match "alpha"
                .alpha = true
            elseif tag\match "angle"
                .rotation = true
                .perspective = true
            elseif tag\match "shear" or tag == "origin"
                .perspective = true
            elseif tag\match "scale" or tag == "fontsize"
                .scale = true

    collection

createGui = (collection) ->

    y, dialog = 0, {}
    for key, value in pairs collection.removeGroup
        continue unless value
        label = ("Remove all #{key}")\gsub "_", " "
        dialog[#dialog+1]= {x: 0, y: y, class: "checkbox", label: label, name: "group_"..key, hint: collection.hint[key]}
        y += 1

    startX = 0
    if #dialog > 0
        table.insert collection.buttons, 1, "Remove Group"
        startX = 1
    x = startX

    for key in *[ item for item in *{"start_tag", "inline_tags", "transforms", "invert"} when collection.tagTypes[item]]       -- Manually sorting since lua doesn't loop through table in order
        label = key\gsub("^%l", string.upper)\gsub("_%l", string.upper)\gsub("_", " ")
        dialog[#dialog+1]= {x: x, y: 0, class: "checkbox", label: label, name: key, hint: collection.hint[key]}
        x += 1

    column = math.max math.ceil(math.sqrt #collection.tagList), x

    count = 0
    for y = 1, column
        for x = startX, column + startX - 1
            count += 1
            break if count > #collection.tagList
            label = (ASS.toFriendlyName[collection.tagList[count]])\gsub("\\1c%s+", "")\gsub("\\", "")
            dialog[#dialog+1] = {x: x, y: y, class: "checkbox", label: label, name: collection.tagList[count]}

    btn, res = aegisub.dialog.display dialog, collection.buttons, {"cancel": "Cancel"}
    aegisub.cancel! unless btn

    btn, res

main = (sub, sel) ->

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    collection = collectTags lines

    btn, res = createGui collection

    lines\runCallback (lines, line, i) ->

        AssfPlus._util.checkCancellation!
        AssfPlus._util.progress "Removing tags", i, #lines.lines

        data = ASS\parse line
        tagSectionCount = data\getSectionCount ASS.Section.Tag
        transforms = data\getTags "transform"
        switch btn

            when "Remove All"
                if res.start_tag
                    data\removeTags _, 1, 1
                elseif res.inline_tags
                    data\removeTags _, 2, tagSectionCount
                else
                    data\stripTags!

            when "Remove Group"

                if res["group_inline_except_last"]
                    data\removeTags _, (collection.tagTypes.start_tag and 2 or 1), tagSectionCount - 1

                else
                    start, end_, tagsToDelete = 1, tagSectionCount, {}
                    end_ = 1 if res.start_tag
                    start = 2 if res.inline_tags
                    for key, value in pairs collection.removeGroupTags
                        continue unless res["group_" .. key]
                        tagsToDelete = list.join tagsToDelete, value
                    tagsToDelete = list.diff ASS.tagSortOrder, tagsToDelete if res.invert
                    data\removeTags tagsToDelete, start, end_

            when "Remove Tags"

                local tagsToDelete
                if res.invert
                    tagsToDelete = [tag for tag in *collection.tagList when not res[tag]]
                else
                    tagsToDelete = [tag for tag in *collection.tagList when res[tag]]

                if res.start_tag
                    data\removeTags tagsToDelete, 1, 1

                elseif res.inline_tags
                    data\removeTags tagsToDelete, 2, tagSectionCount

                elseif res.transforms
                    for tr in *transforms
                        tr.tags\removeTags tagsToDelete

                else
                    data\removeTags tagsToDelete

        data\commit!
        line.text = line.text\gsub "{}", ""
    lines\replaceLines!

depctrl\registerMacro main