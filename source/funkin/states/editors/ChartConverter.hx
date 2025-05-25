package funkin.states.editors;

import flixel.util.FlxTimer;

import funkin.ui.AtlasText;
import funkin.substates.ChartFormatMenu;
import funkin.states.menus.MainMenuState;

class ChartConverter extends FunkinState {
    public var bg:FlxSprite;

    public var fromFormat:ChartFormatMeta;
    public var toFormat:ChartFormatMeta;

    override function create():Void {
        super.create();
        TransitionableState.skipNextTransIn = true;
        TransitionableState.skipNextTransOut = true;

        // Setup the background
        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        bg.scale.set(1.1, 1.1);
        bg.updateHitbox();
        bg.screenCenter();
        bg.alpha = 0.1;
        bg.scrollFactor.set();
        add(bg);

        // Open the actual menu itself
        final menu:ChartFormatMenu = new ChartFormatMenu("Choose a format to convert from", true);
        menu.onSelect = (format:ChartFormatMeta) -> {
            menu.busy = true;
            fromFormat = format;

            final menu2:ChartFormatMenu = new ChartFormatMenu("Choose a format to convert to", false);
            menu2.onSelect = (format2:ChartFormatMeta) -> {
                menu2.busy = true;
                toFormat = format2;

                menu2.selectChart(
                    fromFormat.formatConstructor(),
                    toFormat.formatConstructor()
                );
            };
            menu2.onSuccess = () -> {
                final successText:AtlasText = new AtlasText(20, FlxG.height - 20, "bold", LEFT, "Conversion successful!\nYou will be sent back in 2 seconds...", 0.6);
                successText.y -= successText.height;
                add(successText);

                FlxTimer.wait(2.0, () -> {
                    FlxG.switchState(MainMenuState.new);
                });
            };
            menu2.onCancel = menu.onCancel;
            openSubState(menu2);
        };
        menu.onCancel = () -> {
            FlxG.switchState(MainMenuState.new);
        };
        FlxTimer.wait(0.001, () -> {
            openSubState(menu);
        });
        // resetSubState(); // OPEN IMMEDIATELYYY
    }
}