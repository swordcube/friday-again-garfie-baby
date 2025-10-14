-- [ basic initialization ] --

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

table.contains = function(t, o)
    local len = #t
    for i = 1, len do
        if t[i] == o then
            return true
        end
    end
    return false
end

function string.replace(self, from, to)
    local s, _ = self:gsub(from:gsub('([%^%$%(%)%%%.%[%]%*%+%-%q?])', '%%%1'), to)
    return s
end

-- [ discard on unsupported oses ]

local SUPPORTED_OSES = {"Windows", "Linux"}

if not table.contains(SUPPORTED_OSES, os.name()) then
    print("You are running an unsupported OS for exporting: " .. os.name() .. "\nSupported OSes are: " .. table.concat(SUPPORTED_OSES, ", ") .. "\n\nThis is most likely because I am unable to test said OS!\nReport an issue on GitHub if you'd like to see it supported!\n----------------------------------")
    os.exit(1)
end

-- [ the actual script ] --

package.path = '../export/?.lua;' .. package.path
require("tools.stringtools")

local EXPORT_SETTINGS = require("export_settings")

local EXPORT_DIR = EXPORT_SETTINGS.EXPORT_DIR

if os.name() == "Windows" then
    EXPORT_DIR = EXPORT_DIR .. "/windows"
else
    EXPORT_DIR = EXPORT_DIR .. "/linux"
end

local EXPORT_TYPE = "release"
local CLEAN_BUILD = false

if table.contains(arg, "-debug") or table.contains(arg, "--debug") then
    EXPORT_TYPE = "debug"
end
if table.contains(arg, "-clean") or table.contains(arg, "--clean") then
    CLEAN_BUILD = true
end

if CLEAN_BUILD then
    print("Clearing previous build...\n----------------------------------")
    if os.name() == "Windows" then
        os.execute("rd /S /Q \"" .. EXPORT_DIR .. "\" > nul 2>&1")
        os.execute("mkdir \"" .. EXPORT_DIR .. "\" > nul 2>&1")
    else
        os.execute("rm -rf " .. EXPORT_DIR)
        os.execute("mkdir -p " .. EXPORT_DIR .. "")
    end
end

print("Copying assets...\n----------------------------------")

local FOLDERS_TO_COPY = EXPORT_SETTINGS.FOLDERS_TO_COPY

local FILES_TO_INCLUDE = EXPORT_SETTINGS.FILES_TO_INCLUDE
local FILES_TO_EXCLUDE = EXPORT_SETTINGS.FILES_TO_EXCLUDE

local EXTERNAL_FILES = EXPORT_SETTINGS.EXTERNAL_FILES

for _, folder in ipairs(FOLDERS_TO_COPY) do
    if os.name() == "Windows" then
        os.execute("mkdir \"" .. EXPORT_DIR .. "/" .. folder .. "\" > nul 2>&1")
        os.execute("Xcopy ..\\..\\" .. folder .. " \"" .. EXPORT_DIR .. "/" .. folder .. "\" /E /H /C /I /Y > nul 2>&1")
    else
        os.execute("mkdir -p " .. EXPORT_DIR .. "/" .. folder)
        os.execute("cp -r ../../" .. folder .. " " .. EXPORT_DIR)
    end
end

print("Exporting a " .. EXPORT_TYPE .. " build...\n----------------------------------")

local LOVE_PATH = EXPORT_SETTINGS.LOVE_PATH
local EXECUTABLE_NAME = EXPORT_SETTINGS.EXECUTABLE_NAME

local function isdir(sPath)
    local ext = sPath:match("^.+(%..+)$")
    return not ext or ext == ""
end


