package funkin.backend;

#if hxvlc
import hxvlc.util.Handle;
#end
import lime.graphics.Image;
import flixel.util.FlxTimer;

import funkin.backend.native.NativeAPI;
import funkin.backend.plugins.ForceCrashPlugin;
import funkin.backend.plugins.ScreenShotPlugin;

import funkin.graphics.RatioScaleModeEx;

import funkin.utilities.FlxUtil;
import funkin.utilities.AudioSwitchFix;

#if USE_MOONCHART
import moonchart.backend.FormatDetector;
import funkin.gameplay.song.moonchart.GarfieFormat;
#end
import funkin.gameplay.song.Highscore;

import funkin.states.PlayState;
import funkin.states.menus.TitleState;

import funkin.states.TransitionableState;

class InitState extends FlxState {
    private static var _lastState:Class<FlxState>;

    private var _started:Bool = false;

    override function create() {
        super.create();

        #if (cpp && desktop)
        // ugly hack to make printing actually work
        //
        // it stopped working due to a recent hxcpp change:
        // https://github.com/HaxeFoundation/hxcpp/pull/1199
        //
        // should be line buffered now, but it instead does nothing
        // so i have to do this now :/
        // 
        // TODO: better solution, this sucks
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

        #if (linux || mac || macos)
        // Linux doesn't have executable icons, and apparently
        // the icon doesn't show up on the macOS dock
        //
        // so we just set the icon ourselves to force it to work
		FlxG.stage.window.setIcon(Image.fromFile("icon.png"));
		#end

        // init logging and controls
        trace("init logging");
        Logs.init();
        trace("init controls");
        Controls.init();
        
        // init options & highscore
        trace("init options");
        Options.init();
        trace("init highscore");
        Highscore.init();
        
        // init some flixel stuff
        trace("init flxutil");
        FlxUtil.init();
        trace("init paths asset system");
        Paths.initAssetSystem();
        
        trace("init scale mode & pre state create signal");
        FlxG.scaleMode = new RatioScaleModeEx();
        FlxG.signals.preStateCreate.add((newState:FlxState) -> {
            if(Type.getClass(newState) != _lastState)
                Cache.clearAll();
            
            _lastState = Type.getClass(newState);
        });
        trace("init window util");
        WindowUtil.init();
        
        // init global script
        #if SCRIPTING_ALLOWED
        trace("init global script");
        GlobalScript.init();
        #end
        
        // init the transition shit stuff
        trace("init transitions");
        TransitionableState.resetDefaultTransitions();
        
        // init cursor, discord rpc, and vlc
        trace("init cursor");
        Cursor.init();
        trace("init discord rpc");
        DiscordRPC.init();
        
        #if hxvlc
        trace("init vlc");
        #if desktop
        Handle.initAsync();
        #else
        Handle.init();
        #end
        #end
        
        // init conductor
        trace("init conductor");
        Conductor.instance = new Conductor();
        Conductor.instance.dispatchToStates = true;
        FlxG.plugins.addPlugin(Conductor.instance);
        
        // init moonchart shit
        #if USE_MOONCHART
        trace("init moonchart");
        FormatDetector.registerFormat(GarfieFormat.__getFormat());
        #end
        
        // init extra plugins
        trace("init plugins");
        FlxG.plugins.addPlugin(new ForceCrashPlugin());
        FlxG.plugins.addPlugin(new ScreenShotPlugin());
        
        #if android
        FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
        funkin.mobile.external.android.CallbackUtil.init();
        #end

        // hide cursor, we probably don't need it rn
        trace("start game");
        #if (FLX_MOUSE && !mobile)
        FlxG.mouse.visible = false;
        #else
        startGame();
        #end
    }

    #if (FLX_MOUSE && !mobile)
    override function update(elapsed:Float):Void {
        super.update(elapsed);
        
        // for some reason i have to do this bullshittery
        // just for the cursor to be hidden on linux. what the fuck.
        if(!_started && !FlxG.mouse.visible) {
            FlxTimer.wait(0.001, startGame);
            _started = true;
        }
        FlxG.mouse.visible = false;
    }
    #end

    private function startGame():Void {
        // do starting logic shit
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
            FlxG.switchState(TitleState.new);
        }
    }
}