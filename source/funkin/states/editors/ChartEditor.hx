package funkin.states.editors;

import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import funkin.backend.Main;

import funkin.ui.*;
import funkin.ui.panel.*;
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

@:allow(funkin.ui.charter.CharterNoteRenderer)
class ChartEditor extends FunkinState {
    public static final CELL_SIZE:Int = 40;
    public static final ALL_GRID_SNAPS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192];

    public static var lastParams:ChartEditorParams = {
        song: "bopeebo",
        difficulty: "hard"
    };
    public static var editorSettings:ChartEditorSettings = {};

    public var currentSong:String;
	public var currentDifficulty:String;
	public var currentMix:String;

    public var currentChart:ChartData;
    public var rawNotes:Array<NoteData>;

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
    public var selectionBox:SelectionPanel;

    public var opponentStrumLine:CharterStrumLine;
    public var playerStrumLine:CharterStrumLine;

    public var strumLine:FlxSprite; // this will actually be a line 💥
    public var noteCam:FlxCamera;

    // ui layer

    public var curNoteType:Int = 0;
    public var noteTypes:Array<String> = ["Default"];

    public var uiCam:FlxCamera;
    public var uiLayer:FlxContainer;

    public var topBar:CharterTopBar;

    public function new(params:ChartEditorParams) {
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
        if(FlxG.sound.music != null)
            FlxG.sound.music.stop();

        final instPath:String = Paths.sound('gameplay/songs/${currentSong}/${currentMix}/music/inst');
		if(lastParams.mod != null && lastParams.mod.length > 0)
			Paths.forceMod = lastParams.mod;
		else {
            if(instPath.startsWith('${ModManager.MOD_DIRECTORY}/'))
				Paths.forceMod = instPath.split("/")[1];
            else
                Paths.forceMod = lastParams.mod;
		}
		if(lastParams._chart != null)
			currentChart = lastParams._chart;
		else
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

        noteCam = new FlxCamera();
        noteCam.bgColor = 0;
        FlxG.cameras.add(noteCam, false);

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
        grid.cameras = [noteCam];
        add(grid);

        beatSeparators = new FlxSpriteContainer();
        beatSeparators.cameras = [noteCam];
        add(beatSeparators);

        measureSeparators = new FlxSpriteContainer();
        measureSeparators.cameras = [noteCam];
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
        topCover.cameras = [noteCam];
        add(topCover);
        
        final endStep:Float = Conductor.instance.getStepAtTime(inst.length);
        bottomCover = new FlxSprite(grid.x, grid.y).makeSolid(gridBitmap.width, FlxG.height * 1.5, FlxColor.BLACK);
        bottomCover.y = CELL_SIZE * endStep;
        bottomCover.scrollFactor.x = 0;
        bottomCover.alpha = 0.5;
        bottomCover.cameras = [noteCam];
        add(bottomCover);

        opponentStrumLine = new CharterStrumLine(0, 75);
        opponentStrumLine.screenCenter();
        opponentStrumLine.x -= ((CELL_SIZE * opponentStrumLine.keyCount) / 2) + 1;
        opponentStrumLine.y += CELL_SIZE * 0.5;
        opponentStrumLine.cameras = [noteCam];
        add(opponentStrumLine);
        
        playerStrumLine = new CharterStrumLine(0, 75);
        playerStrumLine.screenCenter();
        playerStrumLine.x += ((CELL_SIZE * opponentStrumLine.keyCount) / 2) + 1;
        playerStrumLine.y += CELL_SIZE * 0.5;
        playerStrumLine.cameras = [noteCam];
        add(playerStrumLine);
        
        rawNotes = currentChart.notes.get(currentDifficulty);
        rawNotes.sort((a, b) -> Std.int(a.time - b.time));

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
        noteRenderer.notes = [for(n in rawNotes) {
            final t = Conductor.instance.getTimingPointAtTime(n.time);
            final step = Conductor.instance.getStepAtTime(n.time, t);
            {
                data: n,
                step: Conductor.instance.getStepAtTime(n.time, t),
                stepLength: Conductor.instance.getStepAtTime(n.time + n.length, t) - step
            };
        }];
        noteRenderer.cameras = [noteCam];
        add(noteRenderer);
        
        strumLine = new FlxSprite().makeSolid(gridBitmap.width, 4, FlxColor.WHITE);
        strumLine.screenCenter();
        strumLine.scrollFactor.set();
        strumLine.cameras = [noteCam];
        add(strumLine);

        selectionBox = new SelectionPanel(0, 0, 16, 16);
        selectionBox.kill();
        selectionBox.cameras = [noteCam];
        add(selectionBox);

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

        FlxG.mouse.visible = true;
        Main.statsDisplay.visible = false; // it gets in the way
        
        noteCam.zoom = editorSettings.gridZoom;
        noteCam.scroll.y -= FlxG.height * 0.5;
        
        super.create();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        FlxG.mouse.getWorldPosition(noteCam, _mousePos);
        noteCam.zoom = FlxMath.lerp(noteCam.zoom, editorSettings.gridZoom, FlxMath.getElapsedLerp(0.32, elapsed));

        if(Conductor.instance.time >= inst.length)
            Conductor.instance.time = inst.length;

        final targetScrollY:Float = (CELL_SIZE * Conductor.instance.getStepAtTime(Conductor.instance.time)) - (FlxG.height * 0.5);
        if(inst.playing)
            noteCam.scroll.y = targetScrollY;
        else {
            if(FlxG.mouse.wheel != 0) {
                final wheel:Float = -FlxG.mouse.wheel;
                if(wheel < 0)
                    goBackABeat();
                else
                    goForwardABeat();
            }
            if(FlxG.keys.justPressed.SHIFT && Math.abs(noteCam.scroll.y - targetScrollY) < 20)
                noteCam.scroll.y = targetScrollY;
            else
                noteCam.scroll.y = FlxMath.lerp(noteCam.scroll.y, targetScrollY, FlxMath.getElapsedLerp(0.32, elapsed));
        }
        if(!noteRenderer._movingObjects) {
            if(FlxG.mouse.pressed) {
                if(FlxG.mouse.justMoved && !selectionBox.exists) {
                    FlxG.mouse.getWorldPosition(noteCam, _lastMousePos);
                    selectionBox.revive();
                }
                if(selectionBox.exists) {
                    final newWidth:Float = (_mousePos.x - _lastMousePos.x);
                    final newHeight:Float = (_mousePos.y - _lastMousePos.y);
                    
                    final newWidthAbs:Float = Math.abs(newWidth);
                    final newHeightAbs:Float = Math.abs(newHeight);
                    
                    if(newWidthAbs > 5 && newHeightAbs > 5) {
                        if(newWidthAbs != selectionBox.width)
                            selectionBox.width = newWidthAbs;
            
                        if(newHeightAbs != selectionBox.height)
                            selectionBox.height = newHeightAbs;
                        
                        selectionBox.setPosition(_lastMousePos.x, _lastMousePos.y);
                        if(newWidth < 0)
                            selectionBox.x -= newWidthAbs;
            
                        if(newHeight < 0)
                            selectionBox.y -= newHeightAbs;
                    }
                    selectionBox.visible = (newWidthAbs > 5 && newHeightAbs > 5);
                }
            }
            else if(FlxG.mouse.justReleased) {
                if(selectionBox.exists) {
                    var selected:Array<ChartEditorObject> = noteRenderer.checkSelection();
                    selectObjects(selected);
        
                    FlxTimer.wait(0.001, () -> selectionBox.kill());
                } else {
                    final direction:Int = Math.floor((_mousePos.x - noteRenderer.x) / CELL_SIZE);
                    if(direction < 0 || direction >= (Constants.KEY_COUNT * 2))
                        selectObjects([]);
                }
            }
        }
    }
    
    override function destroy():Void {
        _mousePos = FlxDestroyUtil.put(_mousePos);
        _lastMousePos = FlxDestroyUtil.put(_lastMousePos);

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
            if(Conductor.instance.time <= 0) {
                for(i in 0...noteRenderer.notes.length) {
                    if(noteRenderer.notes[i].data.time > 0)
                        break;

                    noteRenderer.notes[i].wasHit = false;
                }
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

    public function playTest():Void {
        lastParams = null;
        FlxG.switchState(PlayState.new.bind({
            song: currentSong,
            difficulty: currentDifficulty,
            mix: currentMix,
            mod: Paths.forceMod,
            _chart: currentChart
        }));
    }

    public function zoomIn():Void {
        editorSettings.gridZoom = FlxMath.bound(FlxMath.roundDecimal(editorSettings.gridZoom + 0.2, 2), 0.5, 2.0);
    }

    public function zoomOut():Void {
        editorSettings.gridZoom = FlxMath.bound(FlxMath.roundDecimal(editorSettings.gridZoom - 0.2, 2), 0.5, 2.0);
    }

    public function resetZoom():Void {
        editorSettings.gridZoom = 1.0;
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
                    rawNotes.push(note.data);
                    noteRenderer.notes.push(note);
                    noteRenderer.notes.sort((a, b) -> Std.int(a.data.time - b.data.time));
    
                case CEvent(event):
                    // TODO:
            }
        }
        selectObjects(objects);
    }

    public function addNoteOnCursor():Void {
        final snapMult:Float = CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final newStep:Float = ((FlxG.keys.pressed.SHIFT) ? _mousePos.y : Math.floor(_mousePos.y / snapMult) * snapMult) / CELL_SIZE;
        if(newStep < 0)
            return;

        addObjects([CNote({
            data: {
                time: Conductor.instance.getTimeAtStep(newStep),
                direction: Math.floor((_mousePos.x - grid.x) / CELL_SIZE),
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
                    rawNotes.remove(note.data);
                    noteRenderer.notes.remove(note);

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

    private var _mousePos:FlxPoint = FlxPoint.get();
    private var _lastMousePos:FlxPoint = FlxPoint.get();

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

    public var gridZoom:Float = 1;
}

@:structInit
class ChartEditorNote {
    public var data:NoteData;

    public var step:Float;
    public var lastStep:Float = 0; // used for moving the notes
    public var stepLength:Float;
    
    public var wasHit:Bool = false;
    public var selected:Bool = false;

    public var lastDirection:Int = 0;
}

@:structInit
class ChartEditorEvent {
    public var step:Float;
    public var lastStep:Float = 0;
    
    public var data:EventData;

    public var wasHit:Bool = false;
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