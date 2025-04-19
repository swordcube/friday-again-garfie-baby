package funkin.states.menus.options;

import funkin.ui.AtlasText;

class MainPage extends Page {
    public var grpItems:FlxTypedGroup<AtlasText>;

    override function create():Void {
        super.create();

        grpItems = new FlxTypedGroup<AtlasText>();
        add(grpItems);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if(controls.justPressed.BACK) {
            FlxG.switchState(MainMenuState.new);
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }
}