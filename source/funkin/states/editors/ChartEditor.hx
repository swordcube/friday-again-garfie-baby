package funkin.states.editors;

import haxe.io.Path;
import sys.io.File;

import lime.system.System;

import openfl.geom.Rectangle;
import openfl.net.FileReference;
import openfl.display.BitmapData;

import flixel.math.FlxPoint;
import flixel.text.FlxText;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import funkin.backend.Main;

import funkin.ui.*;
import funkin.ui.charter.*;
import funkin.ui.panel.*;
import funkin.ui.topbar.*;
import funkin.ui.dropdown.*;

import funkin.gameplay.HealthIcon;

import funkin.gameplay.song.NoteData;
import funkin.gameplay.song.EventData;
import funkin.gameplay.song.ChartData;

import funkin.gameplay.song.SongMetadata;
import funkin.gameplay.song.VocalGroup;

import funkin.states.menus.MainMenuState;

import funkin.substates.charter.*;
import funkin.substates.UnsavedWarningSubState;

import funkin.utilities.UndoList;

// TODO: chart metadata window

// TODO: allow the user to edit events (along with a popup when placing a new one)
// TODO: have some way to place & select timing points (put them on the right side of the grid, make them purple to indicate them being apart of song metadata)

// TODO: waveforms for inst and each vocal track
// TODO: rework how zooming works (aka don't zoom the camera)

// TODO: if given song or difficulty are null, pull up a window to select a song to chart

