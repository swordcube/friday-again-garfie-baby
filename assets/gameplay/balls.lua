function onCreatePost()
    local spr = FlxSprite:new(30, 30)
    spr.loadGraphic(Paths.image("wow"))
    spr.screenCenter()
    add(spr)

    FlxTween.tween(spr, {angle = 360}, 5, {type = FlxTweenType.LOOPING})
end