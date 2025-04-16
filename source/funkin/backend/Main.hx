package funkin.backend;

import haxe.CallStack;

import openfl.display.Sprite;
import flixel.FlxGame;

import funkin.backend.InitState;
import funkin.backend.StatsDisplay;

#if (linux && !debug)
@:cppInclude('../../../../vendor/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
@:access(flixel.FlxGame)
class Main extends Sprite {
	public static var changeID:Int = 0;
    public static var audioDisconnected:Bool = false;
	public static var allowTerminalColor:Bool = true;

	public static var sideBars:SideBars;
	public static var statsDisplay:StatsDisplay;

	public function new() {
		super();
		addChild(new FunkinGame(Constants.GAME_WIDTH, Constants.GAME_HEIGHT, InitState.new, Constants.MAX_FPS, Constants.MAX_FPS, true));
		
		sideBars = new SideBars();
		FlxG.game.addChildAt(sideBars, FlxG.game.getChildIndex(FlxG.game._inputContainer));
		
		statsDisplay = new StatsDisplay(10, 3);
		addChild(statsDisplay);
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
}