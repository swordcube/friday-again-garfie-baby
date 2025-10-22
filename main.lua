comet = require("thirdparty.comet")

comet.init({
    flags = require("flags"),
    settings = {
        srcDirectory = "src",
        fpsCap = 0,
        bgColor = {0.0, 0.0, 0.0, 1.0},
        dimensions = {1280, 720},
        parallelUpdate = false
    },
    screen = function() return srcreq("funkin.screens.initscreen"):new() end
})