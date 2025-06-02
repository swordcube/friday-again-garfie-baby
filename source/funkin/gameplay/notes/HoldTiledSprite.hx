package funkin.gameplay.notes;

import flixel.util.FlxColor;
import funkin.graphics.TiledSprite;

import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.NoteSkin;

/**
 * Tiled sprite class specifically made for hold notes
 */
class HoldTiledSprite extends TiledSprite {
    public var holdTrail:HoldTrail;
    public var direction(default, set):Int;
    
    public function setup(direction:Int, skin:String):HoldTiledSprite {
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

    override function loadSkin(newSkin:String) {
        if(_skin == newSkin)
            return;

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.hold, 'gameplay/noteskins/${newSkin}');

        direction = direction; // force animation update
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} hold');

        var oldHeight:Float = height;
        updateHitbox();
        height = oldHeight;

        return direction;
    }
}