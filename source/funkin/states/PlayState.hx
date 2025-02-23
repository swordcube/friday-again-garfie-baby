package funkin.states;

import flixel.util.FlxTimer;

import funkin.gameplay.song.VocalGroup;
import funkin.backend.interfaces.IBeatReceiver;

import funkin.gameplay.PlayField;
import funkin.gameplay.song.Chart;

import funkin.gameplay.character.Character;
import funkin.gameplay.stage.Stage;

import funkin.gameplay.hud.*;
import funkin.gameplay.hud.BaseHUD;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.notes.*;
import funkin.backend.scripting.events.gameplay.*;

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

	public var spectator:Character;
	public var opponent:Character;
	public var player:Character;

	public var stage:Stage;
	
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
		if(lastParams._chart != null) {
			currentChart = lastParams._chart;
			lastParams._chart = null; // this is only useful for changing difficulties mid song, so we don't need to keep this value
		} else
			currentChart = Chart.load(currentSong, currentMix, Paths.forceMod);
		
		FlxG.sound.playMusic(instPath, 0, false);

		Conductor.instance.music = null;
		Conductor.instance.offset = Options.songOffset;

		Conductor.instance.reset(currentChart.meta.song.bpm);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);

		Conductor.instance.time = -((Conductor.instance.beatLength * 4) + Options.songOffset);

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

		stage = new Stage(currentChart.meta.game.stage, {
			spectator: new Character(currentChart.meta.game.getCharacter("spectator"), false),
			opponent: new Character(currentChart.meta.game.getCharacter("opponent"), false),
			player: new Character(currentChart.meta.game.getCharacter("player"), true)
		});
		add(stage);

		playField = new PlayField(currentChart, currentDifficulty);

		playField.onNoteHit.add(onNoteHit);
		playField.onNoteHitPost.add(onNoteHitPost);

		playField.onNoteMiss.add(onNoteMiss);
		playField.onNoteMissPost.add(onNoteMissPost);

		add(playField);
		
		var event:HUDGenerationEvent = Events.get(HUD_GENERATION);
		#if SCRIPTING_ALLOWED
		event = scripts.event("onHUDGeneration", event.recycle(Options.hudType));
		#else
		event = event.recycle(Options.hudType);
		#end
		switch(event.hudType) {
			case "Classic":
				playField.hud = new ClassicHUD(playField);

			default:
				playField.hud = new ScriptedHUD(playField, event.hudType);
		}
		add(playField.hud);

		#if SCRIPTING_ALLOWED
		if(playField.hud is ScriptedHUD) {
			final hud:ScriptedHUD = cast playField.hud;
			scripts.add(hud.script);

			hud.script.setParent(hud);
			hud.script.call("onCreate");
		}
		#end

		inst = FlxG.sound.music;
		inst.pause();

		inst.volume = 1;
		inst.onComplete = finishSong;

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

		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.END)
			endSong(); // end the song immediately when SHIFT + END is pressed, as emergency

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

		#if SCRIPTING_ALLOWED
		scripts.call("onStartSong");
		scripts.call("onSongStart");
		#end

		FlxG.sound.music.time = 0;
		FlxG.sound.music.resume();

		vocals.seek(0);
		vocals.play();

		Conductor.instance.time = -Options.songOffset;
		Conductor.instance.music = FlxG.sound.music;

		#if SCRIPTING_ALLOWED
		scripts.call("onStartSongPost");
		scripts.call("onSongStartPost");
		#end
	}

	public function endSong():Void {
		if(endingSong)
			return;

		endingSong = true;

		#if SCRIPTING_ALLOWED
		scripts.call("onEndSong");
		scripts.call("onSongEnd");
		#end

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = 0;
		FlxG.sound.music.volume = 0;
		FlxG.sound.music.looped = true;

		// TODO: story mode
		FlxG.signals.postStateSwitch.addOnce(() -> {
			FlxTimer.wait(0.001, () -> FlxG.sound.music.fadeIn(2, 0, 1));
		});
		FlxG.switchState(FreeplayState.new);

		#if SCRIPTING_ALLOWED
		scripts.call("onEndSongPost");
		scripts.call("onSongEndPost");
		#end
	}

	//----------- [ Private API ] -----------//

	private function finishSong():Void {
		if(Conductor.instance.offset > 0) {
			// end the song after waiting for the amount
			// of time your song offset takes (in seconds),
			// to avoid the song ending too early
			FlxTimer.wait(Conductor.instance.offset / 1000, endSong);
		} else
			endSong();
	}

	private function onNoteHit(event:NoteHitEvent):Void {
		#if SCRIPTING_ALLOWED
		scripts.event("onNoteHit", event);
		#end
	}

	private function onNoteHitPost(event:NoteHitEvent):Void {
		#if SCRIPTING_ALLOWED
		scripts.event("onNoteHitPost", event);
		#end
	}

	private function onNoteMiss(event:NoteMissEvent):Void {
		#if SCRIPTING_ALLOWED
		scripts.event("onNoteMiss", event);
		#end
	}

	private function onNoteMissPost(event:NoteMissEvent):Void {
		#if SCRIPTING_ALLOWED
		scripts.event("onNoteMissPost", event);
		#end
	}

	override function stepHit(step:Int):Void {
		#if SCRIPTING_ALLOWED
		scripts.call("onStepHit", [step]);
		#end
	}

	override function beatHit(beat:Int):Void {
		if(beat > 0 && beat % Conductor.instance.timeSignature.getNumerator() == 0)
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
		#if SCRIPTING_ALLOWED
		scripts.call("onDestroy");
		scripts.close();
		#end
		PlayState.instance = null;
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

	@:noCompletion
	var ?_chart:ChartData;
}