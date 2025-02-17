package funkin.states;

import flixel.sound.FlxSound;

import funkin.gameplay.song.VocalGroup;
import funkin.backend.interfaces.IBeatReceiver;

import funkin.gameplay.PlayField;
import funkin.gameplay.song.Chart;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.FunkinScript;
import funkin.backend.scripting.FunkinScriptGroup;
#end
import funkin.assets.loaders.AssetLoader;

class PlayState extends FunkinState implements IBeatReceiver {
	public static var lastParams:PlayStateParams = {
		song: "bopeebo",
		difficulty: "hard"
	};
	public static var instance:PlayState;

	public var currentSong:String;
	public var currentDifficulty:String;
	public var currentMix:String;
	
	public var inst:FlxSound;
	public var vocals:VocalGroup;

	public var currentChart:ChartData;
	public var playField:PlayField;

	public var startingSong:Bool = true;
	public var endingSong:Bool = false;

	#if SCRIPTING_ALLOWED
	public var scripts:FunkinScriptGroup;
	#end

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
		instance = this;
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

		#if SCRIPTING_ALLOWED
		scripts = new FunkinScriptGroup();
		scripts.setParent(this);

		@:privateAccess
		final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;

		inline function addScripts(loader:AssetLoader, dir:String) {
			final items:Array<String> = loader.readDirectory(dir);
			for(i in 0...items.length) {
				final path:String = loader.getPath('${dir}/${items[i]}');
				if(FlxG.assets.exists(path))
					scripts.add(FunkinScript.fromFile(path));
			}
		}
		inline function addSongScripts(loader:AssetLoader) {
			final dir:String = 'gameplay/songs/${currentSong}/${currentMix}/scripts';
			addScripts(loader, dir);
		}
		inline function addGameScripts(loader:AssetLoader) {
			final dir:String = 'gameplay/scripts';
			addScripts(loader, dir);
		}
		for(i in 0...loaders.length) {
			addSongScripts(loaders[i]);
			addGameScripts(loaders[i]);
		}
		final leScripts:Array<FunkinScript> = scripts.members.copy();
		for(i in 0...leScripts.length) {
			leScripts[i].execute();
			leScripts[i].call("onCreate");
		}
		#end

		inst = FlxG.sound.music;
		FlxG.sound.music.pause();

		final playerVocals:String = Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/vocals-${currentChart.meta.game.characters.get("player")}');
		if(FlxG.assets.exists(playerVocals)) {
			vocals = new VocalGroup({
				spectator: Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/vocals-${currentChart.meta.game.characters.get("spectator")}'),
				opponent: Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/vocals-${currentChart.meta.game.characters.get("opponent")}'),
				player: playerVocals
			});
		} else {
			vocals = new VocalGroup({
				player: Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/vocals'),
				isSingleTrack: true
			});
		}
		add(vocals);

		Conductor.instance.music = null;
		Conductor.instance.offset = Options.songOffset;

		Conductor.instance.reset(currentChart.meta.song.bpm);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);

		Conductor.instance.time = -((Conductor.instance.beatLength * 4) + Options.songOffset);

		playField = new PlayField(currentChart, currentDifficulty);
		add(playField);

		#if SCRIPTING_ALLOWED
		scripts.call("onCreatePost");
		#end
	}

	override function update(elapsed:Float) {
		#if SCRIPTING_ALLOWED
		scripts.call("onUpdate", [elapsed]);
		#end
		if(startingSong && Conductor.instance.time >= -Options.songOffset)
			startSong();

		FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1.0, FlxMath.getElapsedLerp(0.05, elapsed));
		super.update(elapsed);

		#if SCRIPTING_ALLOWED
		scripts.call("onUpdatePost", [elapsed]);
		#end
	}

	public function startSong():Void {
		if(!startingSong)
			return;

		startingSong = false;

		FlxG.sound.music.time = 0;
		FlxG.sound.music.resume();

		vocals.seek(0);
		vocals.play();

		Conductor.instance.time = -Options.songOffset;
		Conductor.instance.music = FlxG.sound.music;

		#if SCRIPTING_ALLOWED
		scripts.call("onStartSong");
		#end
	}

	override function stepHit(step:Int):Void {
		#if SCRIPTING_ALLOWED
		scripts.call("onStepHit", [step]);
		#end
	}

	override function beatHit(beat:Int):Void {
		if(beat % Conductor.instance.timeSignature.getNumerator() == 0)
			FlxG.camera.zoom += 0.03;

		#if SCRIPTING_ALLOWED
		scripts.call("onBeatHit", [beat]);
		#end
	}

	override function measureHit(measure:Int):Void {
		#if SCRIPTING_ALLOWED
		scripts.call("onMeasureHit", [measure]);
		#end
	}

	override function destroy() {
		PlayState.instance = null;
		Paths.forceMod = null;
		Conductor.instance.offset = 0;

		#if SCRIPTING_ALLOWED
		scripts.close();
		#end
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