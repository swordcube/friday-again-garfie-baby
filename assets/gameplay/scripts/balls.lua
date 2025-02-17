function onCreate()
    local spr = FlxSprite:new(30, 30)
    spr.loadGraphic(Paths.image("wow"))
    spr.screenCenter()
    spr.color = FlxColor.fromRGB(0, 255, 200)
    add(spr)

    FlxTween.tween(spr, {angle = 360}, Conductor.instance.beatLength / 1000.0, {
        type = FlxTweenType.LOOPING,
        onComplete = function(_)
            print(FlxG.random.float(0, 398193))
        end
    })
end