local chosenLovePath = LOVE_PATH[os.name():upper()]
if os.name() == "Windows" then
    EXECUTABLE_NAME = EXECUTABLE_NAME .. ".exe"

    -- package the game into a .love file
    local zipCmd = "7za a game.zip" -- use 7zip because the normal zip command generates ill-formed entries??
    for _, folder in ipairs(FILES_TO_INCLUDE) do
        zipCmd = zipCmd .. " ../../" .. folder
    end
    for _, folder in ipairs(FILES_TO_EXCLUDE) do
        zipCmd = zipCmd .. " -xr!../../" .. folder
    end
    local success = os.execute(zipCmd .. " > nul 2>&1")
    if not success then
        print("An error occured while zipping the game, cannot continue!\n----------------------------------")
        os.exit(1)
    end
    os.rename("game.zip", "game.love")

    -- copy every love2d dll we possibly can to the export folder
    -- this sucks
    --                            too bad.
    os.execute("copy \"" .. chosenLovePath .. "\\love.dll\" \"" .. EXPORT_DIR .. "/love.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\lua51.dll\" \"" .. EXPORT_DIR .. "/lua51.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\SDL3.dll\" \"" .. EXPORT_DIR .. "/SDL3.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\OpenAL32.dll\" \"" .. EXPORT_DIR .. "/OpenAL32.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\mpg123.dll\" \"" .. EXPORT_DIR .. "/mpg123.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcp120.dll\" \"" .. EXPORT_DIR .. "/msvcp120.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcp140.dll\" \"" .. EXPORT_DIR .. "/msvcp140.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcp140_1.dll\" \"" .. EXPORT_DIR .. "/msvcp140_1.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcp140_2.dll\" \"" .. EXPORT_DIR .. "/msvcp140_2.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcp140_atomic_wait.dll\" \"" .. EXPORT_DIR .. "/msvcp140_atomic_wait.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcp140_codecvt_ids.dll\" \"" .. EXPORT_DIR .. "/msvcp140_codecvt_ids.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcr120.dll\" \"" .. EXPORT_DIR .. "/msvcr120.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\msvcr140.dll\" \"" .. EXPORT_DIR .. "/msvcr140.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\vcruntime140.dll\" \"" .. EXPORT_DIR .. "/vcruntime140.dll\" > nul 2>&1")
    os.execute("copy \"" .. chosenLovePath .. "\\vcruntime140_1.dll\" \"" .. EXPORT_DIR .. "/vcruntime140_1.dll\" > nul 2>&1")

    -- create temporary executable & copy icon to export dir
    local exe = EXPORT_TYPE == "debug" and "lovec" or "love"
    os.execute("copy /b \"" .. chosenLovePath .. "\\" .. exe .. ".exe\" TEMPORARY_EXECUTABLE.exe > nul 2>&1")
    os.execute("copy ..\\..\\icon.ico \"" .. EXPORT_DIR .. "/icon.ico\" > nul 2>&1")
    
    -- set icon and version info in temp executable
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-icon \"" .. EXPORT_DIR .. "/icon.ico\"")
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-file-version 1.0.0")
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-product-version 1.0.0")
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-version-string \"ProductName\" \"funkin.lua\"")
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-version-string \"CompanyName\" \"swordcube\"")
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-version-string \"LegalCopyright\" \"2024-2024 swordcube\"")
    os.execute("rcedit.exe TEMPORARY_EXECUTABLE.exe --set-version-string \"FileDescription\" \"funkin.lua\"")
    
    -- create the new game executable by merging the temp executable with the .love file
    os.execute("copy /b TEMPORARY_EXECUTABLE.exe + game.love \"" .. EXPORT_DIR .. "/" .. EXECUTABLE_NAME .. "\" > nul 2>&1 2>&1")

    -- remove temporary junk
    os.remove("game.love")
    os.remove("TEMPORARY_EXECUTABLE.exe")

    -- copy external files to export directory
    for raw, save in pairs(EXTERNAL_FILES) do
        local folderPath = EXPORT_DIR:gsub("/", "\\") .. "\\" .. save:gsub("/", "\\")
        folderPath = folderPath:sub(1, folderPath:lastIndexOf("\\"))
        os.execute("mkdir \"" .. folderPath .. "\" > nul 2>&1 2>&1")

        local letter = isdir(raw:gsub("/", "\\")) and "d" or "f"
        os.execute("echo " .. letter .. " | Xcopy \"" .. raw:gsub("/", "\\") .. "\"" .. " \"" .. EXPORT_DIR:gsub("/", "\\") .. "\\" .. save:gsub("/", "\\") .. "\" /E /H /C /I /Y > nul 2>&1")
    end
    -- copy discord rpc dll file to export directory
    -- os.execute("copy \"..\\..\\libs\\windows\\discord-rpc.dll\"" .. " \"" .. EXPORT_DIR .. "/discord-rpc.dll\"")
