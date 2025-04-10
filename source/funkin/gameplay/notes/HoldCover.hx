package funkin.gameplay.notes;

import flixel.util.FlxSignal;

import funkin.gameplay.UISkin;
import funkin.graphics.SkinnableSprite;

class HoldCover extends SkinnableSprite {
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

    override function loadSkin(newSkin:String):Void {
        if(_skin == newSkin)
            return;

        final json:UISkinData = UISkin.get(newSkin);
        loadSkinComplex(newSkin, json.holdCovers, 'gameplay/uiskins/${newSkin}');

        direction = direction; // force animation update
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} start');
        
        updateHitbox();
        centerOrigin();
    
        centerOffsets();
        offset.add(skinData.offset.x, skinData.offset.y);

        return direction;
    }
}