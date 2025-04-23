package funkin.states.menus.options;

class AppearancePage extends OptionPage {
    public function new() {
        super("Appearance");
    }

    override function initOptions():Void {
        addOption({
            name: "Antialiasing",
            description: "Provides a very tiny performance boost, at the cost of\nworser and more pixelated looking graphics.",
        
            id: "antialiasing",
            type: TCheckbox,

            callback: (value:Dynamic) -> FlxG.allowAntialiasing = value
        });
        addOption({
            name: "HUD Type",
            description: "Changes how the HUD looks during gameplay.\nThis only works if the song has the default HUD skin!",

            id: "hudType",
            type: TList(["Classic", "Psych"])
        });
    }
}