@:allow(funkin.ui.charter.CharterObjectGroup)
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
    public var rawEvents:Array<EventData>;

    public var inst:FlxSound;
    public var vocals:VocalGroup;

    public var undos:UndoList<ChartEditorChange>;
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

	public var objectGroup:CharterObjectGroup;
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
    public var miniPerformers:CharterMiniPerformers;

    public var topBar:CharterTopBar;
    public var playBar:CharterPlayBar;

    public var conductorInfoText:FlxText;
    public var rightClickMenu:DropDown;

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
            if(instPath.startsWith('${Paths.CONTENT_DIRECTORY}/'))
				Paths.forceMod = instPath.split("/")[1];
            else
                Paths.forceMod = lastParams.mod;
		}
		if(lastParams._chart != null)
			currentChart = lastParams._chart;
		else
            currentChart = ChartData.load(currentSong, currentMix, Paths.forceMod);

        undos = new UndoList<ChartEditorChange>();
        undos.unsaved = lastParams._unsaved ?? false;

        Paths.iterateDirectory("gameplay/notetypes", (scriptPath:String) -> {
            if(Paths.isAssetType(scriptPath, SCRIPT))
                noteTypes.push(Path.withoutDirectory(Path.withoutExtension(scriptPath)));
        });
        Conductor.instance.time = 0;
        Conductor.instance.rate = 1;
        Conductor.instance.offset = 0;
        
        Conductor.instance.autoIncrement = false;
        Conductor.instance.hasMetronome = editorSettings.metronome;

        Conductor.instance.reset(currentChart.meta.song.timingPoints.first()?.bpm ?? 100);
		Conductor.instance.setupTimingPoints(currentChart.meta.song.timingPoints);

        FlxG.sound.playMusic(instPath, 0, false);
		
        inst = FlxG.sound.music;
        inst.onComplete = () -> {
            inst.pause();
            inst.time = inst.length;
            vocals.pause();

            Conductor.instance.music = null;
            Conductor.instance.time = inst.length;

            playBar.playPauseButton.icon = Paths.image("editors/charter/images/playbar/play");
        };
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

        // TODO: manually draw these, don't need to
        // manually sync them to timing point changes constantly

        beatSeparators = new FlxSpriteContainer();
        beatSeparators.cameras = [noteCam];
        beatSeparators.active = false;
        add(beatSeparators);

        measureSeparators = new FlxSpriteContainer();
        measureSeparators.cameras = [noteCam];
        measureSeparators.active = false;
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
        topCover = new FlxSprite(grid.x, grid.y).makeSolid(gridBitmap.width, FlxG.height * 2.5, FlxColor.BLACK);
        topCover.y -= topCover.height;
        topCover.scrollFactor.x = 0;
        topCover.alpha = 0.5;
        topCover.cameras = [noteCam];
        topCover.active = false;
        add(topCover);
        
        final endStep:Float = Conductor.instance.getStepAtTime(inst.length);
        bottomCover = new FlxSprite(grid.x, grid.y).makeSolid(gridBitmap.width, FlxG.height * 2.5, FlxColor.BLACK);
        bottomCover.y = CELL_SIZE * endStep;
        bottomCover.scrollFactor.x = 0;
        bottomCover.alpha = 0.5;
        bottomCover.cameras = [noteCam];
        bottomCover.active = false;
        add(bottomCover);

        final endSep:FlxSprite = new FlxSprite(grid.x, grid.y + (CELL_SIZE * endStep)).makeSolid(gridBitmap.width, 2, FlxColor.WHITE);
        endSep.cameras = [noteCam];
        endSep.active = false;
        add(endSep);

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

        rawEvents = currentChart.events;
        rawEvents.sort((a, b) -> Std.int(a.time - b.time));

		objectGroup = new CharterObjectGroup(grid.x, grid.y);
		objectGroup.onEmptyCellClick.add(addObjectOnCursor);

		objectGroup.onNoteClick.add((n) -> selectObjects([CNote(n)]));
		objectGroup.onNoteRightClick.add((n) -> rightClickObject(CNote(n)));

        objectGroup.onEventClick.add((e) -> selectObjects([CEvent(e)]));
		objectGroup.onEventRightClick.add((e) -> rightClickObject(CEvent(e)));

		objectGroup.onNoteHit.add((note:ChartEditorNote) -> {
            if(!inst.playing || playBar.songSlider.dragging)
                return;

            if(note.data.direction < Constants.KEY_COUNT) {
                miniPerformers.opponent.sing(note.data.direction % Constants.KEY_COUNT, Math.max(note.data.length, 0.0) + (Conductor.instance.stepLength * 4));
                opponentStrumLine.glowStrum(note.data.direction % Constants.KEY_COUNT, Math.max(note.data.length, Conductor.instance.stepLength));
                
                if(editorSettings.opponentHitsounds)
                    FlxG.sound.play(Paths.sound('editors/charter/sfx/hitsound'));
            }
            else {
                miniPerformers.player.sing(note.data.direction % Constants.KEY_COUNT, Math.max(note.data.length, 0.0) + (Conductor.instance.stepLength * 4));
                playerStrumLine.glowStrum(note.data.direction % Constants.KEY_COUNT, Math.max(note.data.length, Conductor.instance.stepLength));
                
                if(editorSettings.playerHitsounds)
                    FlxG.sound.play(Paths.sound('editors/charter/sfx/hitsound'));
            }
        });
		objectGroup.notes = [for (n in rawNotes) {
            final t = Conductor.instance.getTimingPointAtTime(n.time);
            final step = Conductor.instance.getStepAtTime(n.time, t);
            {
                data: n,
                step: step,
                stepLength: Conductor.instance.getStepAtTime(n.time + n.length, t) - step
            };
        }];
        var lastEventTime:Float = -999999;
        objectGroup.events = [];

        var event:ChartEditorEvent = null;
        for(e in rawEvents) {
            if(Math.abs(e.time - lastEventTime) > 5) {
                // if the event is more than 5ms away from last event,
                // then create a separate event object
                final t = Conductor.instance.getTimingPointAtTime(e.time);
                final step = Conductor.instance.getStepAtTime(e.time, t);

                event = {
                    step: step,
                    events: [e]
                };
                objectGroup.events.push(event);
            }
            else {
                // if the event is 5ms or closer to last event,
                // then add it to the last event object
                event.events.push(e);
            }
            lastEventTime = e.time;
        }
		objectGroup.cameras = [noteCam];
		add(objectGroup);
        
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

        iconP2 = new HealthIcon(currentChart.meta.game.getCharacter("opponent"), OPPONENT);
        uiLayer.add(iconP2);
        
        iconP1 = new HealthIcon(currentChart.meta.game.getCharacter("player"), PLAYER);
        iconP1.flipX = true;
        uiLayer.add(iconP1);

        for(icon in [iconP1, iconP2]) {
            icon.size.scale(0.5);
            icon.scale.scale(0.5);
            icon.updateHitbox();
            icon.centered = true;
            icon.cameras = [uiCam];
            icon.scrollFactor.set();
        }
        iconP2.setPosition(grid.x - (iconP2.width + 12), 38);
        iconP1.setPosition(grid.x + (grid.width + 12), 38);

        visualMetronome = new CharterVisualMetronome(0, 24);
        visualMetronome.cameras = [uiCam];
        visualMetronome.screenCenter(X);

        if(!editorSettings.visualMetronome)
            visualMetronome.visible = false;

        visualMetronome.bigBars.visible = false;
        uiLayer.add(visualMetronome);

        miniPerformers = new CharterMiniPerformers(0, FlxG.height - 40);
        miniPerformers.y -= miniPerformers.bg.height;
        miniPerformers.cameras = [uiCam];
        miniPerformers.screenCenter(X);

        if(!editorSettings.miniPerformers)
            miniPerformers.visible = false;

        uiLayer.add(miniPerformers);

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

        WindowUtil.titleSuffix = " - Chart Editor";
        WindowUtil.onClose = () -> {
            if(!WindowUtil.preventClosing)
                return;

            if(inst.playing)
                playPause();

            final warning = new UnsavedWarningSubState();
            warning.onAccept.add(() -> {
                WindowUtil.preventClosing = false;
                WindowUtil.resetClosing();
                System.exit(0);
            });
            warning.onCancel.add(() -> {
                WindowUtil.resetClosing();
                warning.close();
            });
            openSubState(warning);
        };
        super.create();
    }

    override function update(elapsed:Float) {
        final isUIFocused:Bool = UIUtil.isAnyComponentFocused([grid, selectionBox]);

        FlxG.sound.acceptInputs = !UIUtil.isModifierKeyPressed(ANY) && !isUIFocused;
        FlxG.mouse.getWorldPosition(noteCam, _mousePos);

        super.update(elapsed);

        final isUIActive:Bool = UIUtil.isHoveringAnyComponent([grid, selectionBox]) || isUIFocused;
        noteCam.zoom = FlxMath.lerp(noteCam.zoom, editorSettings.gridZoom, FlxMath.getElapsedLerp(0.32, elapsed));

        @:privateAccess
        final gridPos = grid.getScreenPosition(grid._point, noteCam);

        iconP2.setPosition((gridPos.x + (grid.width - (grid.width * (1 + ((noteCam.zoom - 1) * 0.5))))) - ((iconP2.frameWidth * iconP2.size.x) + 12), 38);
        iconP1.setPosition(gridPos.x + ((grid.width * (1 + ((noteCam.zoom - 1) * 0.5))) + 12), 38);

        if(Conductor.instance.time >= inst.length)
            Conductor.instance.time = inst.length;
        
        @:privateAccess
        visualMetronome.beatsPerMeasure = Conductor.instance._latestTimingPoint.getTimeSignature().getNumerator();

        Conductor.instance.hasMetronome = editorSettings.metronome && inst.playing;
        conductorInfoText.text = 'Step: ${Conductor.instance.curStep}\nBeat: ${Conductor.instance.curBeat}\nMeasure: ${Conductor.instance.curMeasure}';

        final targetScrollY:Float = (CELL_SIZE * Conductor.instance.getStepAtTime(Conductor.instance.playhead)) - (FlxG.height * 0.5);
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
		if (!objectGroup._movingObjects) {
            if(FlxG.mouse.pressed && FlxG.mouse.justMoved && !isUIActive)
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
					var selected:Array<ChartEditorObject> = objectGroup.checkSelection();
                    if(UIUtil.isModifierKeyPressed(CTRL))
                        selectObjects(selectedObjects.concat(selected));
                    else
                        selectObjects(selected);
        
                    FlxTimer.wait(0.001, () -> {
                        selectionBox.setPosition(-99999, -99999);
                        selectionBox.kill();
                    });
                }
                else {
					final direction:Int = Math.floor((_mousePos.x - objectGroup.x) / CELL_SIZE);
                    if(direction < 0 || direction >= (Constants.KEY_COUNT * 2))
                        selectObjects([]);
                }
            }
            if(FlxG.mouse.justReleasedRight && !isUIActive) {
                final direction:Int = Math.floor((_mousePos.x - objectGroup.x) / CELL_SIZE);
                if(direction < 0 || direction >= (Constants.KEY_COUNT * 2)) {
                    if(rightClickMenu != null)
                        rightClickMenu.destroy();

                    rightClickMenu = new DropDown(FlxG.mouse.x, FlxG.mouse.y, 0, 0, [
                        Button("Undo", [[UIUtil.correctModifierKey(CONTROL), Z]], undo),
                        Button("Redo", [[UIUtil.correctModifierKey(CONTROL), Y], [UIUtil.correctModifierKey(CONTROL), SHIFT, Z]], redo),
                        
                        Separator,
                        
                        Button("Copy", [[UIUtil.correctModifierKey(CONTROL), C]], () -> {trace("copy NOT IMPLEMENTED!!");}),
                        Button("Paste", [[UIUtil.correctModifierKey(CONTROL), V]], () -> {trace("paste NOT IMPLEMENTED!!");}),
                        
                        Separator,
                        
                        Button("Cut", [[UIUtil.correctModifierKey(CONTROL), X]], () -> {trace("cut NOT IMPLEMENTED!!");}),
                        Button("Delete", [[DELETE]], () -> deleteObjects(selectedObjects))
                    ]);
                    rightClickMenu.cameras = [uiCam];
                    add(rightClickMenu);
                }
            }
        }
        WindowUtil.titlePrefix = (undos.unsaved) ? "* " : "";
        WindowUtil.preventClosing = undos.unsaved;
    }

    override function beatHit(beat:Int):Void {
        iconP2.bop();
        iconP1.bop();
        visualMetronome.tick();
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

        WindowUtil.preventClosing = false;
        WindowUtil.onClose = null;
        WindowUtil.resetClosing();

        super.destroy();
    }

    public function playPause():Void {
        if(UIUtil.isAnyComponentFocused([grid, selectionBox]))
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
				for (i in 0...objectGroup.notes.length) {
					if (objectGroup.notes[i].data.time > 0)
                        break;

					objectGroup.notes[i].wasHit = false;
                }
            }
            var newTime:Float = FlxMath.bound(Conductor.instance.time, 0, inst.length);
            if(newTime >= inst.length)
                newTime = 0;

            inst.play();
            inst.time = newTime;
            Conductor.instance.music = inst;
            
            vocals.play();
            vocals.seek(inst.time);

            visualMetronome.bigBars.visible = true;
            visualMetronome.tick();

            playBar.playPauseButton.icon = Paths.image("editors/charter/images/playbar/pause");
        }
    }

    public function goBackABeat():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtBeat(Math.floor(Conductor.instance.getBeatAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) - 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goBackAMeasure():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtMeasure(Math.floor(Conductor.instance.getMeasureAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) - 1), 0, inst.length);
        seekToTime(newTime);
    }
    
    public function goForwardABeat():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtBeat(Math.floor(Conductor.instance.getBeatAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) + 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goForwardAMeasure():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;
        
        final newTime:Float = FlxMath.bound(Conductor.instance.getTimeAtMeasure(Math.floor(Conductor.instance.getMeasureAtTime(Conductor.instance.time + (FlxMath.EPSILON * 1000))) + 1), 0, inst.length);
        seekToTime(newTime);
    }

    public function goBackToStart():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        seekToTime(0);
    }

    public function goToEnd():Void {
        if(inst.playing || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        seekToTime(inst.length);
    }

    public function unsafePlayTest():Void {
        lastParams = null;
        Conductor.instance.music = null;
        FlxG.switchState(PlayState.new.bind({
            song: currentSong,
            difficulty: currentDifficulty,

            mix: currentMix,
            mod: Paths.forceMod,

            chartingMode: true,

            _chart: currentChart,
            _unsaved: undos.unsaved
        }));
    }

    public function playTest():Void {
        if(UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        unsafePlayTest();
    }

    public function zoomIn():Void {
        if(UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        editorSettings.gridZoom = FlxMath.bound(FlxMath.roundDecimal(editorSettings.gridZoom + 0.2, 2), 0.2, 2.0);
    }

    public function zoomOut():Void {
        if(UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        editorSettings.gridZoom = FlxMath.bound(FlxMath.roundDecimal(editorSettings.gridZoom - 0.2, 2), 0.2, 2.0);
    }

    public function resetZoom():Void {
        if(UIUtil.isAnyComponentFocused([grid, selectionBox]))
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

    public function addObjects(objects:Array<ChartEditorObject>, ?unsafe:Bool = false):Void {
        for(object in objects) {
            switch(object) {
                case CNote(note):
                    rawNotes.push(note.data);
					objectGroup.notes.push(note);
					objectGroup.notes.sort((a, b) -> Std.int(a.data.time - b.data.time));
    
                case CEvent(event):
                    // TODO: this shit
            }
        }
        selectObjects(objects, true);
        if(!unsafe) {
            undos.unsaved = true;
            undos.add(CAddObjects(objects));
        }
    }

    public function addObjectOnCursor():Void {
        if(UIUtil.isHoveringAnyComponent([grid, selectionBox]) || UIUtil.isAnyComponentFocused([grid, selectionBox]))
            return;

        final snapMult:Float = CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final newStep:Float = ((FlxG.keys.pressed.SHIFT) ? _mousePos.y : Math.floor(_mousePos.y / snapMult) * snapMult) / CELL_SIZE;
        if(newStep < 0)
            return;

        final direction:Int = Math.floor((_mousePos.x - grid.x) / CELL_SIZE);
        if(direction > -1) {
            final object:ChartEditorObject = CNote({
                data: {
                    time: Conductor.instance.getTimeAtStep(newStep),
                    direction: direction,
                    length: 0,
                    type: noteTypes[curNoteType]
                },
                step: newStep,
                stepLength: 0
            });
            addObjects([object]);
        }
        else if(direction > -3 && direction < 0) {
           // TODO: show a menu for this
           trace("event adding NOT implemented!!!");
        }
    }

    public function selectObjects(objects:Array<ChartEditorObject>, ?unsafe:Bool = false):Void {
        // deselect previous objects
        for(object in selectedObjects) {
            switch(object) {
                case CNote(note): note.selected = false;
                case CEvent(event): event.selected = false;
            }
        }
        final objectDataList:Array<Dynamic> = [];
        final filteredObjects:Array<ChartEditorObject> = [];

        for(object in objects) {
            switch(object) {
                case CNote(note):
                    // make sure the note is never selected twice
                    // before marking it as selectable
                    if(!objectDataList.contains(note)) {
                        objectDataList.push(note);
                        filteredObjects.push(object);
                    }
                    
                case CEvent(event):
                    // make sure the event is never selected twice
                    // before marking it as selectable
                    if(!objectDataList.contains(event)) {
                        objectDataList.push(event);
                        filteredObjects.push(object);
                    }
            }
        }
        for(object in filteredObjects) {
            switch(object) {
                case CNote(note): note.selected = true;
                case CEvent(event): event.selected = true;
            }
        }
        if(!unsafe && filteredObjects.length != 0) {
            undos.unsaved = true;
            undos.add(CSelectObjects(filteredObjects, selectedObjects.copy()));
        }
        selectedObjects = filteredObjects;
    }

    public function deleteObjects(objects:Array<ChartEditorObject>, ?unsafe:Bool = false):Void {
        for(object in objects) {
            switch(object) {
                case CNote(note):
                    rawNotes.remove(note.data);
                    objectGroup.notes.remove(note);

                case CEvent(event):
                    for(e in event.events)
                        rawEvents.remove(e);

                    objectGroup.events.remove(event);
            }
        }
        selectObjects([], true);
        if(!unsafe) {
            undos.unsaved = true;
            undos.add(CRemoveObjects(objects)); 
        }
    }

    public function rightClickObject(object:ChartEditorObject):Void {
        if(UIUtil.isModifierKeyPressed(CTRL))
            deleteObjects([object]);
        else {
            switch(object) {
                case CNote(note):
                    final dropdown:DropDown = new DropDown(FlxG.mouse.x, FlxG.mouse.y, 0, 0, [
                        Button("Edit", null, () -> trace("edit note NOT IMPLEMENTED!!")),

                        Separator,

                        Button("Delete", [[DELETE]], () -> deleteObjects([object])),
                    ]);
                    dropdown.cameras = [uiCam];
                    add(dropdown);

                case CEvent(event):
                    final dropdown:DropDown = new DropDown(FlxG.mouse.x, FlxG.mouse.y, 0, 0, [
                        Button("Edit", null, () -> trace("edit event NOT IMPLEMENTED!!")),

                        Separator,

                        Button("Delete", [[DELETE]], () -> deleteObjects([object])),
                    ]);
                    dropdown.cameras = [uiCam];
                    add(dropdown);
            }
        }
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
        
        visualMetronome.tick(true);
    }

    public function toggleMiniPerformers(value:Bool):Void {
        editorSettings.miniPerformers = value;
        miniPerformers.visible = editorSettings.miniPerformers;
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
        if(inst.playing)
            playPause();

        openSubState(new CharterMetadataMenu());
    }

    public function selectAllNotes():Void {
        final selected:Array<ChartEditorObject> = [];
        for(note in objectGroup.notes)
            selected.push(CNote(note));

        selectObjects(selected);
    }

    public function selectMeasureNotes():Void {
        final selected:Array<ChartEditorObject> = [];
        final curMeasure:Int = Conductor.instance.curMeasure;

        @:privateAccess
        final latestTimingPoint:TimingPoint = Conductor.instance._latestTimingPoint;
        final timeSignature:TimeSignature = latestTimingPoint.getTimeSignature();

        for(note in objectGroup.notes) {
            final step:Float = note.step + 0.01;
            final measureLength:Float = timeSignature.getDenominator() * timeSignature.getNumerator();

            if(step < curMeasure * measureLength || step > (curMeasure + 1) * measureLength)
                continue;

            selected.push(CNote(note));
        }
        selectObjects(selected);
    }

    public function save():Void {
        undos.unsaved = false;
        if(currentSong == null || currentMix == null) {
            saveChartAs();
            FlxTimer.wait(0.1, () -> saveMetaAs());
            return;
        }
        File.saveContent(Paths.json('gameplay/songs/${currentSong}/${currentMix}/chart', lastParams.mod), ChartData.stringify(currentChart));
        File.saveContent(Paths.json('gameplay/songs/${currentSong}/${currentMix}/metadata', lastParams.mod), SongMetadata.stringify(currentChart.meta));
    }

    public function saveChartAs():Void {
        final fileRef:FileReference = new FileReference();
        fileRef.save(ChartData.stringify(currentChart), 'chart.json');
    }

    public function saveMetaAs():Void {
        final fileRef:FileReference = new FileReference();
        fileRef.save(SongMetadata.stringify(currentChart.meta), 'meta.json');
    }

    public function unsafeExit():Void {
        FlxG.sound.music.looped = true;
        FlxG.sound.music.onComplete = null;
        FlxG.sound.music.play();

        Conductor.instance.music = null;
        FlxG.switchState(MainMenuState.new);
    }

    public function exit():Void {
        if(undos.unsaved) {
            if(inst.playing)
                playPause();

            final warning = new UnsavedWarningSubState();
            warning.onAccept.add(unsafeExit);
            warning.onCancel.add(warning.close);
            openSubState(warning);
            return;
        }
        unsafeExit();
    }

    public function undo():Void {
        final action:ChartEditorChange = undos.undo();
        if(action == null)
            return;
        
        switch(action) {
            case CAddObjects(objects):
                deleteObjects(objects, true);

            case CRemoveObjects(objects):
                addObjects(objects, true);

            case CMoveObjects(data):
                for(object in data.objects) {
                    switch(object) {
                        case CNote(note):
                            note.step -= data.change.y;
                            note.data.direction = FlxMath.boundInt(Std.int(note.data.direction - data.change.x), 0, (Constants.KEY_COUNT * 2) - 1);
                            note.data.time = Conductor.instance.getTimeAtStep(note.step);
                        
                        case CEvent(event):
                            event.step -= data.change.y;
                            for(e in event.events)
                                e.time = Conductor.instance.getTimeAtStep(event.step);
                    }
                }

            case CSelectObjects(_, lastSelectedObjects):
                selectObjects(lastSelectedObjects.copy(), true);

            default:
                // do nothing           :p
        }
        undos.unsaved = true;
    }

    public function redo():Void {
        final action:ChartEditorChange = undos.redo();
        if(action == null)
            return;

        switch(action) {
            case CAddObjects(objects):
                addObjects(objects, true);

            case CRemoveObjects(objects):
                deleteObjects(objects, true);

            case CMoveObjects(data):
                for(object in data.objects) {
                    switch(object) {
                        case CNote(note):
                            note.step += data.change.y;
                            note.data.direction = FlxMath.boundInt(Std.int(note.data.direction + data.change.x), 0, (Constants.KEY_COUNT * 2) - 1);
                            note.data.time = Conductor.instance.getTimeAtStep(note.step);
                        
                        case CEvent(event):
                            event.step += data.change.y;
                            for(e in event.events)
                                e.time = Conductor.instance.getTimeAtStep(event.step);
                    }
                }

            case CSelectObjects(newObjects, _):
                selectObjects(newObjects.copy(), true);

            default:
                // do nothing           :p
        }
        undos.unsaved = true;
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

    @:noCompletion
    var ?_unsaved:Bool;
}

@:structInit
class ChartEditorSettings {
    public var opponentHitsounds:Bool = true;
    public var playerHitsounds:Bool = true;

    public var gridSnap:Int = 16;
    public var metronome:Bool = false;
    public var visualMetronome:Bool = false;
    public var miniPerformers:Bool = false;

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
    
    public var events:Array<EventData>;

    public var wasHit:Bool = false;
    public var selected:Bool = false;
}

@:structInit
class ChartEditorMoveObjectData {
    public var change:FlxPoint;
    public var objects:Array<ChartEditorObject>;
}

enum ChartEditorObject {
    CNote(note:ChartEditorNote);
    CEvent(event:ChartEditorEvent);
}

enum ChartEditorChange {
    CAddObjects(objects:Array<ChartEditorObject>);
    CRemoveObjects(objects:Array<ChartEditorObject>);
    
    CMoveObjects(data:ChartEditorMoveObjectData);
    CSelectObjects(newObjects:Array<ChartEditorObject>, lastSelectedObjects:Array<ChartEditorObject>);
}