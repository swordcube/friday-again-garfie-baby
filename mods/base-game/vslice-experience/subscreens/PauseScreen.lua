function onShowPagePost(page, optionNames, optionCallbacks)
    if page == "main" then
        local exitIdx = table.indexOf(optionNames, "Exit to Menu")
        local prevCallback = optionCallbacks[exitIdx]
        optionCallbacks[exitIdx] = function()
            -- switch to sticker transition
            local t = require("transitions.sticker")
            t.stickerPack = "stickers-set-1"

            local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
            if game then
                local stickyPack = game.currentChart.meta.game.stickerPack
                if stickyPack then
                    t.stickerPack = stickyPack
                end
            end
            Transition.currentType = t

            -- reset to default transition once we're done
            comet.signals.postScreenSwitch:connect(function()
                Transition.currentType = Transition.defaultType
            end, true)

            -- call previous callback (usually does as promised, ...exits to menu)
            if prevCallback then
                prevCallback()
            end
        end
    end
end