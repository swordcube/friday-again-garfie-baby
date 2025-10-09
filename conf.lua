local project = require("project")

function love.conf(t)
    t.identity = project.identity
    t.version = "12.0"
    t.console = false

    t.graphics.gammacorrect = false

    -- i think high dpi doesn't break text anymore??
    -- t.highdpi = false
    -- t.usedpiscale = false

    t.window.title = project.title

    t.window.width = 1280
    t.window.height = 720

    t.window.minwidth = 200
    t.window.minheight = 0

    t.window.resizable = true
    t.window.vsync = false

    t.modules.audio = false -- we need to initialize alsoft stuff first
end