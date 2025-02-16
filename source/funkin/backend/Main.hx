package funkin.backend;

import openfl.display.Sprite;
import flixel.FlxGame;

import funkin.backend.InitState;
import funkin.backend.StatsDisplay;

class Main extends Sprite {
	public static var changeID:Int = 0;
    public static var audioDisconnected:Bool = false;

	public static var allowTerminalColor:Bool = true;

	public function new() {
		super();
		addChild(new FlxGame(0, 0, InitState.new, 0, 0, true));
		addChild(new StatsDisplay(10, 3));
	}
}