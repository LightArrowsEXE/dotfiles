export script_name = "Fold Operations"
export script_description = "Different operations on folds"
export script_version = "1.3.2"
export script_author = "PhosCity"
export script_namespace = "phos.FoldOperations"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json" },
        {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
        "aegisub.clipboard"
    }
}
LineCollection, Functional, AegiGui, clipboard = depctrl\requireModules!
{:list, :string, :table, :util} = Functional

logger = depctrl\getLogger!
config = depctrl\getConfigHandler {commentAroundFold: false, foldmarker: ">", markFolds: true}
config\load!
opt = config.c


-- parse the fold extradata in a line
parseLineFold = (line) ->
    return if not line.extra

    info = line.extra["_aegi_folddata"]
    return if not info

    side, collapsed, id = info\match("^(%d+);(%d+);(%d+)$")
    return {:side, :collapsed, :id}


-- returns the fold id that is available to be used
highestID = (sub) ->
    currHighestID = 0
    for i = 1, #sub
        continue unless sub[i].class == "dialogue"
        line = sub[i]
        foldData = parseLineFold line
        continue unless foldData
        currHighestID = math.max currHighestID, foldData.id
    currHighestID + 1


-- returns the fold nested level
getFoldLevel = (sub, act) ->
    openFolds, closedFolds = {}, {}
    for i = 1, #sub
        continue unless sub[i].class == "dialogue"
        line = sub[i]
        foldData = parseLineFold line
        if foldData and foldData.side == "0"
            table.insert openFolds, foldData.id
        elseif foldData and foldData.side == "1"
            table.insert closedFolds, foldData.id
        break if i == act
    openFolds = list.uniq openFolds
    closedFolds = list.uniq closedFolds
    
    openFolds = list.diff openFolds, closedFolds
    #openFolds + 1


-- If you have commented lines around actual lines as fold markers, remove them from selection
correctSelection = (sub, sel) ->
    return sel unless opt.commentAroundFold
    [i for i in *sel when not sub[i].extra["_aegi_folddata"]]


