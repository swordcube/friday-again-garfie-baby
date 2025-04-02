package funkin.gameplay.notes;

import funkin.gameplay.UISkin;
import funkin.graphics.SkinnableSprite;

class Strum extends SkinnableSprite {
    public var strumLine:StrumLine;
    public var holdTime:Float = Math.POSITIVE_INFINITY;
    public var direction(default, set):Int;

    public function new(x:Float = 0, y:Float = 0, direction:Int = 0, skin:String) {
        super(x, y);
        
        animation.onFrameChange.add((an, fn, fi) -> {
            if(onFrameChange != null)
                onFrameChange(an, fn, fi);
        });
        loadSkin(skin);
        
        this.direction = direction;
    }

    public dynamic function onFrameChange(animName:String, frameNumber:Int, frameIndex:Int):Void {
        if(frameNumber != 0)
            return;

        centerOrigin();
        centerOffsets();
    }

    override function update(elapsed:Float) {
        holdTime -= elapsed * 1000;
        if(holdTime <= 0) {
            if(!(strumLine?.botplay ?? true) && animation.name.endsWith("confirm"))
                animation.play('${Constants.NOTE_DIRECTIONS[direction]} press');
            else
                animation.play('${Constants.NOTE_DIRECTIONS[direction]} static');

            holdTime = Math.POSITIVE_INFINITY;
        }
        super.update(elapsed);
    }

    override function loadSkin(newSkin:String):Void {
        if(_skin == newSkin)
            return;

        final json:UISkinData = UISkin.get(newSkin);
        loadSkinComplex(newSkin, json.strum, 'gameplay/uiskins/${newSkin}');

        direction = direction; // force animation update

        updateHitbox();
        centerOrigin();
        centerOffsets();
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} static');

        return direction;
    }
}