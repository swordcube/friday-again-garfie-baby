comet = require("thirdparty.comet")

function comet.load()
    srcreq("funkin.gfx.debugoverlay").init()
end

comet.init({
    flags = require("flags"),
    settings = {
        srcDirectory = "src",
        fpsCap = 240,
        bgColor = {0.0, 0.0, 0.0, 1.0},
        dimensions = {1280, 720},
        parallelUpdate = true
    },
    screen = function() return srcreq("funkin.screens.initscreen"):new() end
})