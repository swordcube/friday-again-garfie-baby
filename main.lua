comet = require("thirdparty.comet")

comet.init({
    flags = require("flags"),
    settings = {
        srcDirectory = "src",
        fpsCap = 240,
        bgColor = {0.0, 0.0, 0.0, 1.0},
        dimensions = {1280, 720},
        parallelUpdate = false,
        frequentGc = true
    },
    screen = function() return srcreq("funkin.screens.initscreen"):new() end
})