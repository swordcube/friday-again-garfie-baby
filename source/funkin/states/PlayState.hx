package funkin.states;

import flixel.math.FlxPoint;
import flixel.util.FlxTimer;

import funkin.backend.Conductor.IBeatReceiver;
import funkin.backend.assets.loaders.AssetLoader;

import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.gameplay.*;
import funkin.backend.scripting.events.notes.*;

import funkin.gameplay.PlayField;
import funkin.gameplay.FunkinCamera;
import funkin.gameplay.character.Character;

import funkin.gameplay.hud.*;
import funkin.gameplay.hud.BaseHUD;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.VocalGroup;

import funkin.gameplay.stage.Stage;

import funkin.gameplay.events.*;
import funkin.gameplay.events.EventRunner;

import funkin.states.editors.ChartEditor;
import funkin.states.menus.FreeplayState;

// import scripting events anyways because i'm too lazy
// to make it work on no scripting mode lol!!
#if SCRIPTING_ALLOWED
import funkin.backend.scripting.FunkinScript;
import funkin.backend.scripting.FunkinScriptGroup;
#end

enum abstract CameraTarget(Int) from Int to Int {
	final OPPONENT = 0;
	final PLAYER = 1;
	final SPECTATOR = 2;
}

class PlayState extends FunkinState {
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
	public var camFollow:FlxObject;

	/**
	 * The current character that is being followed by the camera.
	 * 
	 * - `0` - Opponent
	 * - `1` - Player
	 * - `2` - Spectator
	 */
	public var curCameraTarget:CameraTarget = OPPONENT;

	public var camGame:FunkinCamera;
	public var camHUD:FunkinCamera;
	
	public var inst:FlxSound;
	public var vocals:VocalGroup;

	public var currentChart:ChartData;
	public var playField:PlayField;

	public var eventRunner:EventRunner;

	public var startingSong:Bool = true;
	public var endingSong:Bool = false;

	/**
	 * How many beats it will take before the camera bumps.
	 * 
	 * If this value is exactly `0`, the camera won't bump.
	 * If this value is below `0`, the camera will bump every measure.
	 */
	public var camZoomingInterval:Int = -1;

	/**
	 * The intensity of the camera bumping.
	 */
	public var camZoomingIntensity:Float = 1;

	public var chartingMode:Bool = false;

	#if SCRIPTING_ALLOWED
	public var scripts:FunkinScriptGroup;

	public var noteTypeScripts:Map<String, FunkinScript> = [];
	public var noteTypeScriptsArray:Array<FunkinScript> = []; // to avoid stupid for loop shit on maps, for convienience really

	public var eventScripts:Map<String, FunkinScript> = [];
	public var eventScriptsArray:Array<FunkinScript> = []; // to avoid stupid for loop shit on maps, for convienience really
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
			if(instPath.startsWith('${Paths.CONTENT_DIRECTORY}/'))
				Paths.forceMod = instPath.split("/")[1];
		}
		if(lastParams._chart != null) {
			currentChart = lastParams._chart;
			lastParams._chart = null; // this is only useful for changing difficulties mid song, so we don't need to keep this value
		} else
			currentChart = ChartData.load(currentSong, currentMix, Paths.forceMod);

		chartingMode = lastParams.chartingMode ?? false;
		
		FlxG.sound.playMusic(instPath, 0, false);
		inst = FlxG.sound.music;

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

		camGame = new FunkinCamera();
		camGame.bgColor = 0;
		FlxG.cameras.reset(camGame);

		camHUD = new FunkinCamera();
		camHUD.bgColor = 0;
		FlxG.cameras.add(camHUD, false);

		Conductor.instance.music = null;
		Conductor.instance.offset = Options.songOffset + inst.latency;
		Conductor.instance.autoIncrement = true;
		
		Conductor.instance.reset(currentChart.meta.song.timingPoints.first()?.bpm ?? 100.0);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);
		
		Conductor.instance.time = -((Conductor.instance.beatLength * 4) + Conductor.instance.offset);

		inst.pause();
		inst.volume = 1;
		inst.onComplete = finishSong;

		WindowUtil.titlePrefix = (lastParams._unsaved) ? "* " : "";
		WindowUtil.titleSuffix = (chartingMode) ? " - Chart Playtesting" : "";

		stage = new Stage(currentChart.meta.game.stage, {
			spectator: new Character(currentChart.meta.game.getCharacter("spectator"), false),
			opponent: new Character(currentChart.meta.game.getCharacter("opponent"), false),
			player: new Character(currentChart.meta.game.getCharacter("player"), true)
		});
		camGame.zoom = stage.data.zoom;
		add(stage);

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
		for(i in 0...loaders.length) {
			addScripts(loaders[i], 'gameplay/songs/${currentSong}/${currentMix}/scripts'); // load from specific song and specific mix first
			addScripts(loaders[i], 'gameplay/songs/${currentSong}/scripts'); // then load from specific song, regardless of mix
			addScripts(loaders[i], "gameplay/scripts"); // then load any gameplay script
		}
		if(stage.script != null)
			scripts.add(stage.script);

		for(note in currentChart.notes.get(currentDifficulty)) {
			if(noteTypeScripts.exists(note.type))
				continue;

			final scriptPath:String = Paths.script('gameplay/notetypes/${note.type}');
			if(!FlxG.assets.exists(scriptPath))
				continue;

			final script:FunkinScript = FunkinScript.fromFile(scriptPath);
			script.set("NOTE_TYPE_ID", note.type);
			scripts.add(script);

			noteTypeScripts.set(note.type, script);
			noteTypeScriptsArray.push(script);
		}
		eventRunner = new EventRunner(currentChart.events);
		eventRunner.onExecute.add(onEvent);
		eventRunner.onExecutePost.add(onEventPost);
		add(eventRunner);

		for(e in eventRunner.events.filter((i) -> i.type == "Camera Pan")) {
			if(e.time > 10)
				break;

			eventRunner.execute(e);
		}
		for(b in eventRunner.behaviors) {
			if(b is ScriptedEventBehavior) {
				final sb:ScriptedEventBehavior = cast b;
				if(sb.script != null) {
					scripts.add(sb.script);
	
					eventScripts.set(sb.eventType, sb.script);
					eventScriptsArray.push(sb.script);
				}
			}
		}
		final leScripts:Array<FunkinScript> = scripts.members.copy();
		for(i in 0...leScripts.length) {
			leScripts[i].execute();
			leScripts[i].call("onCreate");
		}
		#end

		spectator = stage.characters.spectator;
		opponent = stage.characters.opponent;
		player = stage.characters.player;

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.05);
		camGame.snapToTarget();

		playField = new PlayField(currentChart, currentDifficulty);

		playField.onNoteHit.add(onNoteHit);
		playField.onNoteHitPost.add(onNoteHitPost);

		playField.onNoteMiss.add(onNoteMiss);
		playField.onNoteMissPost.add(onNoteMissPost);

		playField.cameras = [camHUD];
		add(playField);
		
		var event:HUDGenerationEvent = cast Events.get(HUD_GENERATION);
		event = event.recycle(Options.hudType);

		#if SCRIPTING_ALLOWED
		event = scripts.event("onHUDGeneration", event.recycle(Options.hudType));
		#end
		switch(event.hudType) {
			case "Classic":
				playField.hud = new ClassicHUD(playField);
				
			default:
				#if SCRIPTING_ALLOWED
				playField.hud = new ScriptedHUD(playField, event.hudType);
				#else
				playField.hud = new ClassicHUD(playField);
				#end
		}
		playField.hud.cameras = [camHUD];
		add(playField.hud);

		#if SCRIPTING_ALLOWED
		if(playField.hud is ScriptedHUD) {
			final hud:ScriptedHUD = cast playField.hud;
			scripts.add(hud.script);

			hud.script.setParent(hud);
			hud.script.call("onCreate");
		}
		#end
		
		#if SCRIPTING_ALLOWED
		scripts.call("onCreatePost");
		#end
	}

	override function update(elapsed:Float) {
		#if SCRIPTING_ALLOWED
		scripts.call("onUpdate", [elapsed]);
		#end
		if(startingSong && Conductor.instance.time >= -Conductor.instance.offset)
			startSong();

		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.END) {
			// TODO: warning for unsaved charts
			endSong(); // end the song immediately when SHIFT + END is pressed, as emergency
		}

		if(controls.justPressed.DEBUG) {
			FlxG.switchState(ChartEditor.new.bind({
				song: currentSong,
				difficulty: currentDifficulty,
				mix: currentMix,
				mod: lastParams.mod,

				_chart: currentChart,
				_unsaved: lastParams._unsaved
			}));
		}
		camGame.extraZoom = FlxMath.lerp(camGame.extraZoom, 0.0, FlxMath.getElapsedLerp(0.05, elapsed));
		camHUD.extraZoom = FlxMath.lerp(camHUD.extraZoom, 0.0, FlxMath.getElapsedLerp(0.05, elapsed));

		if(player._holdingPose && player.holdTimer <= 0 && !playField.strumsPressed.contains(true))
			player._holdingPose = false;
		
		final cameraPos:FlxPoint = FlxPoint.get();
		switch(curCameraTarget) {
			case OPPONENT:
				opponent.getCameraPosition(cameraPos);

			case PLAYER:
				player.getCameraPosition(cameraPos);

			case SPECTATOR:
				spectator.getCameraPosition(cameraPos);
		}
		var event:CameraMoveEvent = cast Events.get(CAMERA_MOVE);
		event.recycle(cameraPos);
		#if SCRIPTING_ALLOWED
		event = scripts.event("onCameraMove", event);
		#end
		if(!event.cancelled)
			camFollow.setPosition(event.position.x, event.position.y);
		
		cameraPos.put();
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

		Conductor.instance.time = -Conductor.instance.offset;
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
		final isPlayer:Bool = event.note.strumLine == playField.playerStrumLine;
		if(isPlayer)
			event.character = player;
		else
			event.character = opponent;
		
		#if SCRIPTING_ALLOWED
		final excludedScripts:Array<FunkinScript> = noteTypeScriptsArray.concat(eventScriptsArray);
		scripts.event("onNoteHit", event, excludedScripts);
		scripts.event((isPlayer) ? "onPlayerNoteHit" : "onOpponentNoteHit", event, excludedScripts);
		scripts.event((isPlayer) ? "onPlayerHit" : "onOpponentHit", event, excludedScripts);
		scripts.event((isPlayer) ? "goodNoteHit" : "dadNoteHit", event, excludedScripts);

		final noteTypeScript:FunkinScript = noteTypeScripts.get(event.noteType);
		if(noteTypeScript != null) {
			noteTypeScript.call("onNoteHit", [event]);
			noteTypeScript.call((isPlayer) ? "onPlayerNoteHit" : "onOpponentNoteHit", [event]);
			noteTypeScript.call((isPlayer) ? "onPlayerHit" : "onOpponentHit", [event]);
			noteTypeScript.call((isPlayer) ? "goodNoteHit" : "dadNoteHit", [event]);
		}
		#end
		if(event.cancelled)
			return;
		
		if(event.unmuteVocals && !vocals.isSingleTrack) {
			if(isPlayer) {
				if(vocals.player != null)
					vocals.player.muted = false;
			} else {
				if(vocals.opponent != null)
					vocals.opponent.muted = false;
			}
		}
		if(event.playSingAnim) {
			event.character.playSingAnim(event.direction, event.singAnimSuffix, true);
			event.character.holdTimer += event.length;
			event.character._holdingPose = isPlayer;
		}
	}

	private function onNoteHitPost(event:NoteHitEvent):Void {
		final isPlayer:Bool = event.note.strumLine == playField.playerStrumLine;
		#if SCRIPTING_ALLOWED
		final excludedScripts:Array<FunkinScript> = noteTypeScriptsArray.concat(eventScriptsArray);
		scripts.event("onNoteHitPost", event, excludedScripts);
		scripts.event((isPlayer) ? "onPlayerNoteHitPost" : "onOpponentNoteHitPost", event, excludedScripts);
		scripts.event((isPlayer) ? "onPlayerHitPost" : "onOpponentHitPost", event, excludedScripts);
		scripts.event((isPlayer) ? "goodNoteHitPost" : "dadNoteHitPost", event, excludedScripts);

		final noteTypeScript:FunkinScript = noteTypeScripts.get(event.noteType);
		if(noteTypeScript != null) {
			noteTypeScript.call("onNoteHit", [event]);
			noteTypeScript.call((isPlayer) ? "onPlayerNoteHit" : "onOpponentNoteHit", [event]);
			noteTypeScript.call((isPlayer) ? "onPlayerHit" : "onOpponentHit", [event]);
			noteTypeScript.call((isPlayer) ? "goodNoteHit" : "dadNoteHit", [event]);
		}
		#end
	}
	
	private function onNoteMiss(event:NoteMissEvent):Void {
		final isPlayer:Bool = event.note.strumLine == playField.playerStrumLine;
		if(isPlayer)
			event.character = player;
		else
			event.character = opponent;

		#if SCRIPTING_ALLOWED
		final excludedScripts:Array<FunkinScript> = noteTypeScriptsArray.concat(eventScriptsArray);
		scripts.event("onNoteMiss", event, excludedScripts);

		if(!isPlayer)
			scripts.event("onOpponentNoteMiss", event, excludedScripts);

		final noteTypeScript:FunkinScript = noteTypeScripts.get(event.noteType);
		if(noteTypeScript != null) {
			noteTypeScript.call("onNoteMiss", [event]);

			if(!isPlayer)
				noteTypeScript.call("onOpponentNoteMiss", [event]);
		}
		#end
		if(event.cancelled)
			return;
		
		if(event.muteVocals && !vocals.isSingleTrack) {
			if(isPlayer) {
				if(vocals.player != null)
					vocals.player.muted = true;
			} else {
				if(vocals.opponent != null)
					vocals.opponent.muted = true;
			}
		}
		if(event.playMissAnim) {
			event.character.playMissAnim(event.direction, event.missAnimSuffix, true);
			event.character._holdingPose = isPlayer;
		}
	}

	private function onNoteMissPost(event:NoteMissEvent):Void {
		final isPlayer:Bool = event.note.strumLine == playField.playerStrumLine;
		#if SCRIPTING_ALLOWED
		scripts.event("onNoteMissPost", event);
		scripts.event((isPlayer) ? "onPlayerNoteMissPost" : "onOpponentNoteMissPost", event);
		scripts.event((isPlayer) ? "onPlayerMissPost" : "onOpponentMissPost", event);
		scripts.event((isPlayer) ? "goodNoteMissPost" : "dadNoteMissPost", event);
		#end
	}

	private function onEvent(event:SongEvent):Void {
		#if SCRIPTING_ALLOWED
		scripts.call("onEvent", [event]);
		#end
	}

	private function onEventPost(event:SongEvent):Void {
		#if SCRIPTING_ALLOWED
		scripts.call("onEventPost", [event]);
		#end
	}

	override function stepHit(step:Int):Void {
		#if SCRIPTING_ALLOWED
		scripts.call("onStepHit", [step]);
		#end
	}

	override function beatHit(beat:Int):Void {
		var interval:Int = camZoomingInterval;
		if(interval < 0)
			interval = Conductor.instance.timeSignature.getNumerator();

		@:privateAccess
		final timingPoint:TimingPoint = Conductor.instance._latestTimingPoint;
		
		if(interval > 0 && beat > 0 && Math.floor(Conductor.instance.curDecBeat - timingPoint.beat) % interval == 0) {
			camGame.extraZoom += 0.015 * camZoomingIntensity;
			camHUD.extraZoom += 0.03 * camZoomingIntensity;
		}
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

		Conductor.instance.music = null;
		Conductor.instance.offset = 0;
		
		WindowUtil.resetTitle();
		WindowUtil.resetTitleAffixes();

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

	var ?chartingMode:Bool;

	@:noCompletion
	var ?_chart:ChartData;

	@:noCompletion
	var ?_unsaved:Bool;
}