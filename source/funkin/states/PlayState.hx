package funkin.states;

import funkin.backend.interfaces.IBeatReceiver;

import funkin.gameplay.PlayField;
import funkin.gameplay.song.Chart;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.FunkinLua;
#end

class PlayState extends FunkinState implements IBeatReceiver {
	public static var lastParams:PlayStateParams = {
		song: "bopeebo",
		difficulty: "hard"
	};

	public var currentSong:String;
	public var currentDifficulty:String;
	public var currentMix:String;
	
	public var currentChart:ChartData;
	public var playField:PlayField;

	public var startingSong:Bool = true;
	public var endingSong:Bool = false;

	public function new(?params:PlayStateParams) {
		super();
		if(params == null)
			params = lastParams;

		currentSong = params.song;
		currentDifficulty = params.difficulty;

		currentMix = params.mix;
		if(currentMix == null || currentMix.length == 0)
			currentMix = "default";
		
		lastParams = params;
	}

	override function create() {
		super.create();

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		final instPath:String = Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/inst');
		if(lastParams.mod != null && lastParams.mod.length > 0)
			Paths.forceMod = lastParams.mod;
		else {
			Paths.forceMod = null;
			if(instPath.startsWith('${ModManager.MOD_DIRECTORY}/'))
				Paths.forceMod = instPath.split("/")[1];
		}
		currentChart = Chart.load(currentSong, currentDifficulty, currentMix, Paths.forceMod);

		FlxG.sound.playMusic(instPath, 1, false);
		FlxG.sound.music.pause();

		Conductor.instance.music = null;
		Conductor.instance.offset = Options.songOffset;

		Conductor.instance.reset(currentChart.meta.song.bpm);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);

		Conductor.instance.time = -((Conductor.instance.beatLength * 4) + Options.songOffset);

		playField = new PlayField(currentChart, currentDifficulty);
		add(playField);

		#if SCRIPTING_ALLOWED
		var l = new FunkinLua(Paths.script('gameplay/balls', Paths.forceMod));
		l.setParent(this);
		l.execute();
		l.call("onCreatePost");
		l.close();
		#end
	}

	override function update(elapsed:Float) {
		if(startingSong && Conductor.instance.time >= -Options.songOffset)
			startSong();

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1.0, FlxMath.getElapsedLerp(0.05, elapsed));
		super.update(elapsed);
	}

	public function startSong():Void {
		if(!startingSong)
			return;

		startingSong = false;

		FlxG.sound.music.time = 0;
		FlxG.sound.music.resume();

		Conductor.instance.time = -Options.songOffset;
		Conductor.instance.music = FlxG.sound.music;
	}

	override function stepHit(step:Int):Void {}

	override function beatHit(beat:Int):Void {
		if(beat % Conductor.instance.timeSignature.getNumerator() == 0)
			FlxG.camera.zoom += 0.03;
	}

	override function measureHit(measure:Int):Void {}

	override function destroy() {
		Paths.forceMod = null;
		Conductor.instance.offset = 0;
		super.destroy();
	}
}

typedef PlayStateParams = {
	var song:String;
	var difficulty:String;

	/**
	 * Equivalent to song variants in V-Slice
	 */
	var ?mix:String;

	var ?mod:String;
}