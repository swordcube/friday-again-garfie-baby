package funkin.ui.charter;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;

import funkin.gameplay.song.NoteData;
import funkin.gameplay.song.EventData;
import funkin.gameplay.song.ChartData;

import funkin.states.editors.ChartEditor;

import funkin.ui.SliceSprite;
import funkin.utilities.SortedArrayUtil;

// TODO: show note type id on each note

/**
 * A class specifically designed to handle note & event objects
 * in the chart editor.
 * 
 * This exists because syncing a bunch of individual
 * sprites to chart data is a pain in the ass!!
 * 
 * NOTE: This does NOT support animations on the rendered notes!!
 * 
 * NOTE: This does NOT extend `FlxGroup`, or support any of it's API.
 */
@:allow(funkin.states.editors.ChartEditor)
class CharterObjectGroup extends FlxObject {
    public var charter(default, null):ChartEditor;

    public var onNoteHit(default, null):FlxTypedSignal<ChartEditorNote->Void> = new FlxTypedSignal<ChartEditorNote->Void>(); 
    public var onEventHit(default, null):FlxTypedSignal<ChartEditorEvent->Void> = new FlxTypedSignal<ChartEditorEvent->Void>(); 
    
    public var onEmptyCellClick(default, null):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>(); 

    public var onNoteClick(default, null):FlxTypedSignal<ChartEditorNote->Void> = new FlxTypedSignal<ChartEditorNote->Void>(); 
    public var onNoteRightClick(default, null):FlxTypedSignal<ChartEditorNote->Void> = new FlxTypedSignal<ChartEditorNote->Void>(); 

	public var onEventClick(default, null):FlxTypedSignal<ChartEditorEvent->Void> = new FlxTypedSignal<ChartEditorEvent->Void>();
	public var onEventRightClick(default, null):FlxTypedSignal<ChartEditorEvent->Void> = new FlxTypedSignal<ChartEditorEvent->Void>(); 

    public var objectMoveSounds:Array<FlxSound> = [];
    public var curObjectMoveSound:Int = 0;

    /**
     * The notes from the chart that will directly
     * be rendered onto this object.
     */
    public var notes:Array<ChartEditorNote> = [];

    /**
     * The events from the chart that will directly
     * be rendered onto this object.
     */
    public var events:Array<ChartEditorEvent> = [];

