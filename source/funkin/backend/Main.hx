package funkin.backend;

import sys.thread.Thread;

import haxe.CallStack;
import haxe.io.BytesOutput;

import openfl.display.Sprite;

import funkin.backend.Lasagna;
import funkin.backend.InitState;
import funkin.backend.StatsDisplay;
import funkin.backend.native.HiddenProcess;

#if (linux && !debug)
@:cppInclude('../../../../vendor/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
@:access(flixel.FlxGame)
class Main extends Sprite {
	public static var instance(default, null):Main;
	public static var gameThreads:Array<Thread> = [];

	public static var changeID:Int = 0;
    public static var audioDisconnected:Bool = false;
	public static var allowTerminalColor:Bool = true;

	public static var sideBars:SideBars;
	public static var statsDisplay:StatsDisplay;

	public function new() {
		super();
		instance = this;

		for(i in 0...4)
			gameThreads.push(Thread.createWithEventLoop(() -> Thread.current().events.promise()));

		statsDisplay = new StatsDisplay(10, 3);
		addChild(statsDisplay);
		
		addChildAt(new FunkinGame(Constants.GAME_WIDTH, Constants.GAME_HEIGHT, InitState.new, Constants.MAX_FPS, Constants.MAX_FPS, true), 0);
		statsDisplay.visible = Options.fpsCounter;

		sideBars = new SideBars();
		FlxG.game.addChildAt(sideBars, FlxG.game.getChildIndex(FlxG.game._inputContainer));
		
		addChild(new Lasagna());
	}

	public static function execASync(func:Void->Void) {
		var thread = gameThreads[(_threadCycle++) % gameThreads.length];
		thread.events.run(func);
	}

	public static function callstackToString(callstack:Array<StackItem>):String {
		var str:String = "";
		for (stackItem in callstack) {
			switch (stackItem) {
				case FilePos(_, file, line, _):
					str += '$file:$line\n';
				default:
			}
		}
		return str;
	}

	#if sys
	// https://github.com/openfl/hxp/blob/master/src/hxp/System.hx
	public static function runProcess(command:String, ?args:Array<String>):Null<String> {
		var process = new HiddenProcess(command, args);
		var buffer = new BytesOutput();
		var waiting = true;

		while (waiting) {
			try {
				var current = process.stdout.readAll(1024);
				buffer.write(current);

				if (current.length == 0)
					waiting = false;
			} catch (e) {
				waiting = false;
			}
		}

		var result = process.exitCode();
		var output = buffer.getBytes().toString();
		var retVal:Null<String> = output;

		if (output == "") {
			var error = process.stderr.readAll().toString();
			process.close();

			if (result != 0 || error != "")
				retVal = null;
		} else {
			process.close();
		}
		
		return retVal;
	}
	#end

	private static var _threadCycle:Int = 0;
}