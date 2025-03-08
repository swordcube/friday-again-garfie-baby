package funkin.states.editors;

import sys.io.File;
import openfl.net.FileReference;

import flixel.text.FlxText;
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

import funkin.gameplay.HealthIcon;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.SongMetadata;

import funkin.gameplay.song.VocalGroup;

// TODO: undos & redos

// TODO: have some way to place & select events
// TODO: have some way to place & select timing points

// TODO: waveforms for inst and each vocal track

@:allow(funkin.ui.charter.CharterObjectRenderer)
class ChartEditor extends UIState {
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

    public var grid:CharterGrid;
	public var eventGrid:FlxBackdrop;

    public var iconP2:HealthIcon;
    public var iconP1:HealthIcon;

    public var topCover:FlxSprite;
    public var bottomCover:FlxSprite;
    
    public var beatSeparators:FlxSpriteContainer;
    public var measureSeparators:FlxSpriteContainer;

	public var objectRenderer:CharterObjectRenderer;
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

    public var visualMetronome:CharterVisualMetronome;

    public var topBar:CharterTopBar;
    public var playBar:CharterPlayBar;

    public var conductorInfoText:FlxText;

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
        Conductor.instance.rate = 1;
        Conductor.instance.offset = 0;
        
        Conductor.instance.autoIncrement = false;
        Conductor.instance.hasMetronome = editorSettings.metronome;

