local os = require("os")

--- @protected
--- @return "Windows"|"MacOS"|"Linux"|"Unknown"
local function _osname() return "Unknown" end

if jit and jit.os then
    _osname = function()
        return jit.os
    end
else
    local binaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
    if binaryFormat == "dll" then
        _osname = function()
            return "Windows"
        end
    elseif binaryFormat == "so" then
        _osname = function()
            return "Linux"
        end
    elseif binaryFormat == "dylib" then
        _osname = function()
            return "MacOS"
        end
    end
    binaryFormat = nil
end
os.name = _osname

local settings = {
    EXECUTABLE_NAME = "Funkin",
    EXPORT_DIR = "../../export",

    FOLDERS_TO_COPY = {"assets", "mods"},
    FILES_TO_INCLUDE = {"thirdparty", "src", "conf.lua", "main.lua", "flags.lua", "project.lua"},
    FILES_TO_EXCLUDE = {},

    EXTERNAL_FILES = {
        ["../../alsoft.conf"] = "alsoft.conf"
    },

    --- The file (`love_path.lua`) is formatted like this:
    --- 
    --- ```lua
    --- return {
    ---     WINDOWS = "C:/Program Files/LOVE",
    ---     LINUX = "love.AppImage"
    --- }
    --- ```
    --- 
    --- It's git ignored so you can make your own if you need to
    --- 
    --- Linux love path generally doesn't need to be changed, so you can
    --- omit it from the lua file if you want
    LOVE_PATH = {
        WINDOWS = "C:/Program Files/LOVE",
        LINUX = "love.AppImage"
    }
}
local success, result = pcall(require, "love_path")
if success then
    for key, value in pairs(result) do
        settings.LOVE_PATH[key] = value
    end
else
    print("love_path.lua not found in commands/export, using default data instead!")
end
local lovevlc = "../../thirdparty/lovevlc"
if os.name() == "Windows" then
    settings.EXTERNAL_FILES[lovevlc .. "/plugins/Windows"] = "plugins"
    settings.EXTERNAL_FILES[lovevlc .. "/lib/win64/libvlc.dll"] = "libvlc.dll"
    settings.EXTERNAL_FILES[lovevlc .. "/lib/win64/libvlccore.dll"] = "libvlccore.dll"
    settings.EXTERNAL_FILES[lovevlc .. "/lib/win64/libvlc_wrapper.dll"] = "libvlc_wrapper.dll"

elseif os.name() == "Linux" then
    settings.EXTERNAL_FILES[lovevlc .. "/lib/linux/libvlc_wrapper.so"] = "libvlc_wrapper.so"
end
return settings