else
    -- package the game into a .love file
    local zipCmd = "7za a game.zip" -- use 7zip because the normal zip command generates ill-formed entries??
    for _, folder in ipairs(FILES_TO_INCLUDE) do
        zipCmd = zipCmd .. " ../../" .. folder
    end
    for _, folder in ipairs(FILES_TO_EXCLUDE) do
        zipCmd = zipCmd .. " -x!../../" .. folder
    end
    local success = os.execute(zipCmd .. " > /dev/null")
    if not success then
        print("An error occured while zipping the game, cannot continue!\nDo you have the \"7zip\" package installed?\n----------------------------------")
        os.exit(1)
    end
    os.rename("game.zip", "game.love")
    
    -- extract the love appimage
    os.execute("./" .. chosenLovePath .. " --appimage-extract > /dev/null")

    -- create the new game executable by merging the temp executable with the .love file
    -- this is similar to the windows method seen above
    os.execute("cat squashfs-root/bin/love game.love > squashfs-root/bin/TEMPORARY_EXECUTABLE")

    -- make sure the executable is,,,, actually executable
    os.execute("chmod +x squashfs-root/bin/TEMPORARY_EXECUTABLE")

    -- replace the old love executable with our new one
    os.remove("squashfs-root/bin/love")
    os.rename("squashfs-root/bin/TEMPORARY_EXECUTABLE", "squashfs-root/bin/love")

    -- change the desktop file, for silly appimage stuff
    local desktopFile = io.open("squashfs-root/love.desktop", "r")

    local desktopContents = desktopFile:read("*a"):gsub("\r", "")
    desktopContents = string.replace(desktopContents, "Icon=love", "Icon=CometGameIcon")
    desktopContents = string.replace(desktopContents, "Name=LÖVE", "Name=friday again garfie baby")
    desktopContents = string.replace(desktopContents, "Comment=The unquestionably awesome 2D game engine", "Comment=A fanmade modding framework for Friday Night Funkin' made in LÖVE")
    desktopContents = string.replace(desktopContents, "MimeType=application/x-love-game;\n", "")
    desktopFile:close()
    
    desktopFile = io.open("squashfs-root/love.desktop", "w")
    desktopFile:write(desktopContents)
    desktopFile:close()

    -- replace the old icon with our own
    os.execute("cp -r ../../art/icons/64x.png" .. " squashfs-root/CometGameIcon.png")

    -- package the game back into an appimage
    os.execute("./appimagetool.AppImage squashfs-root " .. EXPORT_DIR .. "/" .. EXECUTABLE_NAME .. " > /dev/null 2>&1")
    
    -- remove temporary junk
    os.remove("game.love")
    os.remove("squashfs-root/love.svg")
    os.execute("rm -rf squashfs-root")

    -- copy the icon to export directory, just in case appimage icon stuff didn't work
    -- then it can atleast apply it at runtime
    os.execute("cp -r ../../art/icons/64x.png" .. " " .. EXPORT_DIR .. "/icon.png")

    -- copy external files to export directory
    for raw, save in pairs(EXTERNAL_FILES) do
        local folderPath = EXPORT_DIR .. "/" .. save
        folderPath = folderPath:sub(1, folderPath:lastIndexOf("/"))

        os.execute("mkdir -p " .. folderPath)
        os.execute("cp -r " .. raw .. " " .. EXPORT_DIR .. "/" .. save)
    end
    -- copy discord rpc so file to export directory
    -- os.execute("cp -r ../../libs/linux/libdiscord-rpc.so" .. " " .. EXPORT_DIR .. "/libdiscord-rpc.so")
end

print("Done! Check out " .. EXPORT_DIR .. "/" .. EXECUTABLE_NAME .. "\n----------------------------------")