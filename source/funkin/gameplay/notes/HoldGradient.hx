package funkin.gameplay.notes;

import funkin.gameplay.notes.NoteSkin;
import funkin.graphics.SkinnableSprite;

class HoldGradient extends SkinnableSprite {
    public var strumLine:StrumLine;
    public var direction(default, set):Int;
    public var holding:Bool = false;

    public function new(x:Float = 0, y:Float = 0, direction:Int = 0, skin:String) {
        super(x, y);
        blend = SCREEN;
        
        loadSkin(skin);
        this.direction = direction;
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

        direction = direction; // force animation update
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} gradient');
        
        updateHitbox();
        centerOrigin();
    
        centerOffsets();
        offset.add(skinData.offset.x, skinData.offset.y);
        
        return direction;
    }
}