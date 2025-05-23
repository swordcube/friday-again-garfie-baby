package funkin.ui.options.pages;

import funkin.backend.Main;

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

            callback: (value:Dynamic, _) -> {
                FlxG.allowAntialiasing = value;
                FlxG.stage.quality = (FlxG.allowAntialiasing) ? BEST : LOW;
            }
        });
        addOption({
            name: "Flashing Lights",
            description: "Whether or not flashing lights can appear in the menus or during gameplay.\nThis may not work for all mods, be warned!",
        
            id: "flashingLights",
            type: TCheckbox
        });
        addOption({
            name: "FPS Counter",
            description: "Whether or not your FPS will be shown in\nthe top left corner of the screen.",
        
            id: "fpsCounter",
            type: TCheckbox,

            callback: (value:Dynamic, _) -> Main.statsDisplay.visible = value
        });
        addOption({
            name: "HUD Type",
            description: "Changes how the HUD looks during gameplay.\nThis only works if the song has the default HUD skin!",

            id: "hudType",
            type: TList(["Classic", "Psych"])
        });
        super.initOptions();
    }
}