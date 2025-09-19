package funkin.gameplay.notes;

import flixel.math.FlxPoint;
import flixel.util.FlxSignal;

import funkin.gameplay.notes.NoteSkin;
import funkin.graphics.SkinnableSprite;

class HoldCover extends SkinnableSprite {
    public var defScale:FlxPoint = new FlxPoint(1, 1);

    public var strumLine:StrumLine;
    public var direction(default, set):Int;

    public var onHoldStart:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public var onHold:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public var onHoldEnd:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public function new(x:Float = 0, y:Float = 0, direction:Int = 0, skin:String) {
        super(x, y);
        // blend = SCREEN;

        animation.onFinish.add((name:String) -> {
            if(name.endsWith("start"))
                animation.play('${Constants.NOTE_DIRECTIONS[direction]} hold');

            else if(name.endsWith("end"))
                kill();
        });
        loadSkin(skin);
        this.direction = direction;
    }

    public function start():Void {
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} start');
        revive();
        onHoldStart.dispatch();
    }

    public function hold():Void {
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} hold');
        revive();
        onHold.dispatch();
    }

    public function end():Void {
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} end');
        revive();
        onHoldEnd.dispatch();
    }

    public function updateOffset():Void {
        centerOrigin();
        centerOffsets();
        offset.add((skinData.offset[0] ?? 0.0), (skinData.offset[1] ?? 0.0));
    }

    override function loadSkin(newSkin:String):Void {
        if(_skin == newSkin)
            return;

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.holdCovers, 'gameplay/noteskins/${newSkin}');
        defScale.set(json.holdCovers.scale, json.holdCovers.scale);

        direction = direction; // force animation update

        final prevAlpha:Float = alpha;
        alpha = 0.0000001;
        drawComplex(FlxG.camera);
        alpha = prevAlpha;
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;

        final animName:String = '${Constants.NOTE_DIRECTIONS[direction]} start';
        if(animation.exists(animName))
            animation.play(animName);

        final prevScaleX:Float = scale.x;
        final prevScaleY:Float = scale.y;

        scale.set(defScale.x, defScale.y);
        updateHitbox();

        scale.set(prevScaleX, prevScaleY);
        updateOffset();

        return direction;
    }
}