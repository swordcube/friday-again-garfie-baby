package funkin.ui.options.pages;

class MiscellanousPage extends OptionPage {
    public function new() {
        super("Miscellanous");
    }

    override function initOptions():Void {
        addOption({
            name: "Auto Pause",
            description: "Changes whether or not the game will automatically\npause when the window is unfocused.",

            id: "autoPause",
            type: TCheckbox,

            callback: (value:Dynamic) -> FlxG.autoPause = value
        });
        addOption({
            name: "Verbose Logging",
            description: "Whether or not detailed engine logs can appear for debugging purposes.",
        
            id: "verboseLogging",
            type: TCheckbox
        });
    }
}