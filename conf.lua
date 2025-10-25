local project = require("project")

math.randomseed(os.time())
local function chance(c)
    return math.random(0, 100) < (c or 50)
end
local function replace(self, from, to)
    local s, _ = self:gsub(from:gsub('([%^%$%(%)%%%.%[%]%*%+%-%q?])', '%%%1'), to)
    return s
end

function love.conf(t)
    t.identity = project.identity
    t.version = "12.0"
    t.console = false

    t.graphics.gammacorrect = false

    -- i think high dpi doesn't break text anymore??
    t.highdpi = true
    t.usedpiscale = true

    t.window.title = project.title
    if chance(5) then
        -- inside joke with friends became so funny that i had to
        t.window.title = replace(t.window.title, "garfie", "gargie")
        t.window.icon = "art/icons/gargicon.png"
    end

    t.window.width = 1280
    t.window.height = 720

    t.window.minwidth = 200
    t.window.minheight = 0

    t.window.resizable = true
    t.window.vsync = false

    t.modules.audio = false -- we need to initialize alsoft stuff first
end