-- selects all the lines in a fold around active line
selectFoldAroundActiveLine = (sub, act) ->
    foldStack, newSelection, foldAroundLine = {}, {}

    for i = 1, #sub
        continue unless sub[i].class == "dialogue"
        line = sub[i]
        folddata = parseLineFold line
        if folddata and folddata.side == "0"
            table.insert foldStack, {index: i, id: folddata.id}

        if i == act
            break if #foldStack == 0
            foldAroundLine = foldStack[#foldStack]
            newSelection = [ j for j = foldAroundLine.index, i ]
        elseif i > act
            table.insert newSelection, i

        if folddata and folddata.side == "1"
            assert(#foldStack > 0 and foldStack[#foldStack].id == folddata.id)
            foldStack[#foldStack] = nil

            if foldAroundLine and foldAroundLine.id == folddata.id
                break

    return newSelection


-- selects lines of all the folds within the selected lines
selectFoldInSelection = (sub, sel) ->
    maxIndex = 0
    finalSelection = {}
    for i in *sel
        continue if i <= maxIndex
        tempSelection = selectFoldAroundActiveLine sub, i
        continue if #tempSelection == 0
        maxIndex = math.max(maxIndex, tempSelection[#tempSelection])
        finalSelection = list.join finalSelection, tempSelection

    finalSelection = list.uniq finalSelection
    table.sort finalSelection
    return finalSelection


-- selects all the lines in a fold among selected lines.
-- If correct_selection is true and if you have commented fold names around fold, it deselects them
selectFold = (sub, sel, correct_selection = true) ->
    local newSelection
    if #sel == 1
        newSelection = selectFoldAroundActiveLine sub, sel[1]
    else
        newSelection = selectFoldInSelection sub, sel

    if correct_selection
        return correctSelection sub, newSelection
    else
        return newSelection


-- remove fold without removing lines
clearFold = (sub, sel) ->
    newSelection = selectFold sub, sel, false
    return if #newSelection == 0

    lines = LineCollection sub, newSelection, -> true
    return if #lines.lines == 0

    linesToRemove = {}
    lines\runCallback (_, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        if line\getExtraData "_aegi_folddata"
            if opt.commentAroundFold
                table.insert linesToRemove, line
            else
                line.extra["_aegi_folddata"] = nil

    lines\replaceLines!
    lines\deleteLines linesToRemove


-- comment all the lines in a fold among selected lines. Remembers lines that were already commented.
commentFold = (sub, sel) ->
    newSelection = selectFold sub, sel
    return if #newSelection == 0

    lines = LineCollection sub, newSelection, -> true
    return if #lines.lines == 0
    lines\runCallback (_, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        if line.comment
            line.extra["fold-operation"] = "commented"
        else
            line.comment = true

    lines\replaceLines!


-- uncomment all the lines in a fold among selected lines. If a line was already commented prior to commenting, they are left commented.
uncommentFold = (sub, sel) ->
    newSelection = selectFold sub, sel
    return if #newSelection == 0

    lines = LineCollection sub, newSelection, -> true
    return if #lines.lines == 0
    lines\runCallback (_, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        if line\getExtraData 'fold-operation'
            line.comment = true
            line.extra["fold-operation"] = nil
        else
            line.comment = false

    lines\replaceLines!


-- toggle comment state on all the lines in a fold around active line. Any commented lines will become uncommented, and vice versa.
-- if any commented lines have the "fold-operation" marker, signifying that they've been commented out by this macro, assume they're not to be uncommented.
toggleCommentFold = (sub, sel) ->
    newSelection = selectFold sub, sel
    return if #newSelection == 0

    lines = LineCollection sub, newSelection, -> true
    return if #lines.lines == 0
    lines\runCallback (lines, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        line.comment = not line.comment unless line.comment and line\getExtraData 'fold-operation'

    lines\replaceLines!


-- toggles the current fold between "commented" and "uncommented". If the fold contains any lines that are uncommented, assume it is uncommented.
stateToggleCommentFold = (sub, sel) ->
    newSelection = selectFold sub, sel
    return if #newSelection == 0

    lines = LineCollection sub, newSelection, -> true
    return if #lines.lines == 0

    isUncommented = (() -> for line in *lines.lines return true if not line.comment)!

    if isUncommented
        commentFold sub, sel
    else
        uncommentFold sub, sel


-- delete all the lines in a fold around active line
deleteFold = (sub, sel) ->
    newSelection = selectFold sub, sel, false
    return if #newSelection == 0

    sub.delete newSelection
    return {newSelection[#newSelection] - #newSelection}


-- copy all the lines in a fold around active line to clipboard. Copies fold state as well as styles.
copyFoldBase = (sub, sel) ->
    newSelection = selectFold sub, sel, false
    return if #newSelection == 0

    lines = LineCollection sub, newSelection, -> true
    return if #lines.lines == 0

    stringToCopy = ""
    lines\runCallback (lines, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        stringToCopy ..= line\__tostring!.."||**||"

        foldData = line\getExtraData '_aegi_folddata'
        commentData = line\getExtraData 'fold-operation'
        if foldData or commentData
            stringToCopy ..= (foldData or "noFold")..","..(commentData or "noComment").. "||**||"
        else
            stringToCopy ..= "noExtradata".."||**||"

        stringToCopy ..= line.styleRef.raw.."\n"

    clipboard.set stringToCopy
    return newSelection


-- copy all the lines in a fold around active line to clipboard
copyFold = (sub, sel) ->
    copyFoldBase sub, sel
    return sel


-- cut all the lines in a fold around active line to clipboard
cutFold = (sub, sel) ->
    newSelection = copyFoldBase sub, sel
    sub.delete newSelection
    return {newSelection[#newSelection] - #newSelection}


-- paste all the folded lines in clipboard. Pastes fold state as well as styles.
pasteFold = (sub, _, act) ->
    dataString = clipboard.get!
    if not dataString or not dataString\match "||Style:"
        logger\log "There are no folded lines in your clipboard. You need to copy the folds using this script."
        aegisub.cancel!

    dialogueRaw, extradata, styleRaw = {}, {}, {}
    for item in *(string.split dataString, "\n")
        continue if item == nil or item  == ""
        dlg, ext, stl = item\match "(.-)||%*%*||(.-)||%*%*||(.*)"
        table.insert dialogueRaw, dlg
        table.insert extradata, ext
        table.insert styleRaw, stl

    -- Validate that the fold that starts definitely ends
    foldValidationTable, minimumID = {}, math.huge
    for fold in *extradata
        continue if fold  == "noExtradata" or fold\match "^noFold"
        side, id = fold\match "^(%d+);%d+;(%d+),"
        minimumID = math.min minimumID, id      -- This will be used later
        foldValidationTable[id] or= {}
        if tonumber(side) == 0
            foldValidationTable[id]["start"] = true
        elseif tonumber(side) == 1
            foldValidationTable[id]["end"] = true
    for _, fold in pairs foldValidationTable
        unless fold.start and fold.end
            logger\log "Fold validation failed. Fold that starts must end and vice versa.\nMake sure you copied folds using the script."
            aegisub.cancel!

    -- Deduplicate style list
    styleRaw = list.uniq styleRaw

    -- Map the raw style text to its fields
    style = {}
    defaultStyleFields = {"name", "fontname", "fontsize", "color1", "color2", "color3", "color4",
        "bold", "italic", "underline", "strikeout", "scale_x", "scale_y", "spacing", "angle",
        "borderstyle", "outline", "shadow", "align", "margin_l", "margin_r", "margin_t", "encoding"}
    for item in *styleRaw
        elements = [x for x in item\gsub("^Style: ", "")\gmatch "([^,]+)"]
        fields = {defaultStyleFields[i], elements[i] for i=1,#elements}

        -- Number fields
        for tag in *{"fontsize", "scale_x", "scale_y", "spacing", "angle", "borderstyle", "outline", "shadow", "align", "margin_l", "margin_r", "margin_t", "encoding"}
            fields[tag] = tonumber(fields[tag])

        -- Boolean fields
        for tag in *{"bold", "italic", "underline", "strikeout"}
            if fields[tag] == "-1"
                fields[tag] = true
            elseif fields[tag] == "0"
                fields[tag] = false

        -- Color fields for some reason
        for tag in *{"color1", "color2", "color3", "color4"}
            fields[tag] ..= "&"

        -- Add missing fields
        fields["margin_b"] = fields["margin_t"]
        fields["section"] = "[V4+ Styles]"
        fields["class"] = "style"

        style[fields.name] = fields

    -- Determine styles that needs to be added
    for i = 1, #sub
        stl = sub[i]
        break if stl.class == "dialogue"
        continue unless stl.class == "style"

        if style[stl.name]
            -- HACK: Remove fields "raw" and "relative_to" to ensure the table equality if all other fields are same
            stl = table.filter stl, (_, key) -> key != "raw"
            stl = table.filter stl, (_, key) -> key != "relative_to"
            if not table.equals style[stl.name], stl
                logger\log "STYLE CONFLICT\nStyle \"#{stl.name}\" already exists in the file but has different field values."
                aegisub.cancel!
            else
                style = table.filter style, (_, key) -> key != stl.name

    -- Insert missing styles
    for i = 1, #sub
        count = i-1
        if sub[i].class == "dialogue"
            for _, stl in pairs style
                sub.insert(count, stl)
                count += 1
            break

    -- Insert lines
    id = highestID sub

    string2line = (lineRaw, ext) ->
        line, extra = {}, {}
        if ext  != "noExtradata"
            foldData, commentData = ext\match "(.-),(.*)"
            if foldData != "noFold"
                foldData = foldData\gsub "(%d+;%d+;)(%d+)", (a, b) -> a..math.floor(b + id - minimumID)
                extra["_aegi_folddata"] = foldData
            if commentData == "commented"
                extra["fold-operation"] = commentData
        with line
            ltype, .layer, s_time, e_time, .style, .actor, .margin_l, .margin_r, .margin_t, .effect, .text = lineRaw\match("(%a+): (%d+),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),([^,]-),(.*)")
            .class = "dialogue"
            .comment = ltype == "Comment" and true or false
            .start_time = util.assTimecode2ms(s_time)
            .end_time = util.assTimecode2ms(e_time)
            .extra = extra
        line


    for index, item in ipairs dialogueRaw
        ext = extradata[index]
        line = string2line item, ext
        sub.insert(act + 1, line)


-- Create a fold around selected lines a commented lines around as fold markers with the user provided name.
createNamedFold = (sub, sel, act) ->
    id = highestID sub
    foldLevel = getFoldLevel sub, act

    str = "
    | label,Enter name of the fold                 | edit,name                         |
    | check,markFolds,Fold Marker,#{opt.markFolds} | edit,foldmarker,#{opt.foldmarker} |
    "
    btn, res = AegiGui.open str
    aegisub.cancel! unless btn
    logger\assert res.name != "", "Fold name cannot be empty!"

    opt.foldmarker = res.foldmarker
    opt.markFolds = res.markFolds
    config\write!

    for i in *{sel[1], sel[#sel]}
        line = sub[i]
        line.actor = ""
        line.effect = ""
        line.comment = true
        line.extra["_aegi_folddata"] = nil

        addFold = (foldType) ->
            line.text = res.markFolds and string.rep(res.foldmarker, foldLevel) .." " or ""
            line.text ..= (res.name)\gsub(".", string.upper)
            line.text ..= foldType == "END" and " END" or ""
            line.extra["_aegi_folddata"] = "#{foldType == "START" and 0 or 1};1;#{id}"
            sub.insert foldType == "START" and i or i+2, line

        if sel[1] == sel[#sel] -- Only 1 line is selected
            addFold "START"
            addFold "END"
            break
        elseif i == sel[1]
            addFold "START"
        elseif i == sel[#sel]
            addFold "END"


-- jump around a fold
jump = (sub, sel, act, mode) ->
    local order
    if mode == "Start" or mode == "Previous"
        order = "reverse"

    _start, _end, _iter = 1, #sub, 1
    if order == "reverse"
        _start, _end, _iter = #sub, 1, -1

    count = 0
    for i = _start, _end, _iter
        if order == "reverse"
            continue if i > act
        else
            continue if i < act

        line = sub[i]
        foldData = parseLineFold line
        continue unless foldData

        if mode == "End"
            return {i} if foldData.side == "1"

        elseif mode == "Start"
            return {i} if foldData.side == "0"

        elseif mode == "Next"
            return {i} if foldData.side == "0"

        elseif mode == "Previous"
            if foldData.side == "0"
                count += 1
                return {i} if count == 2


-- GUI that has all the functions this script provides.
gui = (sub, sel, act) ->
    hint = {
        "Tick this if you add commented lines as fold markers before and after actual lines."
        "Select lines of fold within selected lines."
        "Delete lines of fold within selected lines."
        "Comment lines of fold within selected lines."
        "Uncomment lines of fold within selected lines."
        "If fold contains any uncommented line, comment it. Otherwise uncomment it."
        "Any commented lines will become uncommented and vice versa."
        "Cut fold into clipboard."
        "Copy fold into clipboard."
        "Paste fold from clipboard that you copied using this script."
        "Create a fold around selected lines with name."
        "Remove fold without removing lines."
    }

    str = "
| label,-Config-----                                                               |                                                     |                                         |
| check,commentAroundFold,Comments around fold,#{opt.commentAroundFold},#{hint[1]} | null                                                |                                         |
|                                                                                  |                                                     |                                         |
| label,-Selection-----                                                            | label,-Deletion-----                                | label,-Clear-----                       |
| check,selectFold,Select fold,,#{hint[2]}                                         | check,deleteFold,Delete fold,,#{hint[3]}            | check,clearFold,Clear Fold,,#{hint[12]} |
|                                                                                  |                                                     |                                         |
| label,-Comment----                                                               |                                                     |                                         |
| check,commentFold,Comment,,#{hint[4]}                                            | check,uncommentFold,Uncomment,,#{hint[5]}           | null                                    |
| check,stateToggleCommentFold,Comment or Uncomment Fold,,[[#{hint[6]}]]           | check,toggleCommentFold,Toggle Comments,,#{hint[7]} | null                                    |
|                                                                                  |                                                     |                                         |
| label,-Cut-Copy-Paste-----                                                       |                                                     |                                         |
| check,cutFold,Cut fold,,#{hint[8]}                                               | check,copyFold,Copy fold,,#{hint[9]}                | check,pasteFold,Paste fold,,#{hint[10]} |
|                                                                                  |                                                     |                                         |
| label,-Jump-----                                                                 |                                                     |                                         |
| check,jumpStart,Start of Fold                                                    | check,jumpEnd,End of Fold                           |                                         |
| check,jumpNext,Next Fold                                                         | check,jumpPrevious,Previous Fold                    |                                         |
|                                                                                  |                                                     |                                         |
| label,-Others-----                                                               |                                                     |                                         |
| check,createNamedFold,Create a new named fold around selected lines,,#{hint[11]} |                                                     |                                         |
"
    btn, res = AegiGui.open str

    aegisub.cancel! unless btn
    opt.commentAroundFold = res.commentAroundFold
    config\write!

    if res.selectFold
        newSelection = selectFold sub, sel
        return newSelection

    elseif res.clearFold
        clearFold sub, sel

    elseif res.commentFold
        commentFold sub, sel

    elseif res.uncommentFold
        uncommentFold sub, sel

    elseif res.stateToggleCommentFold
        stateToggleCommentFold sub, sel

    elseif res.toggleCommentFold
        toggleCommentFold sub, sel

    elseif res.cutFold
        cutFold sub, sel

    elseif res.copyFold
        copyFold sub, sel

    elseif res.pasteFold
        pasteFold sub, _, act

    elseif res.deleteFold
        deleteFold sub, sel

    elseif res.createNamedFold
        createNamedFold sub, sel, act

    elseif res.jumpStart
        return jump(sub, sel, act, "Start")
    
    elseif res.jumpEnd
        return jump(sub, sel, act, "End")

    elseif res.jumpNext
        return jump(sub, sel, act, "Next")

    elseif res.jumpPrevious
        return jump(sub, sel, act, "Previous")


depctrl\registerMacros({
    {"01. Select Fold", "Select the fold among the selected lines", selectFold},

    {"02. Comment Fold", "Comment the fold among the selected lines", commentFold},
    {"03. Uncomment Fold", "Uncomment the fold among the selected lines", uncommentFold},
    {"04. Comment or Uncomment Fold", "Comment the fold among the selected lines if it contains uncommented lines, otherwise uncomment it all", stateToggleCommentFold},
    {"05. Toggle Comments in Fold", "Toggle comment state on all lines in selected folds", toggleCommentFold},

    {"06. Delete Fold", "Delete the fold among the selected lines", deleteFold},
    {"07. Clear Fold", "Remove fold without removing lines.", clearFold},

    {"08. Cut Fold", "Cut the fold among the selected lines", cutFold},
    {"09. Copy Fold", "Copy the fold among the selected lines", copyFold},
    {"10. Paste Fold", "Paste the fold from your clipboard", pasteFold},

    {"11. Create Fold Around Selected Lines", "Create a fold around selected lines with a name as comment", createNamedFold}

    {"GUI", "GUI", gui}
})
