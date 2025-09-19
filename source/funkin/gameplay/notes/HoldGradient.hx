package funkin.gameplay.notes;

import flixel.math.FlxPoint;

import funkin.gameplay.notes.NoteSkin;
import funkin.graphics.SkinnableSprite;

class HoldGradient extends SkinnableSprite {
    public var defScale:FlxPoint = new FlxPoint(1, 1);

    public var strumLine:StrumLine;
    public var direction(default, set):Int;
    public var holding:Bool = false;

    public function new(x:Float = 0, y:Float = 0, direction:Int = 0, skin:String) {
        super(x, y);
        blend = SCREEN;
        
        loadSkin(skin);
        this.direction = direction;
    }

    public function updateOffset():Void {
        centerOrigin();
        centerOffsets();
        offset.add((skinData.offset[0] ?? 0.0), (skinData.offset[1] ?? 0.0));
    }

    override function update(elapsed:Float):Void {
        if(holding)
            alpha = FlxMath.lerp(alpha, skinData.alpha, FlxMath.getElapsedLerp(Conductor.instance.stepLength / 1000, FlxG.elapsed));
        else {
            alpha = FlxMath.lerp(alpha, 0, FlxMath.getElapsedLerp(Conductor.instance.stepLength / 1000, FlxG.elapsed));
            if(Math.abs(alpha) <= 0.01)
                kill();
        }
        super.update(elapsed);
    }

    override function loadSkin(newSkin:String):Void {
        if(_skin == newSkin)
            return;

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.holdGradients, 'gameplay/noteskins/${newSkin}');
        defScale.set(json.holdGradients.scale, json.holdGradients.scale);

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

        final animName:String = '${Constants.NOTE_DIRECTIONS[direction]} gradient';
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