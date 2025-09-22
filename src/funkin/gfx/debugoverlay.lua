local DebugOverlay = {}
DebugOverlay.overlayType = "none" --- @type "none"|"basic"|"advanced"

local overlayTypes = {
    "none",
    "basic",
    "advanced"
}

local gfx = love.graphics
local bit = require("bit")

--- Draws a colored rectangle
--- @param mode "fill"|"line"
--- @param x    number
--- @param y    number
--- @param w    number
--- @param h    number
--- @param r    number|string?
--- @param g    number?
--- @param b    number?
--- @param a    number?
gfx.coloredRectangle = function(mode, x, y, w, h, r, g, b, a)
    r, g, b, a = r or 1.0, g or 1.0, b or 1.0, a or 1.0
    if type(r) == "string" then
        local colstr = r:replace("#", "0x")
        if not colstr:startsWith("0x") then
            colstr = "0x" .. colstr
        end
        if #colstr == 8 then
            colstr = "0xFF" .. colstr:sub(3)
        end
        local col = tonumber(colstr)
        r = bit.band(bit.rshift(col, 16), 0xff) / 255
        g = bit.band(bit.rshift(col, 8), 0xff) / 255
        b = bit.band(col, 0xff) / 255
        a = bit.band(bit.rshift(col, 24), 0xff) / 255
    end
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(r * pr, g * pg, b * pb, a * pa)
    gfx.rectangle(mode, x, y, w, h)
    gfx.setColor(pr, pg, pb, pa)
end

--- @param x    number
--- @param y    number
--- @param w    number
--- @param h    number
--- @param r    number|string?
--- @param g    number?
--- @param b    number?
--- @param a    number?
gfx.coloredLine = function(x, y, w, h, r, g, b, a)
    r, g, b, a = r or 1.0, g or 1.0, b or 1.0, a or 1.0
    if type(r) == "string" then
        local colstr = r:replace("#", "0x")
        if not colstr:startsWith("0x") then
            colstr = "0x" .. colstr
        end
        if #colstr == 8 then
            colstr = "0xFF" .. colstr:sub(3)
        end
        local col = tonumber(colstr)
        r = bit.band(bit.rshift(col, 16), 0xff) / 255
        g = bit.band(bit.rshift(col, 8), 0xff) / 255
        b = bit.band(col, 0xff) / 255
        a = bit.band(bit.rshift(col, 24), 0xff) / 255
    end
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setColor(r * pr, g * pg, b * pb, a * pa)
    gfx.line(x, y, x + w, y + h)
    gfx.setColor(pr, pg, pb, pa)
end

