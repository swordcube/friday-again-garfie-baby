package funkin.backend;

import funkin.backend.native.NativeAPI;
import funkin.backend.plugins.ForceCrashPlugin;

import funkin.graphics.RatioScaleModeEx;

import funkin.utilities.FlxUtil;
import funkin.utilities.AudioSwitchFix;

import funkin.states.PlayState;
import funkin.states.menus.FreeplayState;

class InitState extends FlxState {
    private static var _lastState:Class<FlxState>;

    override function create() {
        super.create();

        #if cpp
        // ugly hack to make printing actually work
        //
        // it stopped working due to a recent hxcpp change:
        // https://github.com/HaxeFoundation/hxcpp/pull/1199
        //
        // should be line buffered now, but it instead does nothing
        // so i have to do this now :/
        // 
        // TODO: better solution, this sucks and only works on hxcpp
        untyped __cpp__("setbuf(stdout, 0)");
        #end

        // init audio device switch fix
        AudioSwitchFix.init();

        // set fixed timestep to false, to make elapsed not a constant value
        // this makes menus really slow to get thru on low framerates
        FlxG.fixedTimestep = false;

        #if windows
        NativeAPI.setDarkMode(FlxG.stage.window.title, true);

        // Hacky fix for Windows 10 not applying dark mode correctly
        // Doesn't happen on Windows 11, would be ideal to check for Windows 11
        // but i don't know how to do that
        FlxG.stage.window.borderless = !FlxG.stage.window.borderless;
        FlxG.stage.window.borderless = !FlxG.stage.window.borderless;
        #end

        // init logging & asset system
        Logs.init();
        Paths.initAssetSystem();

        // init controls and mod manager
        Controls.init();

        #if SCRIPTING_ALLOWED
        GlobalScript.init();
        #end

        // init some flixel stuff
        FlxUtil.init();
        FlxG.scaleMode = new RatioScaleModeEx();

        FlxG.signals.preStateCreate.add((newState:FlxState) -> {
            if(Type.getClass(newState) != _lastState) {
                Cache.clearAll();
            }
            _lastState = Type.getClass(newState);
        });
        WindowUtil.resetTitle();

        // init cursor
        Cursor.init();
        
        // init conductor
        Conductor.instance = new Conductor();
        FlxG.plugins.addPlugin(Conductor.instance);

        // init extra plugins
        FlxG.plugins.addPlugin(new ForceCrashPlugin());

        // hide cursor, we probably don't need it rn
        FlxG.mouse.visible = false;
        FlxSprite.defaultAntialiasing = true;

        final args = Sys.args();
        if(args.contains("--song")) {
            // if song arguments are passed, immediately go
            // to playstate with that song
            // 
            // NOTE: difficulty MUST be passed!!
            FlxG.switchState(PlayState.new.bind({
                song: args[args.indexOf("--song") + 1],
                difficulty: args[args.indexOf("--diff") + 1]
            }));    
        } else {
            // otherwise do normal starting logic
            FlxG.switchState(FreeplayState.new);
        }
    }
}