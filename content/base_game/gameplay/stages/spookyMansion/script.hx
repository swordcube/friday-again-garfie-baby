var bg:FlxSprite;

var lightningStrikeBeat:Int = 0;
var lightningStrikeOffset:Int = 8;

function onLoad() {
    bg = add(new FlxSprite(-200, -100));
    bg.frames = getStageSparrow("bg");
    bg.animation.addByPrefix("idle", "halloweem bg0", 24);
    bg.animation.addByPrefix("lightning", "halloweem bg lightning strike", 24, false);
    bg.animation.play("idle", true);
}

function onBeatHit(beat) {
    if (FlxG.random.bool(10) && beat > (lightningStrikeBeat + lightningStrikeOffset) || PlayState.instance.currentSong == "spookeez" && beat == 4)
    {
        bg.animation.play("lightning", true);

        for (char in [characters.player, characters.spectator]) { // really weird but idk how else to do this
            char.playAnim("scared", true);
            char.canDance = false;

            new FlxTimer().start(0.6, function() {
                char.canDance = true;
            });
        }

        lightningStrikeBeat = beat;
		lightningStrikeOffset = FlxG.random.int(8, 24);

        FlxG.sound.play(getStageSFX("thunder_" + FlxG.random.int(1, 2)));
    }
}