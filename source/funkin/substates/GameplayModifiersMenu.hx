package funkin.substates;

import funkin.states.menus.options.OptionPage;

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
            name: "Playback Rate",
            description: "Changes how fast or slow the song will be.\nIf you're on a lower rate, your score will be multiplied by that rate!",

            id: "playbackRate",
            type: TFloat(0.01, 10, 0.01, 2)
        });
    }
}