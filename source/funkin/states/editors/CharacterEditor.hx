package funkin.states.editors;

import funkin.ui.*;

// this is more of a offset editor than a character editor
// but i'll get to that later when i'm not lazy

class CharacterEditor extends UIState {
    override function create():Void {
        FlxG.camera.bgColor = FlxColor.GRAY;
        
        super.create();
    }

    override function destroy():Void {
        FlxG.camera.bgColor = FlxColor.BLACK;
        super.destroy();
    }
}