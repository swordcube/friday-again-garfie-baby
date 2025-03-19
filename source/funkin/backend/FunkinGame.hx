package funkin.backend;

import sys.io.File;
import sys.FileSystem;

import haxe.CallStack;
import lime.system.System;

import openfl.Lib;
import openfl.events.UncaughtErrorEvent;

import flixel.FlxGame;
import flixel.util.typeLimit.NextState.InitialState;

import funkin.backend.native.NativeAPI;

using funkin.utilities.OpenFLUtil;

class FunkinGame extends FlxGame {
    public function new(gameWidth = 0, gameHeight = 0, ?initialState:InitialState, updateFramerate = 60, drawFramerate = 60, skipSplash = false, ?startFullscreen:Bool = false) {
        super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);

        #if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (event:UncaughtErrorEvent) -> {
            event.cancelEvent();
            _onCrash(event.error);
        });

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(_onCrash);
		#end
		#end
    }

    #if CRASH_HANDLER
    //
    // stole from troll engine 🧌
    // https://github.com/riconuts/FNF-Troll-Engine/blob/d5f66fb1d5ab53a04a8831bac5533268cf5d925b/source/funkin/FNFGame.hx#L183
    //
    private function _onCrash(err:String):Void {
        Sys.print("\nCall stack starts below");

		var callstack:String = Main.callstackToString(CallStack.exceptionStack(true));
		Sys.print('\n${callstack}\n${err}\n');

		var boxMessage:String = '${callstack}\n${err}\n';
        
		#if SAVE_CRASH_LOGS
        if(!FileSystem.exists('crash'))
            FileSystem.createDirectory('crash');
        
        final dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		final fileName:String = 'crash/${FlxG.stage.application.meta.get("file").replace(" ", "-")}-${dateNow}.txt';
		
        boxMessage += '\nCall stack was saved as ${fileName}';
		File.saveContent(fileName, callstack);
		#end

		#if WINDOWS_CRASH_HANDLER
		boxMessage += "\nWould you like to goto the main menu?";
		var ret = NativeAPI.showMessageBox(err, boxMessage, ERROR | MessageBoxOptions.YES_NO_CANCEL | MessageBoxDefaultButton.BUTTON_3);
		
		switch(ret) {
			case YES: 
				_toMainMenu();
				return;
            
			case CANCEL: 
				// Continue with a possibly unstable state
				return;
			
            default:
				// Close the game
		}
		#else
		FlxG.stage.window.alert(callstack, err);
		#end
        
		System.exit(1);
    }

    @:unreflective
    private function _toMainMenu():Void {
        try {
            if(_state != null) {
                _state.destroy();
                _state = null;
            }
        }
        catch(e) {
            Logs.error('Failed to destroy state: ${e}');
            _state = null;
        }
        _nextState = new funkin.states.menus.FreeplayState();
        switchState();
    }
    #end
}