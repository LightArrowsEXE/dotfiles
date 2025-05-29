haveDepCtrl, DependencyControl, depctrl = pcall require, 'l0.DependencyControl'
local Functional, ASS, Yutils, APerspective
if haveDepCtrl
    depctrl = DependencyControl{
        name: "AssfPlus",
        version: "1.0.5",
        description: "Adds more features to ASSFoundation.",
        author: "PhosCity",
        moduleName: "phos.AssfPlus",
        url: "https://github.com/PhosCity/Aegisub-Scripts",
        feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
        {
            {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
                feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
            { "l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
                feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json" },
            {"arch.Perspective", version: "1.0.0", url: "https://github.com/TypesettingTools/arch1t3cht-Aegisub-Scripts",
                feed: "https://raw.githubusercontent.com/TypesettingTools/arch1t3cht-Aegisub-Scripts/main/DependencyControl.json"},
            "Yutils"
            "json"
        }
    }
    ASS, Functional, APerspective, Yutils, json = depctrl\requireModules!
else
    ASS = require "l0.ASSFoundation"
    Functional = require "l0.Functional"
    Yutils = require "Yutils"
    APerspective = require "arch.Perspective"
    json = require "json"

logger = depctrl\getLogger!
{:string, :list, :util, :math} = Functional
{:transformPoints, :an_xshift, :an_yshift} = APerspective
import Path   from require "ILL.ILL.Ass.Shape.Path"

local lineCollection
local lineData
local textSection
local tagSection
local _tag
local _shape
local _util

assertLineContent = (data) ->
    logger\assert data.class == ASS.LineContents, " Expected ASSFoundation line data. Got something else."


assertTextSection = (section) ->
    logger\assert section.class == ASS.Section.Text, " Expected a text section. Got something else."


assertTagSection = (section) ->
    logger\assert section.class == ASS.Section.Tag, " Expected a tag section. Got something else."


perspective = (tagList, width, height, shape) ->
    shape = Path(shape)\flatten!

    finalShape = ""
    for sh in *shape.path
        points = {}
        for coord in *sh
            table.insert points, {coord.x, coord.y}

        finalPoints = transformPoints(tagList, width, height, points)
        for index, item in ipairs finalPoints

            x = math.round(item[1], 3)
            y = math.round(item[2], 3)
            if index == 1
                finalShape ..= " m #{x} #{y}"
            elseif index == 2
                finalShape ..= " l #{x} #{y}"
            else
                finalShape ..= " #{x} #{y}"

    finalShape = Path(finalShape)\simplify(0.5, false, false, 170)\export!
    finalShape


getYutilsShape = (text, fontObj) ->

    splitString = (str) ->
        return {str} if #str <= 15

        result = {}
        startIndex = 1
        while startIndex <= #str do
           endIndex = startIndex + 14
           substring = str\sub startIndex, endIndex
           table.insert result, substring
           startIndex = endIndex + 1
        result

    shape = ""
    width, height = 0, 0

    local splitTable
    if jit.os == "Windows"
        splitTable = {text}
    else
        splitTable = splitString text
    for index, item in ipairs splitTable
        currShape = fontObj.text_to_shape item
        currShape = currShape\gsub " c", ""

        currShape = Yutils.shape.filter currShape, (x, y) -> x + width, y

        extents = fontObj.text_extents item
        height = tonumber(extents.height)
        width += tonumber(extents.width)

        shape ..= currShape .. " "

    string.trim(shape), height

getTextDrawingScale = (data, text, tagList, shape, spaceWidth) ->
    prevSpace = text\match("^%s*")\len! * spaceWidth
    text = string.trim text

    dataTemp = data\copy!
    dataTemp\removeSections 1, #dataTemp.sections
    dataTemp\insertSections ASS.Section.Tag!
    dataTemp\insertTags {
        ASS\createTag "align", 7
        ASS\createTag "shadow", 0
        ASS\createTag "outline", 0
        ASS\createTag "position", 0, 0
        ASS\createTag "scale_x", tagList.scale_x.value
        ASS\createTag "scale_y", tagList.scale_y.value
        ASS\createTag "spacing", tagList.spacing.value
        ASS\createTag "fontsize", tagList.fontsize.value
        ASS\createTag "fontname", tagList.fontname.value
        ASS\createTag "bold", tagList.bold\getTagParams!
        ASS\createTag "italic", tagList.italic\getTagParams!
        ASS\createTag "underline", tagList.underline\getTagParams!
        ASS\createTag "strikeout", tagList.strikeout\getTagParams!
    }
    dataTemp\insertSections ASS.Section.Text text

    oldBounds = dataTemp\getLineBounds!
    old_x1, old_y1 = oldBounds[1].x or 0, oldBounds[1].y or 0
    old_x2, old_y2 = oldBounds[2].x or 0, oldBounds[2].y or 0
    oldWidth = old_x2 - old_x1
    oldHeight = old_y2 - old_y1

    bounds = {Yutils.shape.bounding shape}
    new_x1, new_y1 = bounds[1] or 0, bounds[2] or 0
    new_x2, new_y2 = bounds[3] or 0, bounds[4] or 0
    newWidth = new_x2 - new_x1
    newHeight = new_y2 - new_y1

    widthRatio = oldWidth/newWidth
    heightRatio = oldHeight/newHeight

    if math.abs(widthRatio - 1) <= 0.01 and math.abs(heightRatio - 1) <= 0.01
        return shape, 1, 1

    xOffset = old_x1 - (new_x1 * widthRatio)
    yOffset = old_y1 - (new_y1 * heightRatio)
    shape = Yutils.shape.filter shape, (x, y) ->
        (x * widthRatio) + xOffset + prevSpace, y * heightRatio + yOffset

    shape, widthRatio, heightRatio


getSpaceWidth = (data, section, fontObj, tagList) ->
    if jit.os == "Windows"
        return aegisub.text_extents section\getStyleTable!, " "

    fn = (text) ->
        shape = getYutilsShape text, fontObj
        width = aegisub.text_extents section\getStyleTable!, text
        _, widthRatio = getTextDrawingScale data, text, tagList, shape, 0
        width * widthRatio

    width1 = fn ". ."
    width2 = fn ".."
    width1 - width2

lineCollection = {

    collectTags: (lines, errorOnNoTags = false, checkDrawing = false) ->
        collection =
            tagList: {}
            tagTypes: {start_tag: false, inline_tags: false, transforms: false}
            multiple_inline_tags: false

        lines\runCallback (lines, line, i) ->
            _util.checkCancellation!
            _util.progress "Collecting tags", i, #lines.lines
            data = ASS\parse line

            -- Determine if there is a tag at the start of the line
            collection.tagTypes.start_tag, startTagIndex = lineData.firstSectionIsTag data

            if not collection.multiple_inline_tags
                tagSectionCount = data\getSectionCount ASS.Section.Tag
                collection.tagTypes.inline_tags = tagSectionCount > 1
                if startTagIndex and tagSectionCount > 2
                    collection.multiple_inline_tags = true
                elseif not startTagIndex and tagSectionCount > 1
                    collection.multiple_inline_tags = true

            -- Collect all the tags in the line
            for tag in *data\getTags!
                collection.tagList[#collection.tagList + 1] = tag.__tag.name

                if tag.class == ASS.Tag.Transform
                    collection.tagTypes.transforms = true
                    for transformTag in *tag.tags\getTags!
                        collection.tagList[#collection.tagList + 1] = transformTag.__tag.name

            if checkDrawing
                drawingSectionCount = data\getSectionCount ASS.Section.Drawing
                if drawingSectionCount > 0
                    collection.tagList[#collection.tagList + 1] = "drawing"

        -- No tags could be found in the selected lines
        if errorOnNoTags and #collection.tagList == 0
            _util.windowError "No tags found in the selected lines."

        -- Deduplicate the taglist
        collection.tagList = list.uniq collection.tagList

        -- Sort the taglist
        collection.tagList = [tag for tag in *(list.join(ASS.tagSortOrder, {"transform"})) when list.find collection.tagList, (value) -> value == tag ]
        collection

}

lineData = {

    getLineBounds: (data, noBordShad = false, noClip = false, noBlur = false, noPerspective = false) ->
        assertLineContent data

        local bound

        unless noBordShad or noClip or noBlur or noPerspective
            bound = data\getLineBounds!
        else
            dataCopy = data\copy!
            if noBordShad
                for tag in *{"outline", "outline_x", "outline_y", "shadow", "shadow_x", "shadow_y"}
                    dataCopy\replaceTags {ASS\createTag tag, 0}

            if noClip
                for tag in *ASS.tagNames.clips
                    dataCopy\removeTags tag

            if noBlur
                for tag in *{"blur", "blur_edges"}
                    dataCopy\removeTags tag

            if noPerspective
                for tag in *{"shear_x", "shear_y", "angle", "angle_x", "angle_y"}
                    dataCopy\replaceTags {ASS\createTag tag, 0}

            bound = dataCopy\getLineBounds!

        bound


    getBoundingBox: (data, noBordShad = false, noClip = false, noBlur = false, noPerspective = false) ->
        bound = lineData.getLineBounds data, noBordShad, noClip, noBlur, noPerspective

        x1, y1 = bound[1].x, bound[1].y
        x2, y2 = bound[2].x, bound[2].y

        x1, y1, x2, y2


    firstSectionIsTag: (data) ->
        assertLineContent data

        local firstSectionIsTag, startTagIndex
        for index, section in ipairs data.sections
            continue if section.class == ASS.Section.Comment
            if section.class == ASS.Section.Tag
                firstSectionIsTag = true 
                startTagIndex = index
            break
        firstSectionIsTag, startTagIndex


    trim: (data) ->
        assertLineContent data
        trimLeft, trimRight, t = {}, {}, 0
        data\callback ((section, _, _, j) ->
            t = j
            value = section\getString!
            value = value\gsub "%s*\\N%s*", "\\N"
            if value\match "^\\N"
                table.insert trimRight, j - 1
            if value\match "\\N$"
                table.insert trimLeft, j + 1
            section.value = value
        ), ASS.Section.Text

        return if t == 0
        table.insert trimLeft, 1, 1
        table.insert trimRight, t

        data\callback ((section, _, _, j) ->
            for item in *trimLeft
                section\trimLeft! if item == j
            for item in *trimRight
                section\trimRight! if item == j
        ), ASS.Section.Text

    getTextShape: (data) ->
        assertLineContent data

        dataCopy = data\copy!
        pos, align, org = dataCopy\getPosition!
        alignIs = align\getSet!

        lineData.trim dataCopy
        tbl = {{}}

        dataCopy\callback ((section) ->
            value = section\getString!
            fontObj, tagList = section\getYutilsFont!
            tagList = (tagList\copy!).tags

            -- Get width of space
            spaceWidth = getSpaceWidth data, section, fontObj, tagList

            splitTable, splitNos = string.split value, "\\N"
            for index, split in ipairs splitTable
                table.insert tbl, {} if index > 1
                width, height, descent = aegisub.text_extents section\getStyleTable!, split
                shape = getYutilsShape split, fontObj

                if split == ""
                    if index == 1 and #tbl > 1
                        continue
                    elseif index == splitNos
                        continue
                    else
                        width, height, descent = aegisub.text_extents section\getStyleTable!, " "
                        height /= 2
                        width = 0
                        shape = nil
                elseif split\match "^%s*$"
                    width = split\match("^%s*")\len! * spaceWidth
                    shape = nil
                elseif jit.os != "Windows"
                    shape, widthRatio, heightRatio = getTextDrawingScale data, split, tagList, shape, spaceWidth
                    width *= widthRatio
                extents = {width: width, height: height, ascent: height - descent, descent: descent}

                table.insert tbl[#tbl], {tagList: tagList, extents: extents, shape: shape}
        ), ASS.Section.Text

        -- Get maximum width, maximum height, maximum ascent of all lines and offsetTable for each line break
        maxHeight, maxWidth, maxExtents, heightTable = 0, 0, {}, {}
        for index, item in ipairs tbl
            currMaxHeight, currMaxAscent, currMaxDescent, currMaxWidth = 0, 0, 0, 0
            for sec in *item
                currMaxWidth += sec.extents.width
                currMaxHeight = math.max(currMaxHeight, sec.extents.height)
                currMaxAscent = math.max(currMaxAscent, sec.extents.ascent)
                currMaxDescent = math.max(currMaxDescent, sec.extents.descent)

            maxHeight += currMaxHeight
            maxWidth = math.max(maxWidth, currMaxWidth)
            table.insert maxExtents, {maxAscent: currMaxAscent, maxDescent: currMaxDescent, maxWidth: currMaxWidth}
            table.insert heightTable, currMaxHeight

        -- Shamelessly stolen from ILL
        offsetHeightA, heightA = {}, 0
        offsetHeightB, heightB = {}, 0
        for i = 1, #heightTable
            j = #heightTable - i + 1
            -- adds the value of the current line break height value
            offsetHeightA[i] = heightA
            offsetHeightB[j] = heightB
            -- gets the value of the height of the next line break 
            heightA += heightTable[i]
            heightB += heightTable[j]

        drawing = ""
        for index, item in ipairs tbl
            xOffset = 0
            for sec in *item
                {:tagList, :extents, :shape} = sec
                if not shape
                    xOffset += extents.width
                    continue

                -- Get y-offset
                local lineBreakOffset, heightDifferenceOffset
                if alignIs.bottom
                    lineBreakOffset = offsetHeightB[index]
                    heightDifferenceOffset = -(maxExtents[index].maxDescent - extents.descent)
                elseif alignIs.top
                    lineBreakOffset = -offsetHeightA[index]
                    heightDifferenceOffset = maxExtents[index].maxAscent - extents.ascent
                else
                    lineBreakOffset = (offsetHeightB[index] - offsetHeightA[index]) / 2
                    heightDifferenceOffset = ((maxExtents[index].maxAscent - maxExtents[index].maxDescent) - (extents.ascent - extents.descent)) / 2
                yOffset = heightDifferenceOffset - lineBreakOffset

                -- Get x-offset
                xalignShift = ((maxWidth - maxExtents[index].maxWidth) * an_xshift[align.value])

                shape = Yutils.shape.filter shape, (x, y) -> x + xOffset + xalignShift, y + yOffset

                tagList.scale_x.value = 100
                tagList.scale_y.value = 100
                tagList.position.x = pos.x
                tagList.position.y = pos.y
                tagList.origin.x = org.x
                tagList.origin.y = org.y

                shape = perspective tagList, maxWidth, extents.height, shape

                xOffset += extents.width
                drawing ..= "#{shape} "
        return drawing, maxWidth, maxHeight

    convertTextToShape: (data) ->
        shape = lineData.getTextShape data
        if shape == nil or shape == ""
            logger\log "Text shape not found."
            aegisub.cancel!

        drawing = ASS.Draw.DrawingBase {str: shape}
        data\removeSections 2, #data.sections

        pos, align = data\getPosition!
        drawing\sub pos.x, pos.y

        drawing = data\insertSections ASS.Section.Drawing {drawing}

        align\set 7
        data\insertTags align

        data\removeTags {"angle", "angle_x", "angle_y", "origin", "shear_x", "shear_y", "bold", "italic", "underline", "strikeout", "spacing", "fontsize", "fontname"}
        data\replaceTags {
            ASS\createTag "scale_x", 100
            ASS\createTag "scale_y", 100
        }
        data\cleanTags!

    changeAlignment: (data, targetAlignment = 7) ->
        assertLineContent data
        target = ASS\createTag("align", targetAlignment)
        pos, align, org = data\getPosition!
        return if target\equal align

        drawingSectionCount = data\getSectionCount ASS.Section.Drawing

        if drawingSectionCount > 0

            data\callback ((section) ->
                ex = section\getExtremePoints true
                section\add target\getPositionOffset ex.w, ex.h, align
                data\replaceTags {target}
            ), ASS.Section.Drawing

        else

            _, width, height = lineData.getTextShape data
            pos\add target\getPositionOffset width, height, align

            -- https://github.com/TypesettingTools/line0-Aegisub-Scripts/blob/b6deb78511a0a96fd6fd074d2337cc8a687c9655/l0.Nudge.moon#L222
            effTags = data\getEffectiveTags -1, true, true, false
            trans, tags = effTags\checkTransformed!, effTags.tags
            if tags.angle\modEq(0, 360) and tags.angle_x\modEq(0, 360) and tags.angle_y\modEq(0, 360) and not (trans.angle or trans.angle_x or trans.angle_y)
                data\replaceTags {target, pos}
            else
                data\replaceTags {target, pos, org}

    pathfinder: (data, mode) ->
        assertLineContent data

        local clip
        vectorialClip = data\getTags "clip_vect"
        if #vectorialClip == 0
            rectangularClip = data\getTags "clip_rect"
            if #rectangularClip != 0
                clip = rectangularClip[1]\getDrawing!\toString!
            else
                logger\log "Rectangular or Vectorial clip was expected but not found."
                aegisub.cancel!
        else
            clip = vectorialClip[1]\getDrawing!\toString!

    insertTransformTag: (data, tags, t1, t2, accel, index = 1, sectionPosition, direct) ->
        assertLineContent data

        if type(tags) != "table"
            logger\error "argument #2 (tags) to insertTransformTag() must be a table of tags , got type #{type(tags)}"

        transform = {ASS\createTag 'transform', _, t1, t2, accel}
        for tag in *tags
            if not tag.class or not tag.class == ASS.Tag
                logger\error "argument #2 (tags) to insertTransformTag() must be a table of tag object"

            if not ASS.tagMap[tag.__tag.name].props.transformable
                logger\error "argument #2 (tags) to insertTransformTag() contains tag that is not transformable."

            -- table.insert transform[1].tags.tags, tag
            transform[1].tags\insertTags tag
        data\insertTags transform, index, sectionPosition, direct

}


textSection = {

    getTags: (data, section, listOnly = false) ->
        assertLineContent data
        assertTextSection section

        index = section.index
        local tags
        for i = index - 1, 0, -1
            break if i == 0
            sec = data.sections[i]
            continue if sec.class == ASS.Section.Comment 
            tags = (sec\getEffectiveTags false, false, true).tags
            break

        if listOnly and tags
            tagList = [key for key in pairs tags]
            return tagList

        tags

    -- insertTagsAtChar: (data, section, index, tags) ->
    --     assertLineContent data
    --     assertTextSection section
    --
    --     sectionIndex = section.index
    --     table.insert section, sectionIndex + 1

}


tagSection = {

    replaceTags: (section, tags, index) ->
        assertTagSection section

        if type(tags) != "table"
            logger\error "argument #2 (tags) to replaceTags() must be a table of tags , got type #{type(tags)}"

        if index != nil
            logger\assert math.isInt(index) and index != 0,
                "argument #4 (index) must be an integer != 0, got '#{tostring(index)}' of type #{type(index)}."

        if index == -1 or index == nil or #(section\getTags "reset") > 0
            index = #section.tags + 1

        for tag in *tags

            tagName = tag.__tag.name
            tagInSection = section\getTags tagName

            if #tagInSection > 0
                section\removeTags tagName
                index -= 1

            section\insertTags tag, index

}


_tag = {

    color: {

        extractColor: (tag) ->
            local r, g, b
            if type(tag) == "string"
                r, g, b = util.extract_color tag
            elseif type(tag) == "table"
                r, g, b = table.unpack tag
            else
                logger\assert tag.class == ASS.Tag.Color, " Expected color tag . Got something else."
                r, g, b = tag\getTagParams!
            return r, g, b

        getXYZ: (tag) ->
            r, g, b = _tag.color.extractColor tag

            r, g, b = r/0xFF, g/0xFF, b/0xFF

            f = (n) ->
                if n > 0.04045
                    return ((n + 0.055) / 1.055) ^ 2.4
                else
                    return n / 12.92

            r, g, b = f(r), f(g), f(b)

            x = r*0.4124564 + g*0.3575761 + b*0.1804375
            y = r*0.2126729 + g*0.7151522 + b*0.0721750
            z = r*0.0193339 + g*0.1191920 + b*0.9503041

            x, y, z


        getLAB: (tag) ->
            xyz2lab = (x, y, z) ->
                Xn, Yn, Zn = 0.95047, 1.0, 1.08883

                x, y, z = x/Xn, y/Yn, z/Zn

                f = (n) ->
                    if n > 0.008856
                        return n ^ (1/3)
                    else
                        return (903.3 * n + 16) / 116

                x, y, z = f(x), f(y), f(z)

                l = (116 * y) - 16
                a = 500 * (x - y)
                b = 200 * (y - z)

                l, a, b


            x, y, z = _tag.color.getXYZ tag
            l, a, b = xyz2lab x, y, z
            l, a, b


        getDeltaE: (color1, color2, weights = {}) ->
            l1, a1, b1 = _tag.color.getLAB color1
            l2, a2, b2 = _tag.color.getLAB color2

            x1 = {L: l1, A: a1, B: b1}
            x2 = {L: l2, A: a2, B: b2}

            radiansToDegrees = (rad) ->
                rad * 180/math.pi

            degreesToRadians = (deg) ->
                deg * math.pi/180

            gethPrimeFn = (x, y) ->
                if x == 0 and y == 0
                    return 0
                hueAngle = radiansToDegrees(math.atan(x, y))
                if hueAngle > 0
                    return hueAngle
                else
                    return hueAngle + 360

            getDeltahPrime = (c1, c2, hPrime1, hPrime2) ->
                -- If either C'1 or C'2 is 0, then Δh' is irrelevant and may be set to 0
                if c1 == 0 or c2 == 0
                    return 0

                if math.abs(hPrime1 - hPrime2) <= 180
                    return hPrime2 - hPrime1

                if hPrime2 <= hPrime1
                    return hPrime2 - hPrime1 + 360
                else
                    return hPrime2 - hPrime1 - 360

            gethBarPrime = (hPrime1, hPrime2) ->
                if math.abs(hPrime1 - hPrime2) > 180
                    return (hPrime1 + hPrime2 + 360) / 2
                return (hPrime1 + hPrime2) / 2

            getT = (hBarPrime) ->
                return 1 -
                    0.17 * math.cos(degreesToRadians(hBarPrime - 30)) +
                    0.24 * math.cos(degreesToRadians(2 * hBarPrime)) +
                    0.32 * math.cos(degreesToRadians(3 * hBarPrime + 6)) -
                    0.20 * math.cos(degreesToRadians(4 * hBarPrime - 63))

            getRsubT = (cBarPrime, hBarPrime) ->
                return -2 *
                    math.sqrt(
                        cBarPrime^7 / (cBarPrime^7 + 25^7)
                    ) *
                        math.sin(
                            degreesToRadians(
                                60 *
                                math.exp(
                                    -(
                                        ((hBarPrime - 275) / 25) ^ 2
                                    )
                                )
                            )
                        )

            deltaPrime = x2.L - x1.L

            ksubL = weights.lightness or 1
            ksubC = weights.chroma or 1
            ksubH = weights.hue or 1

            deltaLPrime = x2.L - x1.L

            lBar = (x1.L + x2.L) / 2

            c1 = math.sqrt(x1.A^2 + x1.B^2)
            c2 = math.sqrt(x2.A^2 + x2.B^2)

            cBar = (c1 + c2) / 2

            aPrime1 = x1.A +
                (x1.A / 2) *
                (1 - math.sqrt(
                    cBar^7 /
                    (cBar^7 + 25^7)
                ))

            aPrime2 = x2.A +
                (x2.A / 2) *
                (1 - math.sqrt(
                    cBar^7 /
                    (cBar^7 + 25^7)
                ))

            cPrime1 = math.sqrt(
                aPrime1^2 + x1.B^2
            )

            cPrime2 = math.sqrt(
                aPrime2^2 + x2.B^2
            )

            cBarPrime = (cPrime1 + cPrime2) / 2

            deltaCPrime = cPrime2 - cPrime1

            sSubL = 1 + (
                (0.015 * (lBar - 50)^2) /
                math.sqrt(20 + (lBar - 50)^2)
            )

            sSubC = 1 + 0.045 * cBarPrime

            hPrime1 = gethPrimeFn(x1.B, aPrime1)
            hPrime2 = gethPrimeFn(x2.B, aPrime2)
            deltahPrime = getDeltahPrime(c1, c2, hPrime1, hPrime2)
            deltaHPrime = 2 * math.sqrt(cPrime1 * cPrime2) * math.sin(degreesToRadians(deltahPrime) / 2)
            hBarPrime = gethBarPrime(hPrime1, hPrime2)
            t = getT(hBarPrime)
            sSubH = 1 + 0.015 * cBarPrime * t
            rSubT = getRsubT(cBarPrime, hBarPrime)

            -- Put it all together
            lightness = deltaLPrime / (ksubL * sSubL)
            chroma = deltaCPrime / (ksubC * sSubC)
            hue = deltaHPrime / (ksubH * sSubH)

            return math.sqrt(
                lightness^2 +
                chroma^2 +
                hue^2 +
                rSubT * chroma * hue
            )

    }

}


_shape = {

    pathfinder: (mode, shape1, shape2) ->

        if shape1.class != ASS.Section.Drawing and shape1.class != ASS.Draw.DrawingBase
            logger\log " Expected a drawing section or drawing. Got something else."
            aegisub.cancel!

        base = Path(shape1\toString!)

        if shape2.class == ASS.Section.Drawing or shape2.class == ASS.Draw.DrawingBase
            shape2 = Path(shape2\toString!)
        elseif shape2.class == ASS.Tag.ClipRect or shape2.class == ASS.Tag.ClipVect
            shape2 = Path(shape2\getDrawing!\toString!)

        local shape
        switch mode
            when "Unite" then shape = base\unite shape2
            when "Intersect" then shape = base\intersect shape2
            when "Difference" then shape = base\difference shape2
            when "Exclude" then shape = base\exclude shape2
            else
                logger\log "\"#{mode}\" is not a valid pathfinder mode."
                aegisub.cancel!

        shape = shape\export!
        shape = nil if shape == ""
        shape = ASS.Draw.DrawingBase {str: shape}
        shape1.contours = shape.contours

}


_util = {

    setOgLineExtradata: (line, extradataName) ->
        line\setExtraData extradataName, { originalText: line.text, uuid: util.uuid! }

    revertLines: (sub, sel, extradataName) ->

        decode = (line) ->
            return if not line.extra
            extradata = line.extra[extradataName]
            return if not extradata
            json.decode extradata

        uuids = {}
        for index in *sel
            line = sub[index]
            data = decode line
            continue unless data

            unless uuids[data.uuid]
                line.text = data.originalText
                line.number = index
                line.extra[extradataName] = nil
                uuids[data.uuid] = line

        indicesToNuke = {}
        for i = 1, #sub
            line = sub[i]
            data = decode line
            continue unless data 

            if uuids[data.uuid]
                oldLine = uuids[data.uuid]

                if i < oldLine.number
                    oldLine.number = i
                elseif i > oldLine.number
                    indicesToNuke[#indicesToNuke+1] = i

        for _, line in pairs uuids
            sub[line.number] = line

        sub.delete indicesToNuke

    windowError: ( errorMessage ) ->
        aegisub.dialog.display { { class: "label", label: errorMessage } }, { "&Close" }, { cancel: "&Close" }
        aegisub.cancel!

    windowAssertError: ( condition, errorMessage ) ->
        if not condition
            aegisub.dialog.display { { class: "label", label: errorMessage } }, { "&Close" }, { cancel: "&Close" }
            aegisub.cancel!

    progress: (title, count, total) ->
        aegisub.progress.title(title)
        aegisub.progress.task("Processing line "..count.."/"..total)
        aegisub.progress.set(100*count/total)

    checkCancellation: ->
        aegisub.cancel! if aegisub.progress.is_cancelled!

    checkVideoIsOpen: ->
        if aegisub.project_properties!.video_file == ""
            return false
        return true

    getFramerate: (default = 23.379) ->
        if aegisub.project_properties!.video_file == ""
            return default
        else
            ref_ms = 100000000                          -- 10^8 ms ~~ 27.7h
            ref_frame = aegisub.frame_from_ms(ref_ms)
            framerate = ref_frame * 1000 / ref_ms
            return framerate

}


lib = {
    :lineCollection
    :lineData
    :textSection
    :tagSection
    :_tag
    :_shape
    :_util
}


if haveDepCtrl
    lib.version = depctrl
    return depctrl\register lib
else
    return lib