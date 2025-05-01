package funkin.ui.options.pages;

class AppearancePage extends OptionPage {
    public function new() {
        super("Appearance");
    }

    override function initOptions():Void {
        addOption({
            name: "Antialiasing",
            description: "Provides a very tiny performance boost when disabled\nat the cost of worser looking graphics.",
        
            id: "antialiasing",
            type: TCheckbox,

            callback: (value:Dynamic) -> {
                FlxG.allowAntialiasing = value;
                FlxG.stage.quality = (FlxG.allowAntialiasing) ? HIGH : LOW;
            }
        });
        addOption({
            name: "Flashing Lights",
            description: "Whether or not flashing lights can appear in the menus or during gameplay.\nThis may not work for all mods, be warned!",
        
            id: "flashingLights",
            type: TCheckbox
        });
        addOption({
            name: "HUD Type",
            description: "Changes how the HUD looks during gameplay.\nThis only works if the song has the default HUD skin!",

            id: "hudType",
            type: TList(["Classic", "Psych"])
        });
    }
}