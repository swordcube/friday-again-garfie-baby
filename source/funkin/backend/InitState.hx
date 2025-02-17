package funkin.backend;

import flixel.input.keyboard.FlxKey;

import funkin.backend.native.NativeAPI;
import funkin.utilities.AudioSwitchFix;

import funkin.states.PlayState;

class InitState extends FlxState {
    private static var _lastState:Class<FlxState>;

    override function create() {
        super.create();

        AudioSwitchFix.init();
        FlxG.fixedTimestep = false;

        NativeAPI.setDarkMode(FlxG.stage.window.title, true);

        FlxG.stage.window.borderless = !FlxG.stage.window.borderless;
        FlxG.stage.window.borderless = !FlxG.stage.window.borderless;
        
        Logs.init();
        Paths.initAssetSystem();

        Controls.init();

        ModManager.scanMods();
        ModManager.registerMods();

        FlxG.signals.preStateCreate.add((newState:FlxState) -> {
            if(Type.getClass(newState) != _lastState) {
                Cache.clearAll();
            }
            _lastState = Type.getClass(newState);
        });
        Conductor.instance = new Conductor();
        FlxG.plugins.addPlugin(Conductor.instance);

        FlxSprite.defaultAntialiasing = true;
        FlxG.switchState(PlayState.new.bind({
            song: "milf",
            difficulty: "hard"
        }));
    }
}