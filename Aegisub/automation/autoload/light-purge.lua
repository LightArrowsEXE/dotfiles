script_name = "TXT Cleanup"
script_description = "remove actors and/or linebreaks"
script_author = "garret"
script_version = "2.1.0"

local function main(sub, conf)
    for i = 1, #sub do
        if sub[i].class == "dialogue" then
            local line = sub[i]
            if conf.purge_actors == true then
                line.actor = ""
            end
            if conf.purge_linebreaks == true then
                line.text = line.text:gsub(" *\\[Nn] *", " ")
            end
            if conf.convert_hard_space == true then
                line.text = line.text:gsub("\\h", " ")
            end
            sub[i] = line
        end
    end
end

local function conf()
    local conf = {
        {
            class = "checkbox",
            name = "purge_actors",
            x = 0,
            y = 0,
            width = 1,
            height = 1,
            label = "Remove Actors",
            value = true,
        },
        {
            class = "checkbox",
            name = "purge_linebreaks",
            x = 0,
            y = 1,
            width = 1,
            height = 1,
            label = "Remove Linebreaks",
            value = true,
        },
        {
            class = "checkbox",
            name = "convert_hard_space",
            x = 0,
            y = 2,
            width = 1,
            height = 1,
            label = "Convert Hard spaces (\\h)",
            value = true,
        },
    }
    return conf
end
aegisub.register_filter(script_name, script_description, 1, main, conf)
