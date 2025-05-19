package funkin.substates;

import funkin.ui.options.pages.OptionPage;

class GameplayModifiersMenu extends FunkinSubState {
    public var bg:FlxSprite;
    public var page:GameplayModifiersPage;

    override function create():Void {
        super.create();

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        bg = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, FlxColor.BLACK);
		bg.alpha = 0;
		bg.screenCenter();
		add(bg);

        page = new GameplayModifiersPage();
        page.create();
        page.onExit.add(close);
        add(page);

        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}

class GameplayModifiersPage extends OptionPage {
    public function new() {
        super("Gameplay Modifiers");
    }

    override function initOptions():Void {
        addGameplayModifier({
            name: "Practice Mode",
            description: "Whether or not you are invincible from dying to zero health.\nYour scores will not save while this is enabled!",

            id: "practiceMode",
            type: TCheckbox
        });
        addGameplayModifier({
            name: "Botplay",
            description: "Whether or not your notes will be hit automatically.\nYour scores will not save while this is enabled!",

            id: "botplay",
            type: TCheckbox
        });
        addGameplayModifier({
            name: "Scroll Type",
            description: "Changes how scroll speed is applied to the notes.\n\nMultiplicative multiplies the chart's scroll speed with your multiplier.\nConstant sets the scroll speed directly.\nXMod sets the scroll speed based on song BPM.",

            id: "scrollType",
            type: TList(["Multiplicative", "Constant", "XMod"])
        });
        addGameplayModifier({
            name: "Scroll Speed",
            description: "Changes how fast or slow the notes will scroll by.\nThis is affected by playback rate and scroll type!\n\nIf your scroll type is XMod, this value is redundant.",

            id: "scrollSpeed",
            type: TFloat(0.05, 10, 0.05, 2)
        });
        addGameplayModifier({
            name: "Playback Rate",
            description: "Changes how fast or slow the song will be.\nIf you're on a lower rate, your score will be multiplied by that rate!",

            id: "playbackRate",
            type: TFloat(0.05, 10, 0.05, 2)
        });
    }
}