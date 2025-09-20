--- Similar to `require`, but returns from the `src` folder automatically
--- 
--- Recommended to add `@type` documentation to every line of `funkreq` for better autocompletion in VSCode
--- 
--- @param modname string
--- @return unknown
function funkreq(modname)
    return require("src." .. modname)
end

comet = require("thirdparty.comet")
comet.init({
    flags = require("flags"),
    settings = {
        fpsCap = 240,
        bgColor = {0.0, 0.0, 0.0, 1.0},
        dimensions = {1280, 720},
        parallelUpdate = false
    },
    screen = function() return funkreq("funkin.screens.initscreen"):new() end
})