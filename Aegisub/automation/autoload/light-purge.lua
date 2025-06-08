script_name = "TXT Cleanup"
script_description = "remove actors and/or linebreaks"
script_author = "garret"
script_version = "2.0.0"

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
    }
    return conf
end
aegisub.register_filter(script_name, script_description, 1, main, conf)
