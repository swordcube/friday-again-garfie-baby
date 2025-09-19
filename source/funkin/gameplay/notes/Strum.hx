package funkin.gameplay.notes;

import flixel.math.FlxPoint;

import funkin.gameplay.notes.NoteSkin;
import funkin.graphics.SkinnableSprite;

import funkin.gameplay.modchart.math.Vector3;
import funkin.gameplay.modchart.IModifierObject;

class Strum extends SkinnableSprite {
    public var objectType:ModifierObjectType = STRUM;
    public var vec3Cache:Vector3 = new Vector3();

    public var defScale:FlxPoint = new FlxPoint(1, 1); // for modcharting
    
    public var strumLine:StrumLine;
    public var holdTime:Float = Math.POSITIVE_INFINITY;
    public var direction(default, set):Int;

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

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
        offset.add((skinData.offset[0] ?? 0.0), (skinData.offset[1] ?? 0.0));
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
        defScale.set(json.strum.scale, json.strum.scale);

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
        
        final animName:String = '${Constants.NOTE_DIRECTIONS[direction]} static';
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