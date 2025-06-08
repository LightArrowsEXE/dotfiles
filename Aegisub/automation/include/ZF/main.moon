versionRecord = "2.3.0"
haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local karaskel, yutils, depctrl
if haveDepCtrl
    depctrl = DependencyControl {
        name: "ZF main"
        version: versionRecord
        description: "A library used in zeref's Aegisub scripts."
        author: "Zeref"
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        moduleName: "ZF.main"
        feed: "https://raw.githubusercontent.com/TypesettingTools/zeref-Aegisub-Scripts/main/DependencyControl.json"
        {
            { "karaskel" }
            { "Yutils" }
        }
    }
    karaskel, yutils, _ = depctrl\requireModules!
else
    karaskel = require "karaskel"
    yutils  = require "Yutils"

-- globalizes Yutils
export Yutils = yutils

-- loads a library error that was not found
export libError = (name) ->
    error table.concat {
        "\n--> #{name} was not found <--\n\n"
        "⬇ To fix this error, download the file via the link below ⬇\n"
        "https://github.com/TypesettingTools/zeref-Aegisub-Scripts/releases/"
    }

-- checks if the version gives class matches the current one
checkVersion = (version, cls, module_name) ->
    assert version == cls.version, "\n\nVersion incompatible in: \"#{module_name\gsub "%.", "\\"}\"\n\nExpected version: \"#{version}\"\nCurrent version: \"#{cls.version}\""

-- returns module not found error
moduleError = (module_name) ->
    error "\n\nThe module \"#{module_name}\" was not found, please check your files and try again"

-- returns the class error not found in the module
classError = (module_name, export_name) ->
    error "\n\nThe class \"#{export_name}\" was not found in module \"#{module_name\gsub "%.", "\\"}\", please check your files and try again"

-- defines the files that will be exported
files = {
    -- 2D
    clipper: {export_name: "CLIPPER", module_name: "ZF.main.2D.clipper",     version: "1.0.3"}
    path:    {export_name: "PATH",    module_name: "ZF.main.2D.path",        version: "1.1.0"}
    paths:   {export_name: "PATHS",   module_name: "ZF.main.2D.paths",       version: "1.1.3"}
    point:   {export_name: "POINT",   module_name: "ZF.main.2D.point",       version: "1.0.0"}
    segment: {export_name: "SEGMENT", module_name: "ZF.main.2D.segment",     version: "1.0.1"}
    shape:   {export_name: "SHAPE",   module_name: "ZF.main.2D.shape",       version: "1.1.4"}
    -- ass tags
    layer:   {export_name: "LAYER",   module_name: "ZF.main.ass.tags.layer", version: "1.0.0"}
    tags:    {export_name: "TAGS",    module_name: "ZF.main.ass.tags.tags",  version: "1.0.0"}
    -- ass
    dialog:  {export_name: "DIALOG",  module_name: "ZF.main.ass.dialog",     version: "1.0.0"}
    fbf:     {export_name: "FBF",     module_name: "ZF.main.ass.fbf",        version: "1.1.4"}
    font:    {export_name: "FONT",    module_name: "ZF.main.ass.font",       version: "1.0.0"}
    line:    {export_name: "LINE",    module_name: "ZF.main.ass.line",       version: "1.4.0"}
    -- img
    img:     {export_name: "IMAGE",   module_name: "ZF.main.img.img",        version: "1.2.0"}
    potrace: {export_name: "POTRACE", module_name: "ZF.main.img.potrace",    version: "1.2.0"}
    -- util
    config:  {export_name: "CONFIG",  module_name: "ZF.main.util.config",    version: "1.0.2"}
    math:    {export_name: "MATH",    module_name: "ZF.main.util.math",      version: "1.1.1"}
    util:    {export_name: "UTIL",    module_name: "ZF.main.util.util",      version: "1.3.1"}
    table:   {export_name: "TABLE",   module_name: "ZF.main.util.table",     version: "1.0.0"}
}

exports = {version: versionRecord}
for expt_name, expt_value in pairs files
    {:export_name, :module_name, :version} = expt_value
    -- gets the module
    has_module, module = pcall require, module_name
    -- if the module was not loaded, returns an error
    unless has_module
        moduleError module_name
    module = require(module_name)[export_name]
    -- if the class was not loaded, returns an error
    unless module
        classError module_name, export_name
    -- does the check
    checkVersion version, module, module_name
    -- adds the module for export
    exports[expt_name] = module

if haveDepCtrl
    return depctrl\register exports
else
    return exports