    public var isHoveringNote:Bool = false;
    public var isHoveringEvent:Bool = false;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y, 1, 1);
        charter = cast FlxG.state;

        _eventBGSprite = new SliceSprite();
        _eventBGSprite.cursorType = POINTER;
        _eventBGSprite.loadGraphic(Paths.image("editors/charter/images/event_bg"));
        _eventBGSprite.setBorders(20, 20, 14, 14);
        _eventBGSprite.cameras = getCameras();
        _eventBGSprite.container = charter;
        _eventBGSprite.width = 70;
        _eventBGSprite.height = 42;

        _addEventSprite = new FlxSprite();
        _addEventSprite.loadGraphic(Paths.image("editors/charter/images/event_add_bg"));

        for(i in 0...5) {
            // 5 is probably enough of these sounds to continuously re-use 
            final sound:FlxSound = FlxG.sound.play(Paths.sound("editors/charter/sfx/object_move"), 0, false, null, false);
            objectMoveSounds.push(sound);
        }
    }

    override function update(elapsed:Float) {
        final direction:Int = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
        if(_movingObjects) {
            final snapMult:Float = ChartEditor.CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
            if(TouchUtil.justReleased)
                _movingObjects = false;
            
            for(object in charter.selectedObjects) {
                switch(object) {
                    case CNote(note):
                        final lastStep:Float = note.step;
                        final lastDirection:Int = note.data.direction;
                        note.data.direction = FlxMath.boundInt(note.lastDirection + (direction - _lastDirection), 0, (Constants.KEY_COUNT * 2) - 1);

                        final newStep:Float = note.lastStep + (charter._mousePos.y - _lastMouseY);
                        note.step = Math.max((FlxG.keys.pressed.SHIFT) ? (newStep / ChartEditor.CELL_SIZE) : (Math.floor(newStep / snapMult) * snapMult) / ChartEditor.CELL_SIZE, 0);

                        if(note.step != lastStep || note.data.direction != lastDirection) {
                            final sound:FlxSound = (objectMoveSounds[curObjectMoveSound]);
                            sound.volume = 1;
                            sound.play(true);
                            curObjectMoveSound = (curObjectMoveSound + 1) % objectMoveSounds.length;
                        }
                        if(!_movingObjects)
                            note.data.time = Conductor.instance.getTimeAtStep(note.step);

                    case CEvent(event):
                        final lastStep:Float = event.step;

                        final newStep:Float = event.lastStep + (charter._mousePos.y - _lastMouseY);
                        event.step = Math.max((FlxG.keys.pressed.SHIFT) ? (newStep / ChartEditor.CELL_SIZE) : (Math.floor(newStep / snapMult) * snapMult) / ChartEditor.CELL_SIZE, 0);

                        if(event.step != lastStep) {
                            final sound:FlxSound = (objectMoveSounds[curObjectMoveSound]);
                            sound.volume = 1;
                            sound.play(true);
                            curObjectMoveSound = (curObjectMoveSound + 1) % objectMoveSounds.length;
                        }
                        if(!_movingObjects) {
                            final time:Float = Conductor.instance.getTimeAtStep(event.step);
                            for(e in event.events)
                                e.time = time;
                        }

                    default:
                        continue;
                }
            }
            if(!_movingObjects) {
                var change:Float = (charter._mousePos.y - _lastMouseY);
                change = (FlxG.keys.pressed.SHIFT) ? (change / ChartEditor.CELL_SIZE) : (Math.floor(change / snapMult) * snapMult) / ChartEditor.CELL_SIZE;

                charter.undos.add(CMoveObjects({
                    change: new FlxPoint(direction - _lastDirection, change),
                    objects: charter.selectedObjects.copy()
                }));
            }
            return;
        }
        isHoveringNote = false;
        isHoveringEvent = false;

        final coveredUpByOtherUI:Bool = UIUtil.isHoveringAnyComponent([charter.grid, charter.selectionBox]) || UIUtil.isAnyComponentFocused([charter.grid, charter.selectionBox]);
		if(direction < (Constants.KEY_COUNT * 2)) {
            final max:Float = FlxG.height / 70 / getDefaultCamera().zoom;
    
            var sprite:FlxSprite = null;
            var isEmptyCell:Bool = true;

            if(direction > -1) {
                final pointer = TouchUtil.touch;

                // handle notes
                final begin:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep - max, _getVarForEachNoteAdd);
                final end:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep + max, _getVarForEachNoteRemove);
        
                var note:ChartEditorNote = null;
                for(i in begin...end) {
                    note = notes[i];
                    sprite = _getNoteSprite(note.data.type, note.data.direction % Constants.KEY_COUNT);
                    
                    final offsetX:Float = (note.data.direction < Constants.KEY_COUNT) ? -1 : 1;
                    sprite.setPosition(x + (ChartEditor.CELL_SIZE * note.data.direction) + offsetX, y + (ChartEditor.CELL_SIZE * note.step));
    
                    if (pointer.overlaps(sprite, charter.noteCam) && !coveredUpByOtherUI) {
                        isHoveringNote = true;
                        if(TouchUtil.pressed && TouchUtil.justMoved && note.selected && !charter.selectionBox.exists) {
                            for(object in charter.selectedObjects) {
                                switch(object) {
                                    case CNote(note):
                                        note.lastStep = note.step * ChartEditor.CELL_SIZE;
                                        note.lastDirection = note.data.direction;

                                    case CEvent(event):
                                        event.lastStep = event.step * ChartEditor.CELL_SIZE;
                                }
                            }
                            _lastDirection = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
                            _lastMouseY = sprite.y;
    
                            _movingObjects = true;
                            return;
                        }
                        if(TouchUtil.justReleased)
                            onNoteClick.dispatch(note);
    
                        else if(FlxG.mouse.justReleasedRight)
                            onNoteRightClick.dispatch(note);
                        
                        isEmptyCell = false;
                        break;
                    }
                }
            }
            else {
                final pointer = TouchUtil.touch;

                // handle events
                final begin:Int = SortedArrayUtil.binarySearch(events, Conductor.instance.curStep - max, _getVarForEachEventAdd);
                final end:Int = SortedArrayUtil.binarySearch(events, Conductor.instance.curStep + max, _getVarForEachEventRemove);

                var event:ChartEditorEvent = null;
                for(i in begin...end) {
                    event = events[i];
                    
                    final offsetX:Float = -1;
                    _eventBGSprite.cameras = getCameras();
            
                    _eventBGSprite.width = 70 + ((event.events.length - 1) * 30);
                    _eventBGSprite.setPosition((x - _eventBGSprite.width) + offsetX, y + (ChartEditor.CELL_SIZE * event.step) - (_eventBGSprite.height * 0.5));

                    if (pointer.overlaps(_eventBGSprite, charter.noteCam) && !coveredUpByOtherUI) {
                        isHoveringEvent = true;
                        
                        if(TouchUtil.pressed && TouchUtil.justMoved && event.selected && !charter.selectionBox.exists) {
                            for(object in charter.selectedObjects) {
                                switch(object) {
                                    case CNote(note):
                                        note.lastStep = note.step * ChartEditor.CELL_SIZE;
                                        note.lastDirection = note.data.direction;

                                    case CEvent(event):
                                        event.lastStep = event.step * ChartEditor.CELL_SIZE;
                                }
                            }
                            _lastDirection = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
                            _lastMouseY = _eventBGSprite.y;
    
                            _movingObjects = true;
                            return;
                        }
                        if(TouchUtil.justReleased)
                            onEventClick.dispatch(event);
    
                        else if(FlxG.mouse.justReleasedRight)
                            onEventRightClick.dispatch(event);
                        
                        isEmptyCell = false;
                        break;
                    }                    
                }
            }
            if(isEmptyCell && TouchUtil.justReleased && !charter.selectionBox.exists)
                onEmptyCellClick.dispatch();
		}
    }

    override function draw():Void {
        final max:Float = FlxG.height / 70 / getDefaultCamera().zoom;

        isHoveringNote = false;
        isHoveringEvent = false;
        
        var note:ChartEditorNote = null;
        var event:ChartEditorEvent = null;
        
        var sprite:FlxSprite = null;
        var sustain:CharterSustain = null;
        
        // draw all of the notes in the chart
        final begin:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep - max, _getVarForEachNoteAdd);
        final end:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep + max, _getVarForEachNoteRemove);

        final pointer = TouchUtil.touch;
        for(i in begin...end) {
            note = notes[i];

			sprite = _getNoteSprite(note.data.type, note.data.direction % Constants.KEY_COUNT);
            sustain = _getSustain(note.data.type, note.data.direction % Constants.KEY_COUNT);
            
            if(note.data.time <= Conductor.instance.time) {
                sprite.alpha = 0.6;
                if(!note.wasHit) {
                    note.wasHit = true;
                    onNoteHit.dispatch(note);
                }
            } else {
                sprite.alpha = 1;
                note.wasHit = false;
            }
            final offsetX:Float = (note.data.direction < Constants.KEY_COUNT) ? -1 : 1;

            sustain.updateSustain(note.data.direction % Constants.KEY_COUNT, sprite.scale.x);
            sustain.alpha = sprite.alpha;
            sustain.height = (note.stepLength > 0.01) ? (note.stepLength + 0.5) * ChartEditor.CELL_SIZE : 0;
            
            sustain.setPosition(x + (ChartEditor.CELL_SIZE * note.data.direction) + ((ChartEditor.CELL_SIZE - sustain.strip.width) * 0.5) + offsetX, y + (ChartEditor.CELL_SIZE * note.step) + (ChartEditor.CELL_SIZE * 0.5));
            sustain.draw();

            final colorOffset:Float = (note.selected) ? 75 : 0;
            sprite.colorTransform.redOffset = sprite.colorTransform.greenOffset = sprite.colorTransform.blueOffset = colorOffset;
            
            sprite.setPosition(x + (ChartEditor.CELL_SIZE * note.data.direction) + offsetX, y + (ChartEditor.CELL_SIZE * note.step));
            sprite.draw();

            if(pointer.overlaps(sprite, charter.noteCam))
                isHoveringNote = true;
        }

        // draw all of the events in the chart
        final begin:Int = SortedArrayUtil.binarySearch(events, Conductor.instance.curStep - max, _getVarForEachEventAdd);
        final end:Int = SortedArrayUtil.binarySearch(events, Conductor.instance.curStep + max, _getVarForEachEventRemove);

        for(i in begin...end) {
            event = events[i];
            if(event.events.length == 0)
                continue;

            final offsetX:Float = -1;

            // draw bg
            final colorOffset:Float = (event.selected) ? 75 : 0;
            _eventBGSprite.colorTransform.redOffset = _eventBGSprite.colorTransform.greenOffset = _eventBGSprite.colorTransform.blueOffset = colorOffset;
            _eventBGSprite.cameras = getCameras();
            
            _eventBGSprite.width = 70 + ((event.events.length - 1) * 30);
            _eventBGSprite.setPosition((x - _eventBGSprite.width) + offsetX, y + (ChartEditor.CELL_SIZE * event.step) - (_eventBGSprite.height * 0.5));
            _eventBGSprite.draw();

            if(pointer.overlaps(_eventBGSprite, charter.noteCam))
                isHoveringEvent = true;

            // draw icons
            for(j in 0...event.events.length) {
                final e:EventData = event.events[j];
                sprite = _getEventIconSprite(e.type);

                sprite.setPosition(_eventBGSprite.x + (j * 30) + 25, _eventBGSprite.y + ((_eventBGSprite.height - sprite.height) * 0.5));
                sprite.draw();
            }
        }

        // draw the cursor note
        final direction:Int = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
        if(!isHoveringNote && !charter.selectionBox.exists && direction >= 0 && direction < (Constants.KEY_COUNT * 2))
            drawCursorNote(charter.noteTypes[charter.curNoteType], direction);

        // draw the cursor event
        if(!isHoveringEvent && !charter.selectionBox.exists && direction > -3 && direction < 0)
            drawCursorEvent();
    }

    public function drawCursorNote(noteType:String, direction:Int):Void {
        final snapX:Int = Math.floor(charter._mousePos.x / ChartEditor.CELL_SIZE) * ChartEditor.CELL_SIZE;

        final snapMult:Float = ChartEditor.CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final snapY:Float = (FlxG.keys.pressed.SHIFT) ? charter._mousePos.y : Math.floor(charter._mousePos.y / snapMult) * snapMult;

		final sprite:FlxSprite = _getNoteSprite(noteType, direction % Constants.KEY_COUNT);
        sprite.alpha = 0.3;

        final offsetX:Float = (direction < Constants.KEY_COUNT) ? -1 : 1;
        sprite.setPosition(snapX + offsetX, snapY);
        sprite.draw();
    }

    public function drawCursorEvent():Void {
        final snapMult:Float = ChartEditor.CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final snapY:Float = (FlxG.keys.pressed.SHIFT) ? charter._mousePos.y : Math.floor(charter._mousePos.y / snapMult) * snapMult;

        _addEventSprite.cameras = getCameras();
		_addEventSprite.alpha = 0.3;

        final offsetX:Float = -1;
        _addEventSprite.setPosition((x - _addEventSprite.width) + offsetX, snapY - (_addEventSprite.height * 0.5));
        _addEventSprite.draw();
    }

    public function checkSelection():Array<ChartEditorObject> {
        var selectedObjs:Array<ChartEditorObject> = [];
        for(note in notes) {
            final minX:Int = Std.int((charter.selectionBox.x - x) / ChartEditor.CELL_SIZE);
            final minY:Float = ((charter.selectionBox.y - y) / ChartEditor.CELL_SIZE) - 1;

            final maxX:Int = Std.int(Math.ceil(((charter.selectionBox.x + charter.selectionBox.width) - x) / ChartEditor.CELL_SIZE));
            final maxY:Float = (((charter.selectionBox.y + charter.selectionBox.height) - y) / ChartEditor.CELL_SIZE);

            if(note.data.direction >= minX && note.data.direction < maxX && note.step >= minY && note.step < maxY)
                selectedObjs.push(CNote(note));
        }
        final eventDirection:Int = -1;
        for(event in events) {
            final minX:Int = Std.int((charter.selectionBox.x - x) / ChartEditor.CELL_SIZE);
            final minY:Float = ((charter.selectionBox.y - y) / ChartEditor.CELL_SIZE) - 1;

            final maxX:Int = Std.int(Math.ceil(((charter.selectionBox.x + charter.selectionBox.width) - x) / ChartEditor.CELL_SIZE));
            final maxY:Float = (((charter.selectionBox.y + charter.selectionBox.height) - y) / ChartEditor.CELL_SIZE);

            if(eventDirection >= minX && eventDirection < maxX && event.step >= minY && event.step < maxY)
                selectedObjs.push(CEvent(event));
        }
        return selectedObjs;
    }

    override function destroy():Void {
		for (spr in _noteSpriteMap)
            spr.destroy();

        for(spr in _eventIconMap)
            spr.destroy();
        
        for(spr in _sustainMap)
            spr.destroy();

		_noteSpriteMap = null;
        _sustainMap = null;

        _eventBGSprite = FlxDestroyUtil.destroy(_eventBGSprite);
        _addEventSprite = FlxDestroyUtil.destroy(_addEventSprite);
        super.destroy();
    }

    //----------- [ Private API ] -----------//

    private var _eventBGSprite:SliceSprite;
    private var _addEventSprite:FlxSprite;

    private var _movingObjects:Bool = false;

    private var _lastDirection:Int = 0;
    private var _lastMouseY:Float = 0;

    private static function _getVarForEachNoteAdd(n:ChartEditorNote):Float {
		return n.step + n.stepLength;
    }

	private static function _getVarForEachNoteRemove(n:ChartEditorNote):Float {
		return n.step - n.stepLength;
    }

    private static function _getVarForEachEventAdd(n:ChartEditorEvent):Float {
		return n.step;
    }

	private static function _getVarForEachEventRemove(n:ChartEditorEvent):Float {
		return n.step;
    }

    /**
     * Contains a bunch of helper sprites used to render
     * the notes, the keys are the names of note types
     */
	private var _noteSpriteMap:Map<String, FlxSprite> = [];

    /**
     * Contains a bunch of helper sprites used to render
     * the event icons
     */
	private var _eventIconMap:Map<String, FlxSprite> = [];

    /**
     * Contains a bunch of helper sprites used to render
     * the notes, the keys are the names of note types
     */
    private var _sustainMap:Map<String, CharterSustain> = [];

	private function _getNoteSprite(noteType:String, direction:Int):FlxSprite {
		if (!_noteSpriteMap.exists(noteType)) {
            final sprite:FlxSprite = new FlxSprite();
            sprite.frames = Paths.getSparrowAtlas('editors/charter/images/notes');
            
            for(i in 0...Constants.KEY_COUNT)
                sprite.animation.addByPrefix(Constants.NOTE_DIRECTIONS[i], '${Constants.NOTE_DIRECTIONS[i]} scroll', 24, false);

            sprite.animation.play(Constants.NOTE_DIRECTIONS[0], true);
            sprite.setGraphicSize(ChartEditor.CELL_SIZE);
            sprite.updateHitbox();

            sprite.container = charter;
			_noteSpriteMap.set(noteType, sprite);
        }
		final sprite:FlxSprite = _noteSpriteMap.get(noteType);
        sprite.cameras = getCameras();
        sprite.animation.play(Constants.NOTE_DIRECTIONS[direction], true);
        return sprite;
    }

    private function _getEventIconSprite(spriteType:String):FlxSprite {
        if(!_eventIconMap.exists(spriteType)) {
            final sprite:FlxSprite = new FlxSprite();

            final iconPath:String = Paths.image('editors/charter/images/events/${spriteType}');
            if(FlxG.assets.exists(iconPath))
                sprite.loadGraphic(iconPath);
            else
                sprite.loadGraphic(Paths.image('editors/charter/images/events/Unknown'));

            sprite.antialiasing = false;
            sprite.setGraphicSize(20, 20);
            sprite.updateHitbox();
            
            _eventIconMap.set(spriteType, sprite);
        }
        final sprite:FlxSprite = _eventIconMap.get(spriteType);
        sprite.cameras = getCameras();
        return sprite;
    }

    private function _getSustain(noteType:String, direction:Int):CharterSustain {
        if(!_sustainMap.exists(noteType)) {
            final sprite:CharterSustain = new CharterSustain();
            _sustainMap.set(noteType, sprite);
        }
        final sprite:CharterSustain = _sustainMap.get(noteType);
        sprite.cameras = getCameras();
		sprite.updateSustain(direction, _getNoteSprite(noteType, direction).scale.x);
        return sprite;
    }
}