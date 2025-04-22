package funkin.states.menus.options;

import funkin.ui.AtlasText;

class AccessibilityPage extends OptionPage {
    override function initOptions():Void {
        addOption({
            name: "Flashing Lights",
            description: "Whether or not flashing lights can appear in the menus or during gameplay.\nThis may not work for all mods, be warned!",
        
            id: "flashingLights",
            type: TCheckbox
        });
    }
}