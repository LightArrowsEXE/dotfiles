-- Generates a box around the given clip in the style how they look in the TenKen anime.
-- No other usefulness other than typesetting TenKen.
-- Made by Zahuczky for the Kaleido Tenken project (https://github.com/Zahuczky/Zahuczkys-Aegisub-Scripts/blob/main/miscellaneous_scripts/zah.tenkenbox.lua).

script_name = ":: Project-specific/TenKen/Make Box"
script_description = "Boxin"
script_author = "Zahuczky"
script_version = "1.3.1"

function boxer(sub, sel, act)


    GUI = {
          {class= "label",  x= 0, y= 0, width= 1, height= 1, label= "ERABE"},
          {class= "checkbox", name= "incltxt",  x= 0, y= 1, width= 1, height= 1, label= "Include a text line", value= true},
          {class= "intedit", name= "incltxtnum",  x= 2, y= 1, width= 1, height= 1, value= 1},
          {class= "checkbox", name= "inclsep",  x= 0, y= 2, width= 1, height= 1, label= "Include a seperator line", value= true},
          {class= "intedit", name= "inclsepnum",  x= 2, y= 2, width= 1, height= 1, value= 1}
    }

    buttons = {"No transform","Start only transform","Start and end transform","Cancel"}

    pressed, results = aegisub.dialog.display(GUI, buttons)
    if pressed == "Cancel" then aegisub.cancel() end




    line = sub[sel[1]]
    lineplace = sub[sel[1]]
-- read the rect clip
if line.text:match("\\clip%((-?[0-9.]+),(-?[0-9.]+),(-?[0-9.]+),(-?[0-9.]+)%)") then
    aegisub.debug.out("rect")
    clip = line.text:match("\\clip%(([^%)]+)%)")
    xs = { }
    ys = { }
    for x,y in clip:gmatch("(-?[0-9.]+),+(-?[0-9.]+)") do
        table.insert(xs, x)
        table.insert(ys, y)
    end
-- create 4 points from it
    x1 = xs[1]
    y1 = ys[1]
    x2 = xs[2]
    y2 = ys[1]
    x3 = xs[2]
    y3 = ys[2]
    x4 = xs[1]
    y4 = ys[2]

else
    aegisub.debug.out("vect")
    -- parse vect clip
    clip = line.text:match("\\clip%(([^%)]+)%)")
    xs = { }
    ys = { }
    for x,y in clip:gmatch("(-?[0-9.]+) +(-?[0-9.]+)") do
        table.insert(xs, x)
        table.insert(ys, y)
    end
    x1 = xs[1]
    y1 = ys[1]
    x2 = xs[2]
    y2 = ys[2]
    x3 = xs[3]
    y3 = ys[3]
    x4 = xs[4]
    y4 = ys[4]
end



    box_center_x = x1 + (x2 - x1)/2
    box_center_y = y1 + (y2 - y1)/2

-- generate given number of coordinates between my x and y coordinates
numOfPoints = { }
numOfPoints[1] = math.sqrt((x2 - x1)^2 + (y2 - y1)^2) / 5
numOfPoints[2] = math.sqrt((x3 - x2)^2 + (y3 - y2)^2) / 5
numOfPoints[3] = math.sqrt((x4 - x3)^2 + (y4 - y3)^2) / 5
numOfPoints[4] = math.sqrt((x1 - x4)^2 + (y1 - y4)^2) / 5

x_coords1 = { }
y_coords1 = { }
x_coords2 = { }
y_coords2 = { }
x_coords3 = { }
y_coords3 = { }
x_coords4 = { }
y_coords4 = { }
num = 1
for i=1,numOfPoints[1] do
    num = numOfPoints[1]
    la = i / (num + 1)
    table.insert(x_coords1, ((1-la)*x1+(la)*x2))
    table.insert(y_coords1, ((1-la)*y1+(la)*y2))
end
for i=1,numOfPoints[2] do
    num = numOfPoints[2]
    la = i / (num + 1)
    table.insert(x_coords2, ((1-la)*x2+(la)*x3))
    table.insert(y_coords2, ((1-la)*y2+(la)*y3))
end
for i=1,numOfPoints[3] do
    num = numOfPoints[3]
    la = i / (num + 1)
    table.insert(x_coords3, ((1-la)*x3+(la)*x4))
    table.insert(y_coords3, ((1-la)*y3+(la)*y4))
end
for i=1,numOfPoints[4] do
    num = numOfPoints[4]
    la = i / (num + 1)
    table.insert(x_coords4, ((1-la)*x4+(la)*x1))
    table.insert(y_coords4, ((1-la)*y4+(la)*y1))
end

da_x_coords = { }
da_y_coords = { }
for i=1,numOfPoints[1] do
    table.insert(da_x_coords, x_coords1[i])
    table.insert(da_y_coords, y_coords1[i])
end
for i=1,numOfPoints[2] do
    table.insert(da_x_coords, x_coords2[i])
    table.insert(da_y_coords, y_coords2[i])
end
for i=1,numOfPoints[3] do
    table.insert(da_x_coords, x_coords3[i])
    table.insert(da_y_coords, y_coords3[i])
end
for i=1,numOfPoints[4] do
    table.insert(da_x_coords, x_coords4[i])
    table.insert(da_y_coords, y_coords4[i])
end

-- generate shape from xcoords and ycoords
-- watdashape = "m "..x_coords1[1]+math.random(-5,5) .. " " .. y_coords1[2]+math.random(-5,5).." l "
-- for i=3,numOfPoints[1]-2 do
--     watdashape = watdashape .. x_coords1[i]+math.random(-5,5) .. " " .. y_coords1[i]+math.random(-5,5) .. " "
-- end
-- for i=1,numOfPoints[2] do
--     watdashape = watdashape .. x_coords2[i]+math.random(-5,5) .. " " .. y_coords2[i]+math.random(-5,5) .. " "
-- end
-- for i=1,numOfPoints[3] do
--     watdashape = watdashape .. x_coords3[i]+math.random(-5,5) .. " " .. y_coords3[i]+math.random(-5,5) .. " "
-- end
-- for i=1,numOfPoints[4] do
--     watdashape = watdashape .. x_coords4[i]+math.random(-5,5) .. " " .. y_coords4[i]+math.random(-5,5) .. " "
-- end

offsetX = da_x_coords[1]
offsetY = da_y_coords[1]

for i=1,#da_x_coords do
    da_x_coords[i] = da_x_coords[i] - offsetX
    da_y_coords[i] = da_y_coords[i] - offsetY
end

for i=1,#da_x_coords do
    da_x_coords[i] = da_x_coords[i] * 0.98
    da_y_coords[i] = da_y_coords[i] * 0.94
end

dashape = "m "..da_x_coords[1]+math.random(-5,5) .. " " .. da_y_coords[1]+math.random(-5,5).." l "
for i=3,#da_x_coords-2 do
    dashape = dashape .. string.format("%d %d ", da_x_coords[i]+math.random(-5,5), da_y_coords[i]+math.random(-5,5))
end

posX = offsetX * 0.98 + 12
posY = offsetY * 0.94 + 37


linedur = line.end_time - line.start_time - 20
endtransform_text = string.format("\\t(%d,%d,\\fscx30\\1a&HBB&)\\t(%d,%d,\\1a&HFF&)", linedur-240, linedur-160, linedur-160, linedur-160)
endtransform_sepline = string.format("\\t(%d,%d,\\fscx30\\1a&HBB&)\\t(%d,%d,\\1a&HFF&)", linedur-160, linedur-80, linedur-80, linedur-80)
endtransform_box = string.format("\\t(%d,%d,\\fscx20\\fscy20)", linedur-80, linedur)

sepline_length = x2-x1


if pressed == "No transform" then
    line1 = "{\\an7\\shad0.01\\bord10\\1a&HFE&\\3a&HFE&\\blur0.8\\pos("..posX..","..posY..")\\p1\\4c&H1F5306&}"..dashape
    line2 = "{\\an7\\shad0.01\\bord4\\1a&HFE&\\3a&HFE&\\blur0.8\\pos("..posX..","..posY..")\\p1\\4c&HB8DFEB&}"..dashape
    textline = "{\\an4\\fnNyala\\c&H1E2E37&\\pos(371.2,337.6)\\blur0.8}Placeholder"
    sepline = "{\\p1\\an7\\bord0\\blur0.8\\c&H1F5306&\\pos(136.03,378.77)}m 0 0 l "..sepline_length.." 0 "..sepline_length.." 2 0 2"
end
if pressed == "Start only transform" then
    line1 = "{\\fscx20\\fscy20\\bord10\\t(0,80,\\fscx100\\fscy100)\\an7\\shad0.01\\1a&HFE&\\3a&HFE&\\blur0.8\\pos("..posX..","..posY..")\\p1\\4c&H1F5306&}"..dashape
    line2 = "{\\fscx20\\fscy20\\bord4\\t(0,80,\\fscx100\\fscy100)\\an7\\shad0.01\\1a&HFE&\\3a&HFE&\\blur0.8\\pos("..posX..","..posY..")\\p1\\4c&HB8DFEB&}"..dashape
    textline = "{\\an4\\fnNyala\\c&H1E2E37&\\pos(371.2,337.6)\\blur0.8\\fscx33\\1a&HFF&\\t(160,160,\\1a&HBB&)\\t(160,240,\\fscx100\\1a&H00&)}Placeholder"
    sepline = "{\\1a&HFF&\\t(80,80,\\1a&HBB&)\\fscx30\\t(80,160,\\1a&H00&\\fscx100)\\p1\\an7\\bord0\\blur0.8\\c&H1F5306&\\pos(136.03,378.77)}m 0 0 l "..sepline_length.." 0 "..sepline_length.." 2 0 2"
end
if pressed == "Start and end transform" then
    line1 = "{\\fscx20\\fscy20\\bord10\\t(0,80,\\fscx100\\fscy100)\\an7\\shad0.01\\1a&HFE&\\3a&HFE&\\blur0.8\\pos("..posX..","..posY..")\\p1\\4c&H1F5306&"..endtransform_box.."}"..dashape
    line2 = "{\\fscx20\\fscy20\\bord4\\t(0,80,\\fscx100\\fscy100)\\an7\\shad0.01\\1a&HFE&\\3a&HFE&\\blur0.8\\pos("..posX..","..posY..")\\p1\\4c&HB8DFEB&"..endtransform_box.."}"..dashape
    textline = "{\\an4\\fnNyala\\c&H1E2E37&\\pos(371.2,337.6)\\blur0.8\\fscx33\\1a&HFF&\\t(160,160,\\1a&HBB&)\\t(160,240,\\fscx100\\1a&H00&)"..endtransform_text.."}Placeholder"
    sepline = "{\\1a&HFF&\\t(80,80,\\1a&HBB&)\\fscx30\\t(80,160,\\1a&H00&\\fscx100)\\p1\\an7\\bord0\\blur0.8\\c&H1F5306&\\pos(136.03,378.77)"..endtransform_sepline.."}m 0 0 l "..sepline_length.." 0 "..sepline_length.." 2 0 2"
end


offs = 0
if results.incltxt == true then
    offs = offs+1
end
if results.inclsep == true then
    offs = offs+1
end
lineplace.text = line1
sub.insert(sel[1], lineplace)
lineplace.text = line2
sub.insert(sel[1]+1, lineplace)
if results.incltxt == false and results.inclsep == false then
    sub.delete(sel[1]+2)
elseif results.incltxt == true and results.inclsep == false then
    lineplace.text = textline
    sub.insert(sel[1]+2, lineplace)
    sub.delete(sel[1]+3)
elseif results.incltxt == false and results.inclsep == true then
    lineplace.text = sepline
    sub.insert(sel[1]+2, lineplace)
    sub.delete(sel[1]+3)
elseif results.incltxt == true and results.inclsep == true then
    lineplace.text = textline
    sub.insert(sel[1]+2, lineplace)
    lineplace.text = sepline
    sub.insert(sel[1]+3, lineplace)
    sub.delete(sel[1]+4)
end
sel[2]=sel[1]+1


--aegisub.debug.out(line1.."\n"..line2)
return sel
end

aegisub.register_macro(script_name, script_description, boxer)
