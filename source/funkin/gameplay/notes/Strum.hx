package funkin.gameplay.notes;

import funkin.gameplay.notes.NoteSkin;
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

        updateOffset();
    }

    public function updateOffset():Void {
        centerOrigin();
        centerOffsets();
        offset.add((skinData.offset[0] ?? 0.0) * (strumLine?.scaleMult?.x ?? 1.0), (skinData.offset[1] ?? 0.0) * (strumLine?.scaleMult?.y ?? 1.0));
    }

    override function update(elapsed:Float) {
        holdTime -= elapsed * 1000;
        if(holdTime <= 0) {
            final strumsPressed:Array<Bool> = strumLine?.playField?.strumsPressed;
            if(!(strumLine?.botplay ?? true) && animation.name.endsWith("confirm") && (strumsPressed != null && strumsPressed.contains(true)))
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

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.strum, 'gameplay/noteskins/${newSkin}');

        direction = direction; // force animation update
        updateHitbox();
        updateOffset();

        final prevAlpha:Float = alpha;
        alpha = 0.0000001;
        drawComplex(FlxG.camera);
        alpha = prevAlpha;
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;
        
        final animName:String = '${Constants.NOTE_DIRECTIONS[direction]} static';
        if(animation.exists(animName))
            animation.play(animName);

        return direction;
    }
}