        Conductor.instance.reset(currentChart.meta.song.bpm);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);

        FlxG.sound.playMusic(instPath, 0, false);
		
        inst = FlxG.sound.music;
        inst.onComplete = () -> {
            inst.time = inst.length;
            vocals.pause();
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
        grid = new CharterGrid(gridBitmap, Y);
        grid.screenCenter(X);
        grid.scrollFactor.x = 0;
        grid.cameras = [noteCam];
        add(grid);

		eventGrid = new FlxBackdrop(Paths.image("editors/charter/images/event_grid"), Y);
		eventGrid.x = grid.x - eventGrid.width;
		eventGrid.scrollFactor.x = 0;
		eventGrid.cameras = [noteCam];
		eventGrid.alpha = 0.45;
		add(eventGrid);

        iconP2 = new HealthIcon(currentChart.meta.game.getCharacter("opponent"), OPPONENT);
        add(iconP2);
        
        iconP1 = new HealthIcon(currentChart.meta.game.getCharacter("player"), PLAYER);
        iconP1.flipX = true;
        add(iconP1);
        
        for(icon in [iconP1, iconP2]) {
            icon.size.scale(0.5);
            icon.scale.scale(0.5);
            icon.updateHitbox();
            icon.centered = true;
            icon.cameras = [noteCam];
            icon.scrollFactor.set();
        }
        iconP2.setPosition(grid.x - (iconP2.width + 12), 38);
        iconP1.setPosition(grid.x + (grid.width + 12), 38);

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

		objectRenderer = new CharterObjectRenderer(grid.x, grid.y);

		objectRenderer.onEmptyCellClick.add(addObjectOnCursor);
		objectRenderer.onNoteClick.add((n) -> selectObjects([CNote(n)]));
		objectRenderer.onNoteRightClick.add((n) -> deleteObjects([CNote(n)]));

		objectRenderer.onNoteHit.add((note:ChartEditorNote) -> {
            if(!inst.playing || playBar.songSlider.dragging)
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
		objectRenderer.notes = [
			for (n in rawNotes) {
            final t = Conductor.instance.getTimingPointAtTime(n.time);
            final step = Conductor.instance.getStepAtTime(n.time, t);
            {
                data: n,
                step: Conductor.instance.getStepAtTime(n.time, t),
                stepLength: Conductor.instance.getStepAtTime(n.time + n.length, t) - step
            };
        }];
		objectRenderer.cameras = [noteCam];
		add(objectRenderer);
        
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

        visualMetronome = new CharterVisualMetronome(0, 24);
        visualMetronome.cameras = [uiCam];
        visualMetronome.screenCenter(X);

        if(!editorSettings.visualMetronome)
            visualMetronome.visible = false;

        visualMetronome.bigBars.visible = false;
        uiLayer.add(visualMetronome);

        topBar = new CharterTopBar();
        topBar.zIndex = 1;
        uiLayer.add(topBar);
        
        topBar.updateLeftSideItems();
        topBar.updateRightSideItems();

        playBar = new CharterPlayBar();
        playBar.zIndex = 1;
        playBar.y = FlxG.height - playBar.bg.height;
        uiLayer.add(playBar);

        conductorInfoText = new FlxText(12, 0, 0, "Step: 0\nBeat: 0\nMeasure: 0");
        conductorInfoText.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        conductorInfoText.y = FlxG.height - (conductorInfoText.height + playBar.bg.height + 16);
        uiLayer.add(conductorInfoText);

        // adjust a few lil things

        FlxG.mouse.visible = true;
        Main.statsDisplay.visible = false; // it gets in the way
        
        noteCam.zoom = editorSettings.gridZoom;
        noteCam.scroll.y -= FlxG.height * 0.5;
        setPlaybackRate(editorSettings.playbackRate);
        
        super.create();
    }

    override function update(elapsed:Float) {
        final isUIFocused:Bool = UIUtil.isAnyComponentFocused([grid]);

        FlxG.sound.acceptInputs = !UIUtil.isModifierKeyPressed(ANY) && !isUIFocused;
        FlxG.mouse.getWorldPosition(noteCam, _mousePos);

        super.update(elapsed);

        final isUIActive:Bool = UIUtil.isHoveringAnyComponent([grid]) || isUIFocused;
        noteCam.zoom = FlxMath.lerp(noteCam.zoom, editorSettings.gridZoom, FlxMath.getElapsedLerp(0.32, elapsed));

        if(Conductor.instance.time >= inst.length)
            Conductor.instance.time = inst.length;
        
        @:privateAccess
        visualMetronome.beatsPerMeasure = Conductor.instance._latestTimingPoint.getTimeSignature().getNumerator();

        Conductor.instance.hasMetronome = editorSettings.metronome && inst.playing;
        conductorInfoText.text = 'Step: ${Conductor.instance.curStep}\nBeat: ${Conductor.instance.curBeat}\nMeasure: ${Conductor.instance.curMeasure}';

        final targetScrollY:Float = (CELL_SIZE * Conductor.instance.getStepAtTime(Conductor.instance.time)) - (FlxG.height * 0.5);
        if(inst.playing || isUIFocused)
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

            if(FlxG.mouse.pressedMiddle && FlxG.mouse.justMoved && !_middleScrolling) {
                _middleScrolling = true;
                _lastMousePos.y = FlxG.mouse.y;
            }
            if(_middleScrolling) {
                seekToTime(FlxMath.bound(Conductor.instance.time + ((FlxG.mouse.y - _lastMousePos.y) * elapsed * 10), 0, inst.length));
                if(FlxG.mouse.releasedMiddle)
                    _middleScrolling = false;
            }
        }
		if (!objectRenderer._movingObjects) {
            if(FlxG.mouse.justPressed && !isUIActive)
                _selectingObjects = true;

            if(_selectingObjects) {
                if(FlxG.mouse.justMoved && !selectionBox.exists) {
                    _lastMousePos.copyFrom(_mousePos);
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
            if(FlxG.mouse.justReleased && !isUIActive) {
                _selectingObjects = false;
                if(selectionBox.exists) {
					var selected:Array<ChartEditorObject> = objectRenderer.checkSelection();
                    selectObjects(selected);
        
                    FlxTimer.wait(0.001, () -> {
                        selectionBox.setPosition(-99999, -99999);
                        selectionBox.kill();
                    });
                } else {
					final direction:Int = Math.floor((_mousePos.x - objectRenderer.x) / CELL_SIZE);
                    if(direction < 0 || direction >= (Constants.KEY_COUNT * 2))
                        selectObjects([]);
                }
            }
        }
    }

    override function beatHit(beat:Int):Void {
        iconP2.bop();
        iconP1.bop();
        visualMetronome.tick(beat);
        super.beatHit(beat);
    }
    
    override function destroy():Void {
        _mousePos = FlxDestroyUtil.put(_mousePos);
        _lastMousePos = FlxDestroyUtil.put(_lastMousePos);

        Main.statsDisplay.visible = true;
        FlxG.mouse.visible = false;

        Conductor.instance.rate = 1;
        Conductor.instance.music = null;
        Conductor.instance.hasMetronome = false;
        
        FlxG.sound.acceptInputs = true;
        Paths.forceMod = null;
        super.destroy();
    }

    public function playPause():Void {
        if(UIUtil.isAnyComponentFocused([grid]))
            return;

        if(inst.playing) {
            opponentStrumLine.resetAllStrums();
            playerStrumLine.resetAllStrums();
            
            vocals.pause();
            inst.pause();

            Conductor.instance.music = null;
            visualMetronome.bigBars.visible = false;
            playBar.playPauseButton.icon = Paths.image("editors/charter/images/playbar/play");
        }
        else {
            if(Conductor.instance.time <= 0) {
				for (i in 0...objectRenderer.notes.length) {
					if (objectRenderer.notes[i].data.time > 0)
                        break;

					objectRenderer.notes[i].wasHit = false;
                }
            }
            Conductor.instance.music = inst;
            inst.time = FlxMath.bound(Conductor.instance.time, 0, inst.length);
            vocals.seek(inst.time);
            
            vocals.play();
            inst.play();

            visualMetronome.bigBars.visible = true;
            visualMetronome.tick(Conductor.instance.curBeat);

            playBar.playPauseButton.icon = Paths.image("editors/charter/images/playbar/pause");
        }
    }

    public function goBackABeat():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid]))
            return;

        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtBeat(Math.floor(Conductor.instance.getBeatAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) - 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goBackAMeasure():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid]))
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtMeasure(Math.floor(Conductor.instance.getMeasureAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) - 1), 0, inst.length);
        seekToTime(newTime);
    }
    
    public function goForwardABeat():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid]))
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtBeat(Math.floor(Conductor.instance.getBeatAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) + 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goForwardAMeasure():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid]))
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtMeasure(Math.floor(Conductor.instance.getMeasureAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) + 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goBackToStart():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid]))
            return;

        seekToTime(0);
    }

    public function goToEnd():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid]))
            return;

        seekToTime(inst.length);
    }

    public function playTest():Void {
        if(UIUtil.isAnyComponentFocused([grid]))
            return;

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
        if(UIUtil.isAnyComponentFocused([grid]))
            return;

        editorSettings.gridZoom = FlxMath.bound(FlxMath.roundDecimal(editorSettings.gridZoom + 0.2, 2), 0.5, 2.0);
    }

    public function zoomOut():Void {
        if(UIUtil.isAnyComponentFocused([grid]))
            return;

        editorSettings.gridZoom = FlxMath.bound(FlxMath.roundDecimal(editorSettings.gridZoom - 0.2, 2), 0.5, 2.0);
    }

    public function resetZoom():Void {
        if(UIUtil.isAnyComponentFocused([grid]))
            return;
        
        editorSettings.gridZoom = 1.0;
    }

    public function setPlaybackRate(rate:Float):Void {
        if(Math.isNaN(rate))
            rate = 1;
        
        rate = FlxMath.roundDecimal(FlxMath.bound(rate, 0.25, 3), 2);
        editorSettings.playbackRate = rate;

        inst.pitch = editorSettings.playbackRate;
        Conductor.instance.rate = editorSettings.playbackRate;

        if(vocals.spectator != null)
            vocals.spectator.pitch = editorSettings.playbackRate;
        
        if(vocals.opponent != null)
            vocals.opponent.pitch = editorSettings.playbackRate;
        
        if(vocals.player != null)
            vocals.player.pitch = editorSettings.playbackRate;
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
					objectRenderer.notes.push(note);
					objectRenderer.notes.sort((a, b) -> Std.int(a.data.time - b.data.time));
    
                case CEvent(event):
                    // TODO:
            }
        }
        selectObjects(objects);
    }

    public function addObjectOnCursor():Void {
        if(UIUtil.isHoveringAnyComponent([grid]) || UIUtil.isAnyComponentFocused([grid]))
            return;

        final snapMult:Float = CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final newStep:Float = ((FlxG.keys.pressed.SHIFT) ? _mousePos.y : Math.floor(_mousePos.y / snapMult) * snapMult) / CELL_SIZE;
        if(newStep < 0)
            return;

        final direction:Int = Math.floor((_mousePos.x - grid.x) / CELL_SIZE);
        if(direction > -1) {
            addObjects([CNote({
                data: {
                    time: Conductor.instance.getTimeAtStep(newStep),
                    direction: direction,
                    length: 0,
                    type: noteTypes[curNoteType]
                },
                step: newStep,
                stepLength: 0
            })]);
        }
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
					objectRenderer.notes.remove(note);

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
                    note.data.length = Math.max(note.data.length - t.getStepLength(), 0);
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
        Conductor.instance.hasMetronome = editorSettings.metronome && inst.playing;
    }

    public function toggleVisualMetronome(value:Bool):Void {
        editorSettings.visualMetronome = value;

        visualMetronome.visible = editorSettings.visualMetronome;
        visualMetronome.bigBars.visible = inst.playing;
        
        visualMetronome.tick(Conductor.instance.curBeat, true);
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

    public function openMetadataWindow():Void {
        final window = new CharterMetadataWindow(topBar.x + 12, topBar.y + topBar.bg.height + 12);
        window.cameras = [uiCam];
        uiLayer.add(window);
    }

    public function save():Void {
        if(currentSong == null || currentMix == null) {
            saveChartAs();
            FlxTimer.wait(0.1, () -> saveMetaAs());
            return;
        }
        File.saveContent(Paths.json('gameplay/songs/${currentSong}/${currentMix}/chart', lastParams.mod), ChartData.stringify(currentChart));
        File.saveContent(Paths.json('gameplay/songs/${currentSong}/${currentMix}/meta', lastParams.mod), SongMetadata.stringify(currentChart.meta));
    }

    public function saveChartAs():Void {
        final fileRef:FileReference = new FileReference();
        fileRef.save(ChartData.stringify(currentChart), 'chart.json');
    }

    public function saveMetaAs():Void {
        final fileRef:FileReference = new FileReference();
        fileRef.save(SongMetadata.stringify(currentChart.meta), 'meta.json');
    }

    //----------- [ Private API ] -----------//

    private var _middleScrolling:Bool = false;
    private var _selectingObjects:Bool = false;

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
    public var visualMetronome:Bool = false;

    public var muteInstrumental:Bool = false;
    public var muteAllVocals:Bool = false;

    public var muteSpectatorVocals:Bool = false;
    public var muteOpponentVocals:Bool = false;
    public var mutePlayerVocals:Bool = false;

    public var gridZoom:Float = 1;
    public var playbackRate:Float = 1;
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