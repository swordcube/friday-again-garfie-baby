package funkin.gameplay.notes;

import flixel.util.FlxColor;

import funkin.gameplay.notes.NoteSkin;
import funkin.graphics.SkinnableSprite;

class NoteSplash extends SkinnableSprite {
    public var strumLine:StrumLine;
    public var direction(default, set):Int;
    public var splashCount(default, null):Int;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        animation.onFinish.add((_) -> kill());
    }

    public function setup(strumLine:StrumLine, direction:Int, skin:String):NoteSplash {
        loadSkin(skin);
        scale.set(_skinData.scale, _skinData.scale);

        this.strumLine = strumLine;
        this.direction = direction % Constants.KEY_COUNT;

        // reset a bunch of properties the programmer
        // could end up changing via note types

        // which i underestimated when writing this comment
        // holy SHIT there's a lot to account for
        angle = 0;
        alpha = _skinData.alpha;
        shader = null;
        visible = true;
        frameOffset.set();
        color = FlxColor.WHITE;

        colorTransform.redOffset = colorTransform.greenOffset = colorTransform.blueOffset = 0;
        colorTransform.redMultiplier = colorTransform.greenMultiplier = colorTransform.blueMultiplier = 1;

        return this;
    }

    override function loadSkin(newSkin:String):Void {
        if(_skin == newSkin)
            return;

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.splash, 'gameplay/noteskins/${newSkin}');

        splashCount = Lambda.count(json.splash.animation);
        direction = direction; // force animation update

        final prevAlpha:Float = alpha;
        alpha = 0.0000001;
        drawComplex(FlxG.camera);
        alpha = prevAlpha;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if(strumLine != null) {
            final strum:Strum = strumLine.strums.members[direction];
            setPosition(strum.x - ((width - strum.width) * 0.5), strum.y - ((height - strum.height) * 0.5));
        }
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;

        final animName:String = '${Constants.NOTE_DIRECTIONS[direction]} splash${FlxG.random.int(1, splashCount)}';
        if(animation.exists(animName))
            animation.play(animName);

        centerOrigin();        
        updateHitbox();

        centerOffsets();
        offset.add(skinData.offset[0] ?? 0.0, skinData.offset[1] ?? 0.0);

        return direction;
    }
}