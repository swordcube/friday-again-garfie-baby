package funkin.states.menus.options;

import funkin.ui.AtlasText;

class OptionPage extends Page {
    override function update(elapsed:Float):Void {
        super.update(elapsed);
        
        if(controls.justPressed.BACK) {
            menu.loadPage(new MainPage());
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }
}