function DebugOverlay.init()
    local updateTimer = 0.0
    local graphUpdateTimer = 0.0

    local debugFont = gfx.newFont(Paths.font("fonts/jetbrains-mono/regular"), 14, "light")
    local debugFontSmall = gfx.newFont(Paths.font("fonts/jetbrains-mono/regular"), 10, "light")
    local debugFontBold = gfx.newFont(Paths.font("fonts/jetbrains-mono/bold"), 14, "light")

    local stats = {
        fps = 0,
        tps = 0,
        
        gcMem = 0,
        peakGcMem = 0,

        taskMem = 0,
        peakTaskMem = 0,

        videoMem = 0,
        peakVideoMem = 0
    }
    local statY = 15
    local function displayStat(boldText, statText, otherStatText)
        if boldText then
            gfx.print(boldText, debugFontBold, 20, statY + 6)
        end
        gfx.print(statText, debugFont, 20 + (boldText and debugFontBold:getWidth(boldText) or 0), statY + 6)
        if otherStatText then
            local pr, pg, pb, pa = gfx.getColor()
            gfx.setColor(pr, pg, pb, 0.5 * pa)
            gfx.print(otherStatText, debugFont, 20 + (boldText and debugFontBold:getWidth(boldText) or 0) + debugFont:getWidth(statText), statY + 6)
            gfx.setColor(pr, pg, pb, pa)
        end
        statY = statY + 15
    end
    local boxWidth = 320

    local fpsGraph = cometreq("gfx.graph"):new("custom", 0, 0, boxWidth - 20, 40, 0.05, "") --- @type comet.gfx.Graph
    local tpsGraph = comet.settings.parallelUpdate and cometreq("gfx.graph"):new("custom", 0, 0, boxWidth - 20, 40, 0.05, "") or nil --- @type comet.gfx.Graph
    
    comet.signals.postUpdate:connect(function()
        local dt = comet.getFullDeltaTime()
        updateTimer = updateTimer + dt
        graphUpdateTimer = graphUpdateTimer + dt
        
        while updateTimer >= 1.0 do
            stats.fps = love.timer.getFPS()
            stats.tps = love.timer.getTPS()
            stats.gcMem = collectgarbage("count") * 1000
            if stats.gcMem > stats.peakGcMem then
                stats.peakGcMem = stats.gcMem
            end
            stats.taskMem = comet.native.getProcessMemory()
            if stats.taskMem > stats.peakTaskMem then
                stats.peakTaskMem = stats.taskMem
            end
            stats.videoMem = gfx.getStats().texturememory
            if stats.videoMem > stats.peakVideoMem then
                stats.peakVideoMem = stats.videoMem
            end
            updateTimer = updateTimer - 1.0
        end
        if comet.settings.parallelUpdate then
            tpsGraph:update(dt, dt * 1000)
        end
    end)
    comet.signals.postDraw:connect(function()
        local drawDt = comet.getDeltaTime()
        fpsGraph:update(drawDt, drawDt * 1000)
        
        if DebugOverlay.overlayType == "none" then
            return
        end
        local w, h = boxWidth, 145
        if DebugOverlay.overlayType == "advanced" then
            h = comet.settings.parallelUpdate and 245 or 165
        elseif DebugOverlay.overlayType == "basic" then
            h = comet.settings.parallelUpdate and 80 or 65
        end
        local fillColor, lineColor = "CA282A30", "CA696E7E"
        gfx.coloredRectangle("fill", 10, 10, w, h, fillColor)
        gfx.coloredRectangle("line", 10, 10, w, h, lineColor)
        
        statY = 10
        displayStat("FPS: ", tostring(stats.fps))
        
        if comet.settings.parallelUpdate then
            displayStat("TPS: ", tostring(stats.tps))
        end
        displayStat("GC MEM: ", tostring(math.humanizeBytes(stats.gcMem)), " / " .. tostring(math.humanizeBytes(stats.peakGcMem)))
        displayStat("TASK MEM: ", tostring(math.humanizeBytes(stats.taskMem)), " / " .. tostring(math.humanizeBytes(stats.peakTaskMem)))
        
        if DebugOverlay.overlayType == "advanced" then
            displayStat("VRAM: ", tostring(math.humanizeBytes(stats.videoMem)), " / " .. tostring(math.humanizeBytes(stats.peakVideoMem)))
            
            gfx.coloredLine(20, statY + 20, w - 20, 0, lineColor)
            statY = statY + 30
    
            fpsGraph.x = 20
            fpsGraph.y = statY + 15
            fpsGraph:draw()
    
            local txt = "Frametime (" .. math.truncate(fpsGraph:average(), 4) .. "ms avg)"
            gfx.print(txt, debugFontSmall, 20, statY)
            statY = statY + 70
            
            if comet.settings.parallelUpdate then
                tpsGraph.x = 20
                tpsGraph.y = statY + 15
                tpsGraph:draw()
                
                txt = "Ticktime (" .. math.truncate(tpsGraph:average(), 4) .. "ms avg)"
                gfx.print(txt, debugFontSmall, 20, statY)
                statY = statY + 55
            end
            statY = h + 20

            h = 125
            gfx.coloredRectangle("fill", 10, statY, w, h, fillColor)
            gfx.coloredRectangle("line", 10, statY, w, h, lineColor)
            
            local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
            displayStat("Current Song Position: ", tostring(math.truncate(c:getCurrentRawPlayhead(), 3)))
            displayStat("- ", c.curStep .. " step" .. (c.curStep == 1 and "" or "s"))
            displayStat("- ", c.curBeat .. " beat" .. (c.curBeat == 1 and "" or "s"))
            displayStat("- ", c.curMeasure .. " measure" .. (c.curMeasure == 1 and "" or "s"))
            displayStat("", "")
            displayStat("Current BPM: ", tostring(c:getCurrentBPM()))

            local ts = c:getCurrentTimeSignature()
            displayStat("Time Signature: ", ("%d/%d"):format(ts[1], ts[2]))
            
            statY = statY + 30
            h = 80
            gfx.coloredRectangle("fill", 10, statY, w, h, fillColor)
            gfx.coloredRectangle("line", 10, statY, w, h, lineColor)
            
            local screenPath = "N/A"
            if ScreenManager.instance.current then
                local src = comet.settings.srcDirectory .. "."
                if ScreenManager.instance.current.class.path then
                    if ScreenManager.instance.current.class.path:startsWith(src) then
                        screenPath = ScreenManager.instance.current.class.path:sub(#src + 1)
                    else
                        screenPath = ScreenManager.instance.current.class.path
                    end
                elseif ScreenManager.instance.current.class.name then
                    screenPath = ScreenManager.instance.current.class.name
                end
            end
            displayStat("Screen: ", screenPath)

            local objectCount = 0
            local function recursiveObjectSearch(children)
                if not children then
                    return
                end
                for i = 1, #children do
                    objectCount = objectCount + 1
                    recursiveObjectSearch(children[i])
                end
            end
            recursiveObjectSearch(ScreenManager.instance.current and ScreenManager.instance.current.children or nil)
            displayStat("Objects: ", objectCount)

            local textureCount = 0
            for _, _ in pairs(comet.gfx._cache) do
                textureCount = textureCount + 1
            end
            displayStat("Textures: ", textureCount)
            displayStat("Sounds: ", #comet.mixer.sounds.children)
            
            -- TODO: asset loader display
            
            local assetLoaders = Paths._registeredAssetLoaders
            h = 35 + (#assetLoaders * 15)
            statY = statY + 30
            
            gfx.coloredRectangle("fill", 10, statY, w, h, fillColor)
            gfx.coloredRectangle("line", 10, statY, w, h, lineColor)
            
            displayStat("Asset Loaders", "")            
            for i = 1, #assetLoaders do
                displayStat(nil, ("- %s (%s)"):format(assetLoaders[i].name, assetLoaders[i].displayedRoot))
            end
        end
    end)
    comet.signals.onInput:connect(function(e)
        if e.type == "key" and e.key == "f3" and e.pressed then
            DebugOverlay.overlayType = overlayTypes[(table.indexOf(overlayTypes, DebugOverlay.overlayType) % #overlayTypes) + 1]
        end
    end)
end

return DebugOverlay