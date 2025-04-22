package funkin.states.menus.options;

import funkin.ui.AtlasText;

class GameplayPage extends OptionPage {
    override function initOptions():Void {
        addOption({
            name: "Downscroll",
            description: "Scrolls the notes downwards instead of upwards.",

            id: "downscroll",
            type: TCheckbox
        });
        addOption({
            name: "Use Killers",
            description: "Changes whether or not killers are used\nfor judging notes during gameplay.",

            id: "useKillers",
            type: TCheckbox
        });
        addOption({
            name: "Auto Pause",
            description: "Changes whether or not the game will automatically pause when the window is unfocused.",

            id: "autoPause",
            type: TCheckbox,

            callback: (value:Dynamic) -> FlxG.autoPause = value
        });
        addOption({
            name: "Song Offset",
            description: "Changes how offset the music is from notes (in MS).\nMainly useful for headphones with lots of latency.",

            id: "songOffset",
            type: TInt(-5000, 5000, 5)
        });
        addOption({
            name: "Hit Window",
            description: "Changes how early and late you can hit notes (in MS).",

            id: "hitWindow",
            type: TInt(5, 180, 5)
        });
    }
}