script_name = "AutoClip"
script_description = "Add clips to subtitles 𝓪𝓾𝓽𝓸𝓶𝓪𝓰𝓲𝓬𝓪𝓵𝓵𝔂"
script_version = "2.1.1"
script_author = "Zahuczky, Akatsumekusa"
script_namespace = "zah.autoclip"
-- Lua version number is always kept aligned with version number in python script.

local last_supported_script_version = "2.0.3"

-----------------------------------------------------------------------------------------------------
-- Organisation of this file:
-- display_configurator and display_configurator derived functions:
--     first_time_python_with_vsrepo_win, check_python_with_vs_win, edit_config_win, etc.
--     This is for the „configuration“ windows that let the user enter python or vsrepo path.
-- display_runner and display_runner derived functions:
--     first_time_dependencies_win, no_dependencies_win, etc.
--     This is for the „execution“ windows that executes commands to install or upgrade dependencies.
-- main functions:
--     first_time_python_vsrepo_main, autoclip_main, edit_config_main, etc.
--     The main logic of Lua side of AutoClip. Calls functions from previous two sections.
-----------------------------------------------------------------------------------------------------



local DepCtrl = require("l0.DependencyControl")({
    feed = "https://raw.githubusercontent.com/Zahuczky/Zahuczkys-Aegisub-Scripts/main/DependencyControl.json",
    {
        {
            "ILL.ILL",
            version = "1.1.0",
            url = "https://github.com/TypesettingTools/ILL-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
        },
        {
            "aka.uikit",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aka.config",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aka.outcome",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "lfs",
        },
        {
            "aka.command",
            version = "1.0.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        },
        {
            "aka.unsemantic",
            version = "1.1.0",
            url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
            feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json"
        }
    }
})
DepCtrl:requireModules()



local ILL = require("ILL.ILL")
local Aegi, Ass, Line, Path, Table = ILL.Aegi, ILL.Ass, ILL.Line, ILL.Path, ILL.Table

local uikit = require("aka.uikit")
local adialog, abuttons, adisplay = uikit.dialog, uikit.buttons, uikit.display
adialog.join = adialog.join_dialog

local outcome = require("aka.outcome")
local ok, err = outcome.ok, outcome.err

local VSREPO_IN_PATH = "vsrepo in PATH (`$ vsrepo --help`)"
local PATH_TO_VSREPO_OLD = "Path to vsrepo.py (`$ python vsrepo.py --help`)"
local PATH_TO_VSREPO = "Path to vsrepo.py (`$ python /path/to/vsrepo.py --help`)"

local default_config = {
    ["venv_activate"] = "",
    ["python"] = "python3",
    ["vsrepo_mode"] = VSREPO_IN_PATH,
    ["vsrepo"] = "vsrepo",
    -- ["disable_layer_mismatch"] = false,
    ["disable_version_notify"] = false
}

local aconfig = require("aka.config").make_editor({
    display_name = "AutoClip",
    presets = {
        ["default"] = default_config
    },
    default = "default"
})
local json = aconfig.json

local validation_func = function(config)
    if type(config) ~= "table" then
        return err("Missing root table.")
    end
    if config["venv_activate"] == nil then
        config["venv_activate"] = default_config["venv_activate"]
    elseif type(config["venv_activate"]) ~= "string" then
        return err("Invalid key \"venv_activate\".")
    end
    if config["python"] == nil then
        config["python"] = default_config["python"]
    elseif type(config["python"]) ~= "string" then
        return err("Invalid key \"python\".")
    end
    if config["vsrepo_mode"] == nil then
        config["vsrepo_mode"] = default_config["vsrepo_mode"]
    elseif config["vsrepo_mode"] == PATH_TO_VSREPO_OLD then
        config["vsrepo_mode"] = PATH_TO_VSREPO
    elseif config["vsrepo_mode"] ~= VSREPO_IN_PATH and config["vsrepo_mode"] ~= PATH_TO_VSREPO then
        return err("Invalid key \"vsrepo_mode\".")
    end
    if config["vsrepo"] == nil then
        config["vsrepo"] = default_config["vsrepo"]
    elseif type(config["vsrepo"]) ~= "string" then
        return err("Invalid key \"vsrepo\".")
    end
    -- if config["disable_layer_mismatch"] == nil then
    --     config["disable_layer_mismatch"] = default_config["disable_layer_mismatch"]
    -- elseif type(config["disable_layer_mismatch"]) ~= "boolean" then
    --     return err("Invalid key \"disable_layer_mismatch\".")
    -- end
    if config["disable_version_notify"] == nil then
        config["disable_version_notify"] = default_config["disable_version_notify"]
    elseif type(config["disable_version_notify"]) ~= "boolean" then
        return err("Invalid key \"disable_version_notify\".")
    end
    return ok(config)
end
local config

local lfs = require("lfs")

local V = require("aka.unsemantic").V
local disable_version_notify_until_next_time = false

local acommand = require("aka.command")
local check_cmd_c = acommand.check_cmd_c
local run_cmd_c = acommand.run_cmd_c
local c = acommand.c
local p = acommand.p



-- display_configurator and display_configurator derived functions
local dialog_welcome = adialog.new({ width = 50 })
                              :label({ label = "Welcome to AutoClip!" })
local dialog_python do
    if jit.os == "Windows" then
        dialog_python = adialog.new({ width = 50 })
                                     :label({ label = "Enter name to Python if it’s in PATH or under venv (`$ python3 --version`) or path to Python executable (`$ /path/to/python3.exe --version`):" })
                                     :edit({ name = "python" })
    else
        dialog_python = adialog.new({ width = 50 })
                                     :label({ label = "Enter name to Python if it’s in PATH or under venv (`$ python3 --version`) or path to Python executable (`$ /path/to/python3 --version`):" })
                                     :edit({ name = "python" })
end end
local dialog_venv_activate do
    if jit.os == "Windows" then
        dialog_venv_activate = adialog.new({ width = 50 })
                                            :label({ label = "(Leave empty unless using Python with venv) Enter path to venv activate script (`$ /path/to/Activate.ps1`):" })
                                            :edit({ name = "venv_activate" })
    else
        dialog_venv_activate = adialog.new({ width = 50 })
                                            :label({ label = "(Leave empty unless using Python with venv) Enter path to venv activate script (`$ source /path/to/activate`):" })
                                            :edit({ name = "venv_activate" })
end end
local dialog_vsrepo = adialog.new({ width = 50 })
                             :label({ label = "Select whether vsrepo is in PATH and enter either the name to vsrepo or path to vsrepo.py:" })
                             :dropdown({ name = "vsrepo_mode", items = { VSREPO_IN_PATH, PATH_TO_VSREPO } })
                             :edit({ name = "vsrepo" })
local dialog_no_vsrepo do
    dialog_no_vsrepo = adialog.new({ width = 50 })
    local subdialog = dialog_no_vsrepo:ifable({ name = "vsrepo_mode", value = VSREPO_IN_PATH })
    subdialog:label({ label = "Unable to find vsrepo with given name." })
    local subdialog = dialog_no_vsrepo:unlessable({ name = "vsrepo_mode", value = VSREPO_IN_PATH })
    subdialog:label({ label = "Unable to find vsrepo with given path." })
end
local dialog_no_python_with_vs do
    dialog_no_python_with_vs = adialog.new({ width = 50 })
    local subdialog = dialog_no_python_with_vs:unlessable({ name = "venv_activate", value = "" })
    subdialog:label({ label = "Unable to activate venv or unable to import VapourSynth (`import vapoursynth`) in given environment." })
    local subdialog = dialog_no_python_with_vs:ifable({ name = "venv_activate", value = "" })
    subdialog:label({ label = "Unable to find Python with VapourSynth (`import vapoursynth`) at given name or path." })
end
local dialog_two_warnings = adialog.new({ width = 50 })
                                   -- :label({ label = "Do you want to disable warning when the number of layers mismatches?" })
                                   -- :checkbox({ label = "Disable", name = "disable_layer_mismatch" })
                                   :label({ label = "Do you want to disable warning when Python script is outdated?" })
                                   :checkbox({ label = "Disable", name = "disable_version_notify" })

local buttons_set_cancel = abuttons.ok("&Set"):close("Cancel")
local buttons_continue_cancel = abuttons.ok("&Continue"):close("Cancel")
local buttons_apply_close = abuttons.ok("&Apply"):close("Close")

local display_configurator = function(dialog, buttons)
    local button, result = adisplay(dialog:load_data(config),
                                    buttons):resolve()
    if buttons:is_ok(button) then
        for k, v in pairs(result) do
            config[k] = v
        end
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)
        return ok()
    else
        return err("[zah.autoclip] Operation cancelled by user")
