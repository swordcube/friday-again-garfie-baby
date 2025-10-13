function onExecute(time, params)
    local char = params.char
    if char < 2 then
        game.curCameraTarget = (1 - char) + 1
    else
        game.curCameraTarget = char + 1
    end
end