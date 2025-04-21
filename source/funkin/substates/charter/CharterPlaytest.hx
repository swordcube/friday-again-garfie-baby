package funkin.substates.charter;

import flixel.sound.FlxSound;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.VocalGroup;

import funkin.gameplay.PlayField;
import funkin.gameplay.Countdown;
import funkin.gameplay.hud.ClassicHUD;

class CharterPlaytest extends FunkinSubState {
    public static var lastParams:CharterPlaytestParams;

    public var bg:FlxSprite;

    public var inst:FlxSound;
    public var vocals:VocalGroup;

    public var conductor:Conductor;

    public var currentSong:String;
	public var currentDifficulty:String;
	public var currentMix:String;

    public var currentChart:ChartData;
    public var playField:PlayField;

    public var startingSong:Bool = true;
    public var lastMouseVisible:Bool = false;

    public var countdown:Countdown;

    public function new(?params:CharterPlaytestParams) {
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
    
    override function create():Void {
        super.create();

        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = false;

        FlxG.sound.acceptInputs = true;
        currentChart = lastParams.chart;

        final instPath:String = Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/inst');
		inst = FlxG.sound.play(instPath, 0, false);

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
        
        conductor = new Conductor();
        conductor.autoIncrement = true;
        conductor.dispatchToStates = true;

        conductor.reset(currentChart.meta.song.timingPoints.first()?.bpm ?? 100.0);
        conductor.setupTimingPoints(currentChart.meta.song.timingPoints);

        conductor.time = (lastParams?.startTime ?? 0.0) - (conductor.beatLength * 5);
        conductor.offset = Options.songOffset + inst.latency;
        add(conductor);

        inst.pause();
        inst.onComplete = close;

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        bg.color = 0xFF4CAF50;
        bg.screenCenter();
        bg.scrollFactor.set();
        add(bg);

        playField = new PlayField(currentChart, currentDifficulty, Constants.DEFAULT_NOTE_SKIN, Constants.DEFAULT_UI_SKIN);
        playField.attachedConductor = conductor;

        if(lastParams.startTime != null && lastParams.startTime > 0)
            playField.noteSpawner.skipToTime(lastParams.startTime);

        add(playField);

        playField.hud = new ClassicHUD(playField);
        add(playField.hud);

        countdown = new Countdown();
        countdown.start(Constants.DEFAULT_UI_SKIN, conductor);
		add(countdown);

        WindowUtil.titleSuffix = " - Chart Playtesting";
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if(startingSong && conductor.time >= (lastParams?.startTime ?? 0.0) - conductor.offset)
            startSong();

        if(controls.justPressed.BACK)
            close();
    }

    public function startSong():Void {
        if(!startingSong)
            return;

        if(lastParams.startTime != null && lastParams.startTime > 0)
            conductor.time = lastParams.startTime;
        else
            conductor.time = -conductor.offset;

        inst.time = conductor.rawTime;
        inst.volume = 1;
        inst.resume();
        
        vocals.seek(inst.time);
        vocals.play();
        
        conductor.music = inst;
        startingSong = false;
    }
    
    override function destroy():Void {
        FlxG.mouse.visible = lastMouseVisible;
        WindowUtil.titleSuffix = " - Chart Editor";

        FlxG.cameras.remove(camera);
        inst = FlxDestroyUtil.destroy(inst);
        super.destroy();
    }
}

typedef CharterPlaytestParams = {
    var chart:ChartData;
    
	var song:String;
	var difficulty:String;

	/**
	 * Equivalent to song variants in V-Slice
	 */
	var ?mix:String;

    var ?startTime:Float;
}