end end
local display_verified_configurator = function(dialog, buttons, command_f)
    if check_cmd_c(command_f(config)) then
        return ok("Already satisfied")
    else
        return adisplay(dialog:load_data(config),
                        buttons)
            :repeatUntil(function(button, result)
                setmetatable(result, { __index = config })
                if check_cmd_c(command_f(result)) then
                    return ok(result)
                else
                    return err(result)
                end end)
            :andThen(function(result)
                for k, v in pairs(result) do
                    config[k] = v
                end
                aconfig.write_config("zah.autoclip", config)
                    :ifErr(function()
                        aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                        aegisub.debug.out("[aka.config] " .. error .. "\n") end)
                return ok() end)
end end

local command_f_check_python_with_vs_win = function(data)
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -c 'import vapoursynth'\n"
end
local command_f_check_python_with_vs_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -c 'import vapoursynth'\n"
end
local command_f_check_vsrepo_win = function(data)
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           (data["vsrepo_mode"] == VSREPO_IN_PATH and
            p(data["vsrepo"]) .. " --help\n" or
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " --help\n")
end

local first_time_python_with_vsrepo_win = function()
    return display_configurator(dialog_welcome:copy():join(dialog_python):join(dialog_venv_activate):join(dialog_vsrepo),
                                buttons_set_cancel)
end
local first_time_python_unix = function()
    return display_configurator(dialog_welcome:copy():join(dialog_python):join(dialog_venv_activate),
                                buttons_set_cancel)
end
local check_python_with_vs_win = function()
    return display_verified_configurator(dialog_no_python_with_vs:copy():join(dialog_python):join(dialog_venv_activate),
                                         buttons_continue_cancel,
                                         command_f_check_python_with_vs_win)
end
local check_python_with_vs_unix = function()
    return display_verified_configurator(dialog_no_python_with_vs:copy():join(dialog_python):join(dialog_venv_activate),
                                         buttons_continue_cancel,
                                         command_f_check_python_with_vs_unix)
end
local check_vsrepo_win = function()
    return display_verified_configurator(dialog_no_vsrepo:copy():join(dialog_vsrepo),
                                         buttons_continue_cancel,
                                         command_f_check_vsrepo_win)
end
local edit_config_win = function()
    return display_configurator(dialog_python:copy():join(dialog_venv_activate):join(dialog_vsrepo):join(dialog_two_warnings),
                                buttons_apply_close)
end
local edit_config_unix = function()
    return display_configurator(dialog_python:copy():join(dialog_venv_activate):join(dialog_two_warnings),
                                buttons_apply_close)
end



-- display_runner and display_runner derived functions
local dialog_execution_error_label_resolver = {}
dialog_execution_error_label_resolver.resolve = function(item, dialog, x, y, width)
    item = Table.copy(item)
    item.class = "label"
    if dialog["data"]["terminate"] == "exit" then
        item.label = "Command execution exits with code " .. tostring(dialog["data"]["code"]) .. ":"
    else
        item.label = "Command execution terminated with signal " .. tostring(dialog["data"]["code"]) .. ":"
    end
    item.x = x
    item.y = y
    item.width = width
    table.insert(dialog, item)
    return item.y + 1
end
local dialog_click_run_again = adialog.new({ width = 50 })
                                      :label({ label = "You can edit the command below and click „Run Again“ to retry." })
local dialog_command = adialog.new({ width = 50 })
                              :textbox({ height = 12, name = "command" })

local buttons_run_again_cancel = abuttons.ok("&Run Again"):close("Cancel")

local display_runner_with_ignore = function(dialog, buttons)
    local button, result = adisplay(dialog:load_data(config),
                                    buttons):resolve()
    if buttons:is_ok(button) then
        local log, status, terminate, code = run_cmd_c(result["command"])
        if status then
            return ok() -- XXX WRONG USE E() (I’ve no idea what this message meant when I left it.)
        else
            dialog = adialog.new({ width = 50 })
                            :load_data({ ["command"] = result["command"] })
                            :load_data({ ["log"] = log, ["status"] = status, ["terminate"] = terminate, ["code"] = code })
            table.insert(dialog, setmetatable({}, { __index = dialog_execution_error_label_resolver }))
            dialog:textbox({ height = 12, name = "log" })
                  :join(dialog_click_run_again)
                  :join(dialog_command)

            return adisplay(dialog, buttons_run_again_cancel)
                :repeatUntil(function(button, result)
                    local log, status, terminate, code = run_cmd_c(result["command"])
                    if status then
                        return ok()
                    else
                        result["log"] = log result["status"] = status result["terminate"] = terminate result["code"] = code
                        return err(result)
                    end end)
        end
    elseif buttons:is_close(button) then
        return err("[zah.autoclip] Operation cancelled by user")
    elseif button == "Remind Me Next Time" then
        disable_version_notify_until_next_time = true
        return ok()
    elseif button == "Do Not Show Again" then
        config["disable_version_notify"] = true
        aconfig.write_config("zah.autoclip", config)
            :ifErr(function()
                aegisub.debug.out("[aka.config] Failed to write config to file.\n")
                aegisub.debug.out("[aka.config] " .. error .. "\n") end)
        return ok()
    else
        error("[zah.autoclip] Reach if else end")
end end
local display_runner = display_runner_with_ignore

local dialog_requires_install = adialog.new({ width = 50 })
                                       :label({ label = "AutoClip requires additional dependencies to be installed." })
local dialog_click_run = adialog.new({ width = 50 })
                                :label({ label = "Click „Run“ to execute the following commands. You may edit the command before running, or copy the command and execute it in terminal." })
local dialog_failed_to_execute = adialog.new({ width = 50 })
                                        :label({ label = "Failed to execute AutoClip." })
local dialog_click_run_and_reinstall = adialog.new({ width = 50 })
                                              :label({ label = "Click „Run“ to execute the following commands and reinstall AutoClip. You may edit the command before running, or copy the command and execute it in terminal." })
local dialog_out_of_date = adialog.new({ width = 50 })
                                  :label({ label = "AutoClip dependencies are out of date." })
local dialog_click_run_command_and_update = adialog.new({ width = 50 })
                                                   :label({ label = "Click „Run Command“ to execute the following commands and update AutoClip. You may edit the command before running, or copy the command and execute it in terminal." })
local dialog_unsupported = adialog.new({ width = 50 })
                                  :label({ label = "AutoClip dependencies are out of date and no longer supported." })

local dialog_requires_vs_dependencies = adialog.new({ width = 50 })
                                               :label({ label = "AutoClip requires additional VapourSynth plugins to be installed." })
local dialog_follow_install = adialog.new({ width = 50 })
                                               :label({ label = "Please follow the links below and install the required plugins." })
local dialog_update_requires_vs_dependencies = adialog.new({ width = 50 })
                                               :label({ label = "The newly installed version requires additional VapourSynth plugins to be installed." })

local buttons_run_cancel = abuttons.ok("&Run"):close("Cancel")
local buttons_cancel = abuttons.close("Cancel")
local buttons_run_command_ignore_cancel = abuttons.ok("&Run Command")("Remind Me Next Time")("Do Not Show Again"):close("Cancel")
local buttons_run_command_cancel = abuttons.ok("&Run Command"):close("Cancel")

local data_command_win = { ["command"] = function(_, data)
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ensurepip\n" .. 
           p(data["python"]) .. " -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
           p(data["python"]) .. " -m pip install ass-autoclip --upgrade --force-reinstall --no-deps\n" ..
           (data["vsrepo_mode"] == VSREPO_IN_PATH and
            p(data["vsrepo"]) .. " update\n" ..
            p(data["vsrepo"]) .. " install lsmas dfttest rgvs\n" ..
            p(data["vsrepo"]) .. " upgrade lsmas dfttest rgvs\n" or
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " update\n" ..
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " install lsmas dfttest rgvs\n" ..
            p(data["python"]) .. " " .. p(data["vsrepo"]) .. " upgrade lsmas dfttest rgvs\n") end }
local data_command_python_unix = { ["command"] = function(_, data)
            return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
                   p(data["python"]) .. " -m ensurepip\n" .. 
                   p(data["python"]) .. " -m pip install numpy PySide6 scikit-image --upgrade --upgrade-strategy eager\n" .. 
                   p(data["python"]) .. " -m pip install ass-autoclip --upgrade --force-reinstall --no-deps\n" end }
local data_command_vs_unix = { ["command"] = "lsmas (https://aur.archlinux.org/packages/vapoursynth-plugin-lsmashsource-git)\n" .. 
                                             "dfttest (https://aur.archlinux.org/packages/vapoursynth-plugin-dfttest-git)\n" .. 
                                             "rgvs (https://aur.archlinux.org/packages/vapoursynth-plugin-removegrain-git)\n" }
local data_command_update_win = { ["command"] = function(_, data)
           return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
                  p(data["python"]) .. " -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" ..
                  (data["vsrepo_mode"] == VSREPO_IN_PATH and
                   p(data["vsrepo"]) .. " update\n" ..
                   p(data["vsrepo"]) .. " install lsmas dfttest rgvs\n" ..
                   p(data["vsrepo"]) .. " upgrade lsmas dfttest rgvs\n" or
                   p(data["python"]) .. " " .. p(data["vsrepo"]) .. " update\n" ..
                   p(data["python"]) .. " " .. p(data["vsrepo"]) .. " install lsmas dfttest rgvs\n" ..
                   p(data["python"]) .. " " .. p(data["vsrepo"]) .. " upgrade lsmas dfttest rgvs\n") end }
local data_command_python_update_unix = { ["command"] = function(_, data)
                   return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
                          p(data["python"]) .. " -m pip install ass-autoclip --upgrade --upgrade-strategy eager\n" end }

local command_f_check_dependencies_win = function(data)
    return (data["venv_activate"] ~= "" and p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-dependencies\n"
end
local command_f_check_dependencies_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-dependencies\n"
end
local command_f_check_python_dependencies_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-python-dependencies\n"
end
local command_f_check_vs_dependencies_unix = function(data)
    return (data["venv_activate"] ~= "" and "source " .. p(data["venv_activate"]) .. "\n" or "") ..
           p(data["python"]) .. " -m ass_autoclip --check-vs-dependencies\n"
end

local first_time_dependencies_win = function()
    local dialog
    local result
    while not check_cmd_c(command_f_check_dependencies_win(config)) do
        if not dialog then
            dialog = adialog.new({ width = 50 })
                            :join(dialog_requires_install)
                            :join(dialog_click_run)
                            :join(dialog_command)
                            :load_data(data_command_win)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local first_time_python_dependencies_unix = function()
    local dialog
    local result
    while not check_cmd_c(command_f_check_python_dependencies_unix(config)) do
        if not dialog then
            dialog = adialog.new({ width = 50 })
                            :join(dialog_requires_install)
                            :join(dialog_click_run)
                            :join(dialog_command)
                            :load_data(data_command_python_unix)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local first_time_vs_dependencies_unix = function()
    if not check_cmd_c(command_f_check_vs_dependencies_unix(config)) then
        adisplay(adialog.new({ width = 50 })
                         :join(dialog_requires_vs_dependencies)
                         :join(dialog_follow_install)
                         :join(dialog_command)
                         :load_data(data_command_vs_unix),
                 buttons_cancel):resolve()
        return err()
    end
    return ok("Already satisfied")
end

local no_dependencies_win = function()
    local dialog
    local result
    while not check_cmd_c(command_f_check_dependencies_win(config)) do
        if not dialog then
            dialog = adialog.new({ width = 50 })
                            :join(dialog_failed_to_execute)
                            :join(dialog_click_run_and_reinstall)
                            :join(dialog_command)
                            :load_data(data_command_win)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local no_python_dependencies_unix = function()
    local dialog
    local result
    while not check_cmd_c(command_f_check_python_dependencies_unix(config)) do
        if not dialog then
            dialog = adialog.new({ width = 50 })
                            :join(dialog_failed_to_execute)
                            :join(dialog_click_run_and_reinstall)
                            :join(dialog_command)
                            :load_data(data_command_python_unix)
        end
        result = display_runner(dialog, buttons_run_cancel)
        if result:isErr() then return result end
    end
    return result or ok("Already satisfied")
end

local no_vs_dependencies_unix = function()
    if not check_cmd_c(command_f_check_vs_dependencies_unix(config)) then
        adisplay(adialog.new({ width = 50 })
                        :join(dialog_failed_to_execute)
                        :join(dialog_follow_install)
                        :join(dialog_command)
                        :load_data(data_command_vs_unix),
                 buttons_cancel):resolve()
        return err()
    end
    return ok("Already satisfied")
end

local out_of_date_dependencies_win = function()
    local dialog = adialog.new({ width = 50 })
                          :join(dialog_out_of_date)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_update_win)
    return display_runner_with_ignore(dialog, buttons_run_command_ignore_cancel)
end

local out_of_date_python_dependencies_unix = function()
    local dialog = adialog.new({ width = 50 })
                          :join(dialog_out_of_date)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_python_update_unix)
    return display_runner_with_ignore(dialog, buttons_run_command_ignore_cancel)
end

local update_dependencies_win = function()
    local dialog = adialog.new({ width = 50 })
                          :join(dialog_click_run)
                          :join(dialog_command)
                          :load_data(data_command_update_win)
    return display_runner_with_ignore(dialog, buttons_run_cancel)
end

local update_python_dependencies_unix = function()
    local dialog = adialog.new({ width = 50 })
                          :join(dialog_click_run)
                          :join(dialog_command)
                          :load_data(data_command_python_update_unix)
    return display_runner_with_ignore(dialog, buttons_run_cancel)
end

local update_precheck_vs_dependencies_unix = function()
    return check_cmd_c(command_f_check_vs_dependencies_unix(config))
end

local update_vs_dependencies_unix = function()
    if not check_cmd_c(command_f_check_vs_dependencies_unix(config)) then
        adisplay(adialog.new({ width = 50 })
                        :join(dialog_update_requires_vs_dependencies)
                        :join(dialog_follow_install)
                        :join(dialog_command)
                        :load_data(data_command_vs_unix),
                 buttons_cancel):resolve()
        return err()
    end
    return ok("Already satisfied")
end

local unsupported_dependencies_win = function()
    local dialog = adialog.new({ width = 50 })
                          :join(dialog_unsupported)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_update_win)
    return display_runner(dialog, buttons_run_command_cancel)
end

local unsupported_python_dependencies_unix = function()
    local dialog = adialog.new({ width = 50 })
                          :join(dialog_unsupported)
                          :join(dialog_click_run_command_and_update)
                          :join(dialog_command)
                          :load_data(data_command_python_update_unix)
    return display_runner(dialog, buttons_run_command_cancel)
end



-- main functions
local first_time_python_vsrepo_main = function()
    if not config then
        if lfs.attributes(aconfig.config_dir .. "/zah.autoclip.json", "mode") then
            config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
                :ifErr(aegisub.cancel)
                :unwrap()
        else
            config = aconfig:read_and_validate_config_if_empty_then_default_or_else_edit_and_save("zah.autoclip", validation_func)
                :ifErr(aegisub.cancel)
                :unwrap()

            if jit.os == "Windows" then
                ok():andThen(first_time_python_with_vsrepo_win)
                    :andThen(check_python_with_vs_win)
                    :andThen(check_vsrepo_win)
                    :andThen(first_time_dependencies_win)
                    :ifErr(aegisub.cancel)
            else
                ok():andThen(first_time_python_unix)
                    :andThen(check_python_with_vs_unix)
                    :andThen(first_time_python_dependencies_unix)
                    :andThen(first_time_vs_dependencies_unix)
                    :ifErr(aegisub.cancel)
end end end end

local no_dependencies_main = function()
    if jit.os == "Windows" then
        if check_cmd_c(command_f_check_dependencies_win(config)) then
            return "Already satisfied"
        else
            ok():andThen(check_python_with_vs_win)
                :andThen(check_vsrepo_win)
                :andThen(no_dependencies_win)
                :ifErr(aegisub.cancel)
        end
    else
        if check_cmd_c(command_f_check_dependencies_unix(config)) then
            return "Already satisfied"
        else
            ok():andThen(check_python_with_vs_unix)
                :andThen(no_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local out_of_date_dependencies_main = function()
    if jit.os == "Windows" then
        ok():andThen(out_of_date_dependencies_win)
            :ifErr(aegisub.cancel)
    else
        if update_precheck_vs_dependencies_unix() then
            ok():andThen(out_of_date_python_dependencies_unix)
                :andThen(update_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
        else
            ok():andThen(out_of_date_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local unsupported_dependencies_main = function()
    if jit.os == "Windows" then
        ok():andThen(unsupported_dependencies_win)
            :ifErr(aegisub.cancel)
    else
        if update_precheck_vs_dependencies_unix() then
            ok():andThen(unsupported_python_dependencies_unix)
                :andThen(update_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
        else
            ok():andThen(unsupported_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local clip_gather_main = function(ass)
    local first
    local last
    local active = aegisub.project_properties().video_position
    local active_clip = err("Not found")
    local clip = err("Not found")
    for line, s, i, n in ass:iterSel() do
        Aegi.progressCancelled()
        ass:progressLine(s, i, n)

        line.start_frame = aegisub.frame_from_ms(line.start_time)
        line.end_frame = aegisub.frame_from_ms(line.end_time)

        if not first then
            first = line.start_frame
            last = line.end_frame
        else
            first = first <= line.start_frame and first or line.start_frame
            last = last >= line.end_frame and last or line.end_frame
        end

        Line.process(ass, line)
        if type(line.data["clip"]) == "table" then
            if line.start_frame <= active and active < line.end_frame then
                if active_clip:isErr() and active_clip:unwrapErr() == "Not found" then
                    active_clip = ok(line.data["clip"])
                elseif active_clip:isOk() then
                    if not (line.data["clip"][1] == active_clip:unwrap()[1] and
                            line.data["clip"][2] == active_clip:unwrap()[2] and
                            line.data["clip"][3] == active_clip:unwrap()[3] and
                            line.data["clip"][4] == active_clip:unwrap()[4]) then
                        active_clip = err("Multiple")
            end end end
                
            if clip:isErr() and clip:unwrapErr() == "Not found" then
                clip = ok(line.data["clip"])
            elseif clip:isOk() then
                if not (line.data["clip"][1] == clip:unwrap()[1] and
                        line.data["clip"][2] == clip:unwrap()[2] and
                        line.data["clip"][3] == clip:unwrap()[3] and
                        line.data["clip"][4] == clip:unwrap()[4]) then
                    clip = err("Multiple")
    end end end end
    return first, last, active, active_clip, clip
end

local clip_set = err("Not set")
local clip_set_first
local clip_set_last
local clip_set_main = function(sub, sel, act)
    first_time_python_vsrepo_main()

    local ass = Ass(sub, sel, act)

    Aegi.progressTitle("Gathering clip information")
    local first, last, active, active_clip, clip = clip_gather_main(ass)
    local act_clip = err("Not found")
    local act_line = Line.process(ass, sub[act])
    if act_line.data["clip"] == "table" then
        act_clip = ok(act_line.data["clip"])
    end

    if active_clip:isOk() then
        if act_clip:isOk() then
            if act_clip:unwrap()[1] == active_clip:unwrap()[1] and
               act_clip:unwrap()[2] == active_clip:unwrap()[2] and
               act_clip:unwrap()[3] == active_clip:unwrap()[3] and
               act_clip:unwrap()[4] == active_clip:unwrap()[4] then
                clip = act_clip
            else
                local dialog = adialog.new({ width = 50 })
                                      :label({ label = "A rect clip is found on the active line." })
                                      :label({ label = "However, a single different rect clip is found on lines containing the frame at video seek head." })
                                      :label({ label = "Select either rect clip to set as active area for AutoClipping, or unset the rect clip that's been set previously." })
                local buttons = abuttons.new()
                                        :ok("Set Clip On The &Active Line")
                                        :extra("Set Clip On Line&s At Video Seek Head")
                                        :extra("Unset Previously Set &Clip")
                                        :cancel("Cancel")
                local b = adisplay(dialog, buttons):resolve()
                if buttons:is_ok(b) then
                    clip = act_clip
                elseif b == "Set Clip On Line&s At Video Seek Head" then
                    clip = active_clip
                elseif b == "Unset Previously Set &Clip" then
                    clip = err("Explicit unset")
                else
                    aegisub.cancel()
            end end
        else
            clip = active_clip
        end
    elseif active_clip:isErr() and active_clip:unwrapErr() == "Multiple" then
        if act_clip:isOk() then
            local dialog = adialog.new({ width = 50 })
                                  :label({ label = "A rect clip is found on the active line." })
                                  :label({ label = "However, multiple different rect clip are found on lines containing the frame at video seek head." })
                                  :label({ label = "Select either to set the rect clip as active area for AutoClipping, or to unset the rect clip that's been set previously." })
            local buttons = abuttons.new()
                                    :ok("Set Clip On The &Active Line")
                                    :extra("Unset Previously Set &Clip")
                                    :cancel("Cancel")
            local b = adisplay(dialog, buttons):resolve()
            if buttons:is_ok(b) then
                clip = act_clip
            elseif b == "Unset Previously Set &Clip" then
                clip = err("Explicit unset")
            else
                aegisub.cancel()
            end
        else
            aegisub.debug.out("[zah.autoclip] No rect clips found on the active line while multiple different rect clips are found on lines containing the frame at video seek head.\n")
            aegisub.debug.out("[zah.autoclip] Unsetting the rect clip that's been set previously.\n")
        end
    else
        if act_clip:isOk() then
            clip = act_clip
        elseif clip:isErr() and clip:unwrapErr() == "Multiple" then
            aegisub.debug.out("[zah.autoclip] No rect clips are found on the active line or on lines containing the frame at video seek head, while multiple different rect clip are found on other selected lines.\n")
            aegisub.debug.out("[zah.autoclip] Unsetting previously set rect clip.\n")
    end end
    if clip:isOk() then
        clip_set = clip
        clip_set_first = first
        clip_set_last = last
    else
        clip_set = err("Not set")
        clip_set_first = nil
        clip_set_last = nil
end end

local autoclip_main = function(sub, sel, act)
    first_time_python_vsrepo_main()

    local ass = Ass(sub, sel, act)

    local video_file = aegisub.project_properties().video_file
    if not video_file or video_file == "" then
        aegisub.debug.out("[zah.autoclip] AutoClip requires a video to be loaded for clipping.\n")
        aegisub.cancel()
    end

    -- Grab frame and clip information and check frame continuity across subtitle lines
    Aegi.progressTitle("Gathering frame information")
    local first, last, active, active_clip, clip = clip_gather_main(ass)

    -- Make sure active is inside [first:last]
    if not (first <= active and active < last) then
        aegisub.debug.out("[zah.autoclip] Video seek head outside the range of selected lines.\n")
        aegisub.debug.out("[zah.autoclip] The selected lines start at frame " .. tostring(first) .. " and end at frame " .. tostring(last - 1) .. " but video seek head is at frame " .. tostring(active) .. ".\n")
        aegisub.debug.out("[zah.autoclip] AutoClip uses video seek head as the reference frame and also by default takes the clipping area from lines containing video seek head.\n")
        aegisub.cancel()
    end
    
    local clip_set_available
    if clip_set:isErr() and clip_set:unwrapErr() == "Not set" then
        clip_set_available = err("Not available")
    elseif last > clip_set_first and first < clip_set_last then
        clip_set_available = clip_set
    elseif last < clip_set_first - 240 or first > clip_set_last + 240 then
        clip_set_available = err("Not available")
    else
        clip_set_available = err("Near range")
    end

    -- Set clip
    if active_clip:isOk() then
        if clip_set_available:isOk() then
            clip = clip_set
        elseif clip_set_available:isErr() and clip_set_available:unwrapErr() == "Near range" then
            local dialog = adialog.new({ width = 50 })
                                  :label({ label = "A rect clip is found on lines containing the frame at video seek head." })
                                  :label({ label = "For information, selected lines start at frame " .. tostring(first) .. " and end at frame " .. tostring(last - 1) .. "." })
                                  :label({ label = "However, a rect clip has previously been set for range from frame " .. tostring(clip_set_first) .. " to frame " .. tostring(clip_set_last - 1) .. "." })
                                  :label({ label = "Select either to use the rect clip in the lines containing the frame at video seek head, or to use the rect clip that's been set previously." })
            local buttons = abuttons.new()
                                    :ok("Use Clip On Line&s At Video Seek Head")
                                    :extra("Use Previously Set &Clip")
                                    :cancel("Cancel")
            local b = adisplay(dialog, buttons):resolve()
            if buttons:is_ok(b) then
                clip = active_clip
            elseif b == "Use Previously Set &Clip" then
                clip = clip_set
            else
                aegisub.cancel()
            end
        else
            clip = active_clip
        end
    elseif active_clip:isErr() and active_clip:unwrapErr() == "Multiple" then
        if clip_set_available:isOk() then
            clip = clip_set
        elseif clip_set_available:isErr() and clip_set_available:unwrapErr() == "Near range" then
            aegisub.debug.out("[zah.autoclip] Multiple different rect clips found on lines containing the frame at video seek head.\n")
            aegisub.debug.out("[zah.autoclip] For information, selected lines start at frame " .. tostring(first) .. " and end at frame " .. tostring(last - 1) .. ".\n")
            aegisub.debug.out("[zah.autoclip] However, a rect clip has previously been set for range from frame " .. tostring(clip_set_first) .. " to frame " .. tostring(clip_set_last - 1) .. ".\n")
            aegisub.debug.out("[zah.autoclip] AutoClip will proceed with the rect clip that's previously been set.\n")
            aegisub.debug.out("[zah.autoclip] To use the rect clip on lines containing the frame at video seek head, make sure there's only one unique rect clip on lines containing the frame at video seek head.\n")
            clip = clip_set
        else
            aegisub.debug.out("[zah.autoclip] Multiple different rect clips found on lines containing the frame at video seek head.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it will be active.\n")
            aegisub.debug.out("[zah.autoclip] AutoClip by default takes this clip from lines containing the frame at video seek head. AutoClip expects one unique rect clip on the lines.\n")
            aegisub.debug.out("[zah.autoclip] To run AutoClip on top of existing clips and merge the incoming clips from AutoClipping with existing clips, set the active area using „AutoClip > Set Active Area“.\n")
            aegisub.cancel()
        end
    else
        if clip_set_available:isOk() then
            clip = clip_set
        elseif clip_set_available:isErr() and clip_set_available:unwrapErr() == "Near range" then
            if clip:isOk() then
                local dialog = adialog.new({ width = 50 })
                                      :label({ label = "A rect clip is found on selected lines." })
                                      :label({ label = "For information, selected lines start at frame " .. tostring(first) .. " and end at frame " .. tostring(last - 1) .. "." })
                                      :label({ label = "However, a rect clip has previously been set for range from frame " .. tostring(clip_set_first) .. " to frame " .. tostring(clip_set_last - 1) .. "." })
                                      :label({ label = "Select either to use the rect clip in the selected lines, or to use the rect clip that's been set previously." })
                local buttons = abuttons.new()
                                        :ok("Use Clip In &Selected Lines")
                                        :extra("Use Previously Set &Clip")
                                        :cancel("Cancel")
                local b = adisplay(dialog, buttons):resolve()
                if b == "Use Previously Set &Clip" then
                    clip = clip_set
                elseif buttons:is_cancel(b) then
                    aegisub.cancel()
                end
            elseif clip:isErr() and clip:unwrapErr() == "Multiple" then
                aegisub.debug.out("[zah.autoclip] No rect clip found in lines containing the frame at video seek head, and there are multiple different rect clips found on other selected line.\n")
                aegisub.debug.out("[zah.autoclip] For information, selected lines start at frame " .. tostring(first) .. " and end at frame " .. tostring(last - 1) .. ".\n")
                aegisub.debug.out("[zah.autoclip] However, a rect clip has previously been set for range from frame " .. tostring(clip_set_first) .. " to frame " .. tostring(clip_set_last - 1) .. ".\n")
                aegisub.debug.out("[zah.autoclip] AutoClip will proceed with the rect clip that's previously been set.\n")
                aegisub.debug.out("[zah.autoclip] To use the rect clip in the selected lines, make sure there's only one unique rect clip in the selected lines.\n")
                clip = clip_set
            else
                clip = clip_set
            end
        else
            if clip:isErr() and clip:unwrapErr() == "Multiple" then
                aegisub.debug.out("[zah.autoclip] No rect clip found in lines containing the frame at video seek head, and there are multiple different rect clips found on other selected line.\n")
                aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it will be active.\n")
                aegisub.debug.out("[zah.autoclip] AutoClip first checks if such clip exists on lines containing the frame at video seek head, otherwise it fallbacks and checks for clips in every lines in the selection.\n")
                aegisub.cancel()
            elseif clip:isErr() then
                aegisub.debug.out("[zah.autoclip] No rect clips found in selected lines.\n")
                aegisub.debug.out("[zah.autoclip] AutoClip requires a rect clip to be set for the area it will be active.\n")
                aegisub.debug.out("[zah.autoclip] AutoClip first checks if such clip exists on lines containing the frame at video seek head, otherwise it fallbacks and checks for clips in every lines in the selection.\n")
                aegisub.cancel()
    end end end
    clip = clip:unwrap()

    -- Check frame continuity
    local frames = {}
    for line, s, i, n in ass:iterSel() do
        line.start_frame = aegisub.frame_from_ms(line.start_time)
        line.end_frame = aegisub.frame_from_ms(line.end_time)
        
        for j = line.start_frame, line.end_frame - 1 do
            if not frames[j] then
                frames[j] = 1
            else
                frames[j] = frames[j] + 1
    end end end

    local head
    for i = first, last - 1 do
        if not frames[i] then
            for j = i, last - 1 do
                if frames[j] then
                    aegisub.debug.out("[zah.autoclip] Selected lines aren't time continuous.\n")
                    aegisub.debug.out("[zah.autoclip] The earliest frame in the selected line is frame " .. tostring(first) .. ", and the latest frame is frame " .. tostring(last - 1) .. ".\n")
                    if i ~= j - 1 then
                        aegisub.debug.out("[zah.autoclip] There is a gap from frame " .. tostring(i) .. " to frame " .. tostring(j - 1) .. " that no lines in the selection covers.\n")
                    else
                        aegisub.debug.out("[zah.autoclip] There is a gap at frame " .. tostring(i) .. " that no lines in the selection covers.\n")
                    end
                    aegisub.debug.out("[zah.autoclip] AutoClip will continue but please manually confirm the result after run.\n")
            end end
        -- elseif not config["disable_layer_mismatch"] then
            -- if head == nil then
            --     head = frames[i]
            -- elseif head ~= false and head ~= frames[i] then
            --     aegisub.debug.out("[zah.autoclip] Number of layers mismatches.\n")
            --     aegisub.debug.out("[zah.autoclip] There are " .. tostring(head) .. " layers on frame " .. tostring(i - 1) .. ", but there are " .. tostring(frames[i]) .. " layers on frame " .. tostring(i) .. ".\n")
            --     aegisub.debug.out("[zah.autoclip] If this is intentional and you want to silence this warning, you can disable it in „AutoClip > Configure AutoClip“.\n")
            --     aegisub.debug.out("[zah.autoclip] Continuing.\n")
            --     head = false
    end end -- end

    -- Run commands
    ::run_again::

    Aegi.progressCancelled()
    Aegi.progressTitle("Waiting for Python to complete")
    local output_file
    local command -- ↓
    local log
    local status
    local terminate
    local code
    local f
    local msg
    local output
    
    output_file = aegisub.decode_path("?temp/zah.autoclip." .. string.sub(tostring(math.random(10000000, 99999999)), 2) .. ".json")
    if jit.os == "Windows" then
        command = config["venv_activate"] ~= "" and p(config["venv_activate"]) .. "\n" or ""
    else
        command = config["venv_activate"] ~= "" and "source " .. p(config["venv_activate"]) .. "\n" or ""
    end
    command = command ..
              p(config["python"]) .. " -m ass_autoclip" ..
                                     " --input " .. p(video_file) ..
                                     " --output " .. p(output_file) ..
                       string.format(" --clip '%f %f %f %f'", clip[1], clip[2], clip[3], clip[4]) ..
                                     " --first " .. first ..
                                     " --last " .. last ..
                                     " --active " .. active ..
                                     " --supported-version " .. ((not disable_version_notify_until_next_time and not config["disable_version_notify"]) and
                                                                 script_version or
                                                                 last_supported_script_version)
    log, status, terminate, code = run_cmd_c(command)

    Aegi.progressCancelled()
    Aegi.progressTitle("Parsing output from Python")
    if not status then
        if no_dependencies_main() ~= "Already satisfied" then
            goto run_again
        end

        if terminate == "exit" then
            aegisub.debug.out("[zah.autoclip] Python exits with code " .. tostring(code) .. ":\n")
        else
            aegisub.debug.out("[zah.autoclip] Python terminated with signal " .. tostring(code) .. ":\n")
        end
        aegisub.debug.out("[zah.autoclip] " .. c(command) .. "\n")
        aegisub.debug.out(log)
        aegisub.debug.out("[zah.autoclip] Attempting to continue.\n")
    end

    -- Open output file
    f, msg = io.open(output_file, "r")
    if not f then
        aegisub.debug.out("[zah.autoclip] Failed to open output file:\n")
        aegisub.debug.out("[zah.autoclip] " .. msg .. "\n")
        aegisub.cancel()
    end

    output = json:decode3(f:read("*a"))
        :ifErr(function(error)
            aegisub.debug.out("[zah.autoclip] Failed to parse output file:\n")
            aegisub.debug.out("[zah.autoclip] " .. error .. "\n")
            aegisub.cancel() end)
        :unwrap()
    f:close()

    if type(output["clip"]) ~= "table" then
        if output["current_version"] then
            if V(output["current_version"]) < V(last_supported_script_version) then
                unsupported_dependencies_main()
            elseif V(output["current_version"]) < V(script_version) then
                out_of_date_dependencies_main()
            else
                error("Unexpected error")
            end
            goto run_again
        else
            aegisub.debug.out("[zah.autoclip] Failed to parse output file:\n")
            aegisub.debug.out("[zah.autoclip] Malformatted or missing key \"clip\".\n")
            aegisub.cancel()
    end end

    frames = output["clip"]
    if frames[last - first] == nil then
        aegisub.debug.out("[zah.autoclip] Output file contains less frames than expected.\n")
        aegisub.debug.out("[zah.autoclip] AutoClip will continue but please manually confirm the result after run.\n")
    elseif frames[last - first + 1] ~= nil then
        aegisub.debug.out("[zah.autoclip] Output file contains more frames than expected.\n")
        aegisub.debug.out("[zah.autoclip] AutoClip will continue but please manually confirm the result after run.\n")
    end
    for i, v in ipairs(frames) do
        frames[i] = Path(v)
    end

    -- Apply the frames table to subtitle
    Aegi.progressTitle("Writing clips to lines")
    local layer_operations = {}
    local frame = aegisub.get_frame(active)
    for line, s, i, n in ass:iterSel() do
        Aegi.progressCancelled()
        ass:progressLine(s, i, n)

        ass:removeLine(line, s)

        -- Internal ILL value; May break
        line.isShape = false
        Line.process(ass, line)
        Line.callBackFBF(ass, line, function(line_, i_, end_frame)
            if frames[aegisub.frame_from_ms(line_.start_time) - first + 1] then
                local clippy
                if line_.data["clip"] and
                   type(line_.data["clip"]) == "table" and
                   line_.data["clip"][1] == clip[1] and
                   line_.data["clip"][2] == clip[2] and
                   line_.data["clip"][3] == clip[3] and
                   line_.data["clip"][4] == clip[4] then
                elseif line_.data["clip"] then
                    if line_.data["isIclip"] then
                        clippy = Path(line_.data["clip"])
                    else
                        local clipping_clippy = Path(line_.data["clip"])
                        local bounding_box = clipping_clippy:boundingBox()
                        clippy = Path({ math.min(0, bounding_box.l), math.min(0, bounding_box.t), math.max(frame:width(), bounding_box.r), math.max(frame:height(), bounding_box.b) })
                        clippy:difference(clipping_clippy)
                end end

                if clippy then
                    if not layer_operations[line_.layer] then
                        local dialog = adialog.new({ width = 50 })
                                              :label({ label = "A clip is found on lines with layer " .. line_.layer .. "." })
                                              :label({ label = "Select either to replace existing clips with incoming clips, or to merge the existing clips with incoming clips." })
                        local buttons = abuttons.extra("&Replace Existing Clip With AutoClip")
                                                :ok("Apply Auto&Clip In Additional To Existing Clipping (iclip OR)")
                                                :extra("Apply AutoClip To Existing Clip (iclip Su&btract)")
                                                :extra("Apply Exi&sting Clip To AutoClip (iclip Subtract)")
                                                :extra("Apply iclip &AND")
                                                :extra("Apply iclip &XOR")
                                                :extra("Keep &Existing Clip")
                                                :extra("Cancel AutoClip")
                        local b = adisplay(dialog, buttons):resolve()
                        if b == "Cancel AutoClip" then
                            aegisub.cancel()
                        end
                        layer_operations[line_.layer] = b
                    end
                    if layer_operations[line_.layer] == "Keep &Existing Clip" then
                    else
                        line_.text.tagsBlocks[1]:remove("clip", "iclip")

                        if layer_operations[line_.layer] == "&Replace Existing Clip With AutoClip" then
                            line_.text.tagsBlocks[1]:insert("\\iclip(" .. frames[aegisub.frame_from_ms(line_.start_time) - first + 1]:export() .. ")")
                        elseif layer_operations[line_.layer] == "Apply Auto&Clip In Additional To Existing Clipping (iclip OR)" then
                            local clip = clippy
                            clip:unite(frames[aegisub.frame_from_ms(line_.start_time) - first + 1])
                            line_.text.tagsBlocks[1]:insert("\\iclip(" .. clip:export() .. ")")
                        elseif layer_operations[line_.layer] == "Apply AutoClip To Existing Clip (iclip Su&btract)" then
                            local clip = clippy
                            clip:difference(frames[aegisub.frame_from_ms(line_.start_time) - first + 1])
                            line_.text.tagsBlocks[1]:insert("\\iclip(" .. clip:export() .. ")")
                        elseif layer_operations[line_.layer] == "Apply Exi&sting Clip To AutoClip (iclip Subtract)" then
                            local clip = Table.copy(frames[aegisub.frame_from_ms(line_.start_time) - first + 1])
                            clip:difference(clippy)
                            line_.text.tagsBlocks[1]:insert("\\iclip(" .. clip:export() .. ")")
                        elseif layer_operations[line_.layer] == "Apply iclip &AND" then
                            local clip = clippy
                            clip:intersect(frames[aegisub.frame_from_ms(line_.start_time) - first + 1])
                            line_.text.tagsBlocks[1]:insert("\\iclip(" .. clip:export() .. ")")
                        elseif layer_operations[line_.layer] == "Apply iclip &XOR" then
                            local clip = clippy
                            clip:exclude(frames[aegisub.frame_from_ms(line_.start_time) - first + 1])
                            line_.text.tagsBlocks[1]:insert("\\iclip(" .. clip:export() .. ")")
                    end end
                else
                    if line_.data["clip"] then
                        line_.text.tagsBlocks[1]:remove("clip", "iclip")
                    end

                    line_.text.tagsBlocks[1]:insert("\\iclip(" .. frames[aegisub.frame_from_ms(line_.start_time) - first + 1]:export() .. ")")
            end end
            ass:insertLine(line_, s) end)
    end

    return ass:getNewSelection()
end

local update_dependencies_main = function()
    first_time_python_vsrepo_main()

    if jit.os == "Windows" then
        ok():andThen(update_dependencies_win)
            :ifErr(aegisub.cancel)
    else
        if update_precheck_vs_dependencies_unix() then
            ok():andThen(update_python_dependencies_unix)
                :andThen(update_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
        else
            ok():andThen(update_python_dependencies_unix)
                :andThen(no_vs_dependencies_unix)
                :ifErr(aegisub.cancel)
end end end

local edit_config_main = function()
    first_time_python_vsrepo_main()

    if jit.os == "Windows" then
        ok():andThen(edit_config_win)
            :ifErr(aegisub.cancel)
    else
        ok():andThen(edit_config_unix)
            :ifErr(aegisub.cancel)
end end


DepCtrl:registerMacros({
    { "AutoClip", script_description, autoclip_main },
    { "Set or Unset Active Area", "Set active area for AutoClipping. This is only needed in the case where there would be existing clips on the lines to be merged with the incoming clips from AutoClipping", clip_set_main},
    { "Update Dependencies", "Update AutoClip dependencies", update_dependencies_main },
    { "Configure AutoClip", "Configure AutoClip", edit_config_main }
})
