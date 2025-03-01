package funkin.states.editors;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import funkin.backend.Main;

import funkin.ui.*;
import funkin.ui.topbar.*;
import funkin.ui.charter.*;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.VocalGroup;

// TODO: play bar
// TODO: undos & redos
// TODO: click and drag selection box thingie

// TODO: have some way to place events
// TODO: have some way to place timing points

// TODO: waveforms or whatever the fuck you're supposed to call them

class ChartEditor extends FunkinState {
    public static final CELL_SIZE:Int = 40;
    public static final ALL_GRID_SNAPS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192];

    public static var editorSettings:ChartEditorSettings = {};

    public var currentSong:String;
	public var currentDifficulty:String;
	public var currentMix:String;

    public var currentChart:ChartData;

    public var inst:FlxSound;
    public var vocals:VocalGroup;

    public var selectedObjects:Array<ChartEditorObject> = [];
    
    // note layer

    public var bg:FlxSprite;
    public var grid:FlxBackdrop;

    public var topCover:FlxSprite;
    public var bottomCover:FlxSprite;
    
    public var beatSeparators:FlxSpriteContainer;
    public var measureSeparators:FlxSpriteContainer;

    public var noteRenderer:CharterNoteRenderer;

    public var opponentStrumLine:CharterStrumLine;
    public var playerStrumLine:CharterStrumLine;

    public var strumLine:FlxSprite; // this will actually be a line 💥

    // ui layer

    public var curNoteType:Int = 0;
    public var noteTypes:Array<String> = ["Default"];

    public var uiCam:FlxCamera;
    public var uiLayer:FlxContainer;

    public var topBar:CharterTopBar;

    public function new(params:ChartEditorParams) {
        super();

        currentSong = params.song;
        currentDifficulty = params.difficulty;
        currentMix = params.mix;

        _params = params;
    }

    override function create() {
        if(FlxG.sound.music != null)
            FlxG.sound.music.stop();

        final instPath:String = Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/inst');
		if(_params.mod != null && _params.mod.length > 0)
			Paths.forceMod = _params.mod;
		else {
            if(instPath.startsWith('${ModManager.MOD_DIRECTORY}/'))
				Paths.forceMod = instPath.split("/")[1];
            else
                Paths.forceMod = _params.mod;
		}
		if(_params._chart != null) {
			currentChart = _params._chart;
			_params._chart = null; // this is only useful for reloading charts, so we don't need to keep this value
		} else
            currentChart = ChartData.load(currentSong, currentMix, Paths.forceMod);
		
        Conductor.instance.time = 0;
        Conductor.instance.offset = 0;
        
        Conductor.instance.autoIncrement = false;
        Conductor.instance.hasMetronome = editorSettings.metronome;

        Conductor.instance.reset(currentChart.meta.song.bpm);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);

        FlxG.sound.playMusic(instPath, 0, false);
		
        inst = FlxG.sound.music;
        inst.onComplete = () -> {
            inst.time = inst.length;
            Conductor.instance.music = null;
            Conductor.instance.time = inst.length;
        }
        Conductor.instance.music = inst;

        inst.pause();
        inst.time = 0;
        inst.volume = 1;

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

        if(vocals.spectator != null)
            vocals.spectator.muted = editorSettings.muteSpectatorVocals;

        if(vocals.opponent != null)
            vocals.opponent.muted = editorSettings.muteOpponentVocals;

        if(vocals.player != null)
            vocals.player.muted = editorSettings.mutePlayerVocals;

        // note layer

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        bg.scale.set(1.1, 1.1);
        bg.updateHitbox();
        bg.screenCenter();
        bg.alpha = 0.1;
        bg.scrollFactor.set(0, 0);
        add(bg);

        final gridBitmap:BitmapData = _createGridBitmap();
        grid = new FlxBackdrop(gridBitmap, Y);
        grid.screenCenter(X);
        grid.scrollFactor.x = 0;
        add(grid);

        beatSeparators = new FlxSpriteContainer();
        add(beatSeparators);

        measureSeparators = new FlxSpriteContainer();
        add(measureSeparators);

        var curBeat:Int = -16;
        var curMeasure:Int = -16;

        final endBeat:Int = Std.int(Conductor.instance.getBeatAtTime(inst.length)) + 16;
        final endMeasure:Int = Std.int(Conductor.instance.getMeasureAtTime(inst.length)) + 16;

        while(curBeat < endBeat) {
            final beatTime:Float = Conductor.instance.getTimeAtBeat(curBeat);
            measureSeparators.add(new FlxSprite(grid.x, grid.y + (CELL_SIZE * Conductor.instance.getStepAtTime(beatTime))).makeSolid(gridBitmap.width, 1, FlxColor.WHITE));
            curBeat++;
        }
        while(curMeasure < endMeasure) {
            final measureTime:Float = Conductor.instance.getTimeAtMeasure(curMeasure);
            measureSeparators.add(new FlxSprite(grid.x, grid.y + (CELL_SIZE * Conductor.instance.getStepAtTime(measureTime))).makeSolid(gridBitmap.width, 4, FlxColor.WHITE));
            curMeasure++;
        }
        topCover = new FlxSprite(grid.x, grid.y).makeSolid(gridBitmap.width, FlxG.height * 1.5, FlxColor.BLACK);
        topCover.y -= topCover.height;
        topCover.scrollFactor.x = 0;
        topCover.alpha = 0.5;
        add(topCover);
        
        final endStep:Float = Conductor.instance.getStepAtTime(inst.length);
        bottomCover = new FlxSprite(grid.x, grid.y).makeSolid(gridBitmap.width, FlxG.height * 1.5, FlxColor.BLACK);
        bottomCover.y = CELL_SIZE * endStep;
        bottomCover.scrollFactor.x = 0;
        bottomCover.alpha = 0.5;
        add(bottomCover);

        opponentStrumLine = new CharterStrumLine(0, 75);
        opponentStrumLine.screenCenter();
        opponentStrumLine.x -= ((CELL_SIZE * opponentStrumLine.keyCount) / 2) + 1;
        opponentStrumLine.y += CELL_SIZE * 0.5;
        add(opponentStrumLine);
        
        playerStrumLine = new CharterStrumLine(0, 75);
        playerStrumLine.screenCenter();
        playerStrumLine.x += ((CELL_SIZE * opponentStrumLine.keyCount) / 2) + 1;
        playerStrumLine.y += CELL_SIZE * 0.5;
        add(playerStrumLine);
        
        final rawNotes:Array<NoteData> = currentChart.notes.get(currentDifficulty);
        noteRenderer = new CharterNoteRenderer(grid.x, grid.y);

        noteRenderer.onEmptyCellClick.add(addNoteOnCursor);
        noteRenderer.onNoteClick.add((n) -> selectObjects([CNote(n)]));
        noteRenderer.onNoteRightClick.add((n) -> deleteObjects([CNote(n)]));

        noteRenderer.onNoteHit.add((note:ChartEditorNote) -> {
            if(!inst.playing)
                return;

            if(note.data.direction < Constants.KEY_COUNT) {
                opponentStrumLine.glowStrum(note.data.direction % Constants.KEY_COUNT, Math.max(note.data.length, Conductor.instance.stepLength));
                if(editorSettings.opponentHitsounds)
                    FlxG.sound.play(Paths.sound('editors/charter/sfx/hitsound'));
            }
            else {
                playerStrumLine.glowStrum(note.data.direction % Constants.KEY_COUNT, Math.max(note.data.length, Conductor.instance.stepLength));
                if(editorSettings.playerHitsounds)
                    FlxG.sound.play(Paths.sound('editors/charter/sfx/hitsound'));
            }
        });
        add(noteRenderer);

        final opponentNotes:Array<NoteData> = rawNotes.filter((n) -> return n.direction < Constants.KEY_COUNT);
        opponentNotes.sort((a, b) -> Std.int(a.time - b.time));

        noteRenderer.opponentNotes = [for(n in opponentNotes) {
            final t = Conductor.instance.getTimingPointAtTime(n.time);
            final step = Conductor.instance.getStepAtTime(n.time, t);
            {
                data: n,
                step: Conductor.instance.getStepAtTime(n.time, t),
                stepLength: Conductor.instance.getStepAtTime(n.time + n.length, t) - step
            };
        }];
        final playerNotes:Array<NoteData> = rawNotes.filter((n) -> return n.direction > (Constants.KEY_COUNT - 1));
        playerNotes.sort((a, b) -> Std.int(a.time - b.time));
        
        noteRenderer.playerNotes = [for(n in playerNotes) {
            final t = Conductor.instance.getTimingPointAtTime(n.time);
            final step = Conductor.instance.getStepAtTime(n.time, t);
            {
                data: n,
                step: step,
                stepLength: Conductor.instance.getStepAtTime(n.time + n.length, t) - step
            };
        }];
        strumLine = new FlxSprite().makeSolid(gridBitmap.width, 4, FlxColor.WHITE);
        strumLine.screenCenter();
        strumLine.scrollFactor.set();
        add(strumLine);

        // ui layer

        uiCam = new FlxCamera();
        uiCam.bgColor = 0;
        FlxG.cameras.add(uiCam, false);

        uiLayer = new FlxContainer();
        uiLayer.cameras = [uiCam];
        add(uiLayer);

        topBar = new CharterTopBar();
        uiLayer.add(topBar);
        
        topBar.updateLeftSideItems();
        topBar.updateRightSideItems();

        // adjust a few lil things

        Main.statsDisplay.visible = false; // it gets in the way
        
        FlxG.mouse.visible = true;
        FlxG.camera.scroll.y -= FlxG.height * 0.5;
        
        super.create();
    }

    override function update(elapsed:Float) {
        final targetScrollY:Float = (CELL_SIZE * Conductor.instance.getStepAtTime(Conductor.instance.time)) - (FlxG.height * 0.5);
        if(inst.playing)
            FlxG.camera.scroll.y = targetScrollY;
        else {
            if(FlxG.mouse.wheel != 0) {
                final wheel:Float = -FlxG.mouse.wheel;
                if(wheel < 0)
                    goBackABeat();
                else
                    goForwardABeat();
            }
            if(FlxG.keys.justPressed.SHIFT && Math.abs(FlxG.camera.scroll.y - targetScrollY) < 20)
                FlxG.camera.scroll.y = targetScrollY;
            else
                FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, targetScrollY, FlxMath.getElapsedLerp(0.32, elapsed));
        }
        super.update(elapsed);
    }
    
    override function destroy():Void {
        Main.statsDisplay.visible = true;
        FlxG.mouse.visible = false;

        Conductor.instance.music = null;
        Conductor.instance.hasMetronome = false;
        
        Paths.forceMod = null;
        super.destroy();
    }

    public function playPause():Void {
        if(inst.playing) {
            opponentStrumLine.resetAllStrums();
            playerStrumLine.resetAllStrums();
            
            vocals.pause();
            inst.pause();

            Conductor.instance.music = null;
        }
        else {
            if(noteRenderer.opponentNotes.length != 0) {
                if(Conductor.instance.time <= 0)
                    noteRenderer.opponentNotes[0].wasHit = false;
            }
            if(noteRenderer.playerNotes.length != 0) {
                if(Conductor.instance.time <= 0)
                    noteRenderer.playerNotes[0].wasHit = false;
            }
            Conductor.instance.music = inst;
            inst.time = FlxMath.bound(Conductor.instance.time, 0, inst.length);
            vocals.seek(inst.time);
            
            vocals.play();
            inst.play();
        }
    }

    public function goBackABeat():Void {
        if(inst.playing)
            return;

        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtBeat(Math.floor(Conductor.instance.getBeatAtTime(Conductor.instance.time)) - 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goBackAMeasure():Void {
        if(inst.playing)
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtMeasure(Math.floor(Conductor.instance.getMeasureAtTime(Conductor.instance.time)) - 1), 0, inst.length);
        seekToTime(newTime);
    }
    
    public function goForwardABeat():Void {
        if(inst.playing)
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtBeat(Math.floor(Conductor.instance.getBeatAtTime(Conductor.instance.time)) + 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goForwardAMeasure():Void {
        if(inst.playing)
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtMeasure(Math.floor(Conductor.instance.getMeasureAtTime(Conductor.instance.time)) + 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goBackToStart():Void {
        if(inst.playing)
            return;

        seekToTime(0);
    }

    public function goToEnd():Void {
        if(inst.playing)
            return;

        seekToTime(inst.length);
    }
    
    public inline function seekToTime(newTime:Float):Void {
        inst.time = newTime;
        vocals.seek(newTime);
        Conductor.instance.time = newTime;
    }

    public function addObjects(objects:Array<ChartEditorObject>):Void {
        for(object in objects) {
            switch(object) {
                case CNote(note):
                    final rawNotes:Array<NoteData> = currentChart.notes.get(currentDifficulty);
                    rawNotes.push(note.data);
    
                    final notes:Array<ChartEditorNote> = (note.data.direction < Constants.KEY_COUNT) ? noteRenderer.opponentNotes : noteRenderer.playerNotes;
                    notes.push(note);
                    notes.sort((a, b) -> Std.int(a.data.time - b.data.time));
    
                case CEvent(event):
                    // TODO:
            }
        }
        selectObjects(objects);
    }

    public function addNoteOnCursor():Void {
        final snapMult:Float = ChartEditor.CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final newStep:Float = ((FlxG.keys.pressed.SHIFT) ? FlxG.mouse.y : Math.floor(FlxG.mouse.y / snapMult) * snapMult) / CELL_SIZE;
        if(newStep < 0)
            return;

        addObjects([CNote({
            data: {
                time: Conductor.instance.getTimeAtStep(newStep),
                direction: Math.floor((FlxG.mouse.x - grid.x) / ChartEditor.CELL_SIZE),
                length: 0,
                type: noteTypes[curNoteType]
            },
            step: newStep,
            stepLength: 0
        })]);
    }

    public function selectObjects(objects:Array<ChartEditorObject>):Void {
        for(object in selectedObjects) {
            switch(object) {
                case CNote(note): note.selected = false;
                case CEvent(event): event.selected = false;
            }
        }
        for(object in objects) {
            switch(object) {
                case CNote(note): note.selected = true;
                case CEvent(event): event.selected = true;
            }
        }
        selectedObjects = objects.copy();
    }

    public function deleteObjects(objects:Array<ChartEditorObject>):Void {
        for(object in objects) {
            switch(object) {
                case CNote(note):
                    final rawNotes:Array<NoteData> = currentChart.notes.get(currentDifficulty);
                    rawNotes.remove(note.data);
            
                    final notes:Array<ChartEditorNote> = (note.data.direction < Constants.KEY_COUNT) ? noteRenderer.opponentNotes : noteRenderer.playerNotes;
                    notes.remove(note);

                case CEvent(event):
                    // TODO
            }
        }
        selectObjects([]);
    }

    public function addSustainLength(objects:Array<ChartEditorObject>):Void {
        for(object in objects) {
            switch(object) {
                case CNote(note):
                    final t = Conductor.instance.getTimingPointAtTime(note.data.time);
                    note.data.length = Math.max(note.data.length + t.getStepLength(), 0);
                    note.stepLength = Math.max(note.stepLength + 1, 0);

                default:
            }
        }
    }

    public function subtractSustainLength(objects:Array<ChartEditorObject>):Void {
        for(object in objects) {
            switch(object) {
                case CNote(note):
                    final t = Conductor.instance.getTimingPointAtTime(note.data.time);
                    note.data.length = Math.max(note.data.length - (t.getStepLength() * 1000), 0);
                    note.stepLength = Math.max(note.stepLength - 1, 0);

                default:
            }
        }
    }

    public function setGridSnap(snap:Int):Void {
        editorSettings.gridSnap = snap;
        topBar.updateRightSideItems();
    }

    public function increaseGridSnap():Void {
        var index:Int = ALL_GRID_SNAPS.indexOf(editorSettings.gridSnap);
        index = FlxMath.wrap(index + 1, 0, ALL_GRID_SNAPS.length - 1);
        setGridSnap(ALL_GRID_SNAPS[index]);
    }

    public function decreaseGridSnap():Void {
        var index:Int = ALL_GRID_SNAPS.indexOf(editorSettings.gridSnap);
        index = FlxMath.wrap(index - 1, 0, ALL_GRID_SNAPS.length - 1);
        setGridSnap(ALL_GRID_SNAPS[index]);
    }

    public function toggleMetronome(value:Bool):Void {
        editorSettings.metronome = value;
        Conductor.instance.hasMetronome = editorSettings.metronome;
    }

    public function toggleInstrumental(value:Bool):Void {
        editorSettings.muteInstrumental = value;
        inst.muted = editorSettings.muteInstrumental;
    }

    public function toggleAllVocals(value:Bool):Void {
        editorSettings.muteAllVocals = value;
        if(vocals.spectator != null)
            vocals.spectator.muted = editorSettings.muteAllVocals || editorSettings.muteSpectatorVocals;
        
        if(vocals.opponent != null)
            vocals.opponent.muted = editorSettings.muteAllVocals || editorSettings.muteOpponentVocals;
        
        if(vocals.player != null)
            vocals.player.muted = editorSettings.muteAllVocals || editorSettings.mutePlayerVocals;
    }

    public function toggleSpectatorVocals(value:Bool):Void {
        editorSettings.muteSpectatorVocals = value;
        if(vocals.spectator != null)
            vocals.spectator.muted = editorSettings.muteAllVocals || editorSettings.muteSpectatorVocals;
    }

    public function toggleOpponentVocals(value:Bool):Void {
        editorSettings.muteOpponentVocals = value;
        if(vocals.opponent != null)
            vocals.opponent.muted = editorSettings.muteAllVocals || editorSettings.muteOpponentVocals;
    }

    public function togglePlayerVocals(value:Bool):Void {
        editorSettings.mutePlayerVocals = value;
        if(vocals.player != null)
            vocals.player.muted = editorSettings.muteAllVocals || editorSettings.mutePlayerVocals;
    }

    //----------- [ Private API ] -----------//

    private var _params:ChartEditorParams;

    private function _createGridBitmap():BitmapData {
        final gridBitmap:BitmapData = FlxGridOverlay.createGrid(
            CELL_SIZE, CELL_SIZE,
            CELL_SIZE * Constants.KEY_COUNT * 2, CELL_SIZE * 4,
            true, 0xFF4e4e4e, 0xFF252525
        );
        gridBitmap.lock();

        gridBitmap.fillRect(new Rectangle(0, 0, 1, gridBitmap.height), 0xFFDDDDDD);
        gridBitmap.fillRect(new Rectangle(Std.int(gridBitmap.width * 0.5) - 1, 0, 1, gridBitmap.height), 0xFFDDDDDD);
        gridBitmap.fillRect(new Rectangle(gridBitmap.width - 1, 0, 1, gridBitmap.height), 0xFFDDDDDD);

        gridBitmap.unlock();
        return gridBitmap;
    }
}

typedef ChartEditorParams = {
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

@:structInit
class ChartEditorSettings {
    public var opponentHitsounds:Bool = true;
    public var playerHitsounds:Bool = true;

    public var gridSnap:Int = 16;
    public var metronome:Bool = false;

    public var muteInstrumental:Bool = false;
    public var muteAllVocals:Bool = false;

    public var muteSpectatorVocals:Bool = false;
    public var muteOpponentVocals:Bool = false;
    public var mutePlayerVocals:Bool = false;
}

@:structInit
class ChartEditorNote {
    public var data:NoteData;

    public var step:Float;
    public var stepLength:Float;
    
    public var wasHit:Bool = false;
    public var selected:Bool = false;
}

@:structInit
class ChartEditorEvent {
    public var data:EventData;
    public var selected:Bool = false;
}

enum ChartEditorObject {
    CNote(note:ChartEditorNote);
    CEvent(event:ChartEditorEvent);
}

enum ChartEditorChange {
    CCutObjects(objects:Array<ChartEditorObject>);
    CPasteObjects(objects:Array<ChartEditorObject>);
    
    CMoveObjects(objects:Array<ChartEditorObject>);
    CSelectObjects(objects:Array<ChartEditorObject>);

    CAddObject(object:ChartEditorObject);
    CRemoveObject(object:ChartEditorObject);
}