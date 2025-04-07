package funkin.ui.charter;

class CharterMiniPerformers extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var guys:FlxSpriteContainer;

    public var opponent:MiniPerformer;
    public var player:MiniPerformer;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        bg = new FlxSprite(0, 0).loadGraphic(Paths.image("editors/charter/images/performers/tray"));
        bg.scale.set(0.5, 0.5);
        bg.updateHitbox();
        bg.flipY = true;
        add(bg);

        guys = new FlxSpriteContainer(25, -12);
        add(guys);

        opponent = new MiniPerformer(0, 0, false);
        guys.add(opponent);

        player = new MiniPerformer(0, 0, true);
        guys.add(player);
    }

    //----------- [ Private API ] -----------//
}

class MiniPerformer extends FlxSprite {
    public var holdTimer:Float = Math.POSITIVE_INFINITY;

    public function new(x:Float = 0, y:Float = 0, blue:Bool) {
        super(x, y);
        frames = Paths.getSparrowAtlas('editors/charter/images/performers/${(blue) ? "blue" : "red"}_guy');
        antialiasing = false;

        for(dir in Constants.NOTE_DIRECTIONS)
            animation.addByPrefix(dir, '${dir}0', 12, false);

        animation.addByPrefix("idle", "idle", 12, true);
        animation.play("idle");

        scale.set(1.3, 1.3);
        updateHitbox();
    }

    override function update(elapsed:Float):Void {
        holdTimer -= elapsed * 1000 * Conductor.instance.rate;
        if(holdTimer <= 0) {
            holdTimer = Math.POSITIVE_INFINITY;
            animation.play("idle");
        }
        super.update(elapsed);
    }

    public function sing(direction:Int, ?duration:Float = 0):Void {
        if(duration <= 0)
            duration = Conductor.instance.stepLength * 4;

        holdTimer = duration;
        animation.play(Constants.NOTE_DIRECTIONS[direction], true);
    }
}