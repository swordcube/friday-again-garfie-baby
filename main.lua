comet = require("thirdparty.comet")

comet.init({
    flags = require("flags"),
    settings = {
        fpsCap = 240,
        bgColor = {0.0, 0.0, 0.0, 1.0},
        dimensions = {1280, 720},
        parallelUpdate = false
    },
    -- screen = function() return require("funkin.screens.initscreen"):new() end
})