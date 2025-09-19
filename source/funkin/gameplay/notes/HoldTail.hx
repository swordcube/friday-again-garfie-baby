package funkin.gameplay.notes;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;

import funkin.graphics.SkinnableSprite;
import funkin.gameplay.notes.NoteSkin;

/**
 * Tiled sprite class specifically made for hold tails
 */
class HoldTail extends SkinnableSprite {
    public var defScale:FlxPoint = new FlxPoint(1, 1);

    public var holdTrail:HoldTrail;
    public var direction(default, set):Int;
    
    public function setup(direction:Int, skin:String):HoldTail {
        this.direction = direction;
        loadSkin(skin);
        
        // reset a bunch of properties the programmer
        // could end up changing via note types
        angle = 0;
        alpha = 1;
        visible = true;
        frameOffset.set();
        color = FlxColor.WHITE;
        colorTransform.color = FlxColor.WHITE;
        shader = null;

        setPosition(-999999, -999999);
        return this;
    }

    public function updateOffset():Void {
        centerOrigin();
        centerOffsets();
        offset.add((skinData.offset[0] ?? 0.0), (skinData.offset[1] ?? 0.0));
    }

    override function loadSkin(newSkin:String) {
        if(_skin == newSkin)
            return;

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.hold, 'gameplay/noteskins/${newSkin}');
        defScale.set(json.hold.scale, json.hold.scale);

        direction = direction; // force animation update
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;

        final animName:String = '${Constants.NOTE_DIRECTIONS[direction]} tail';
        if(animation.exists(animName))
            animation.play(animName);

        final prevScaleX:Float = scale.x;
        final prevScaleY:Float = scale.y;
        centerOrigin();
        
        scale.set(defScale.x, defScale.y);
        updateHitbox();

        scale.set(prevScaleX, prevScaleY);
        updateOffset();

        return direction;
    }
}