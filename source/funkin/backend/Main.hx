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
class Main extends Sprite {
	public static var changeID:Int = 0;
    public static var audioDisconnected:Bool = false;
	public static var allowTerminalColor:Bool = true;

	public static var statsDisplay:StatsDisplay;

	public function new() {
		super();
		addChild(new FunkinGame(Constants.GAME_WIDTH, Constants.GAME_HEIGHT, InitState.new, 0, 0, true));
		
		statsDisplay = new StatsDisplay(10, 3);
		addChild(statsDisplay);
	}

	public static function callstackToString(callstack:Array<StackItem>):String {
		var str:String = "";
		for (stackItem in callstack) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					str += '$file:$line\n';
				default:
			}
		}
		return str;
	}
}