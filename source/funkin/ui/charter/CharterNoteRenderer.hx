package funkin.ui.charter;

import flixel.math.FlxRect;
import flixel.math.FlxPoint;

import flixel.util.FlxSignal;
import flixel.util.FlxDestroyUtil;

import funkin.utilities.SortedArrayUtil;

import funkin.gameplay.song.ChartData;
import funkin.states.editors.ChartEditor;

/**
 * A class specifically designed to render notes
 * in the chart editor.
 * 
 * This exists because syncing a bunch of individual
 * sprites to chart data is a pain in the ass!!
 * 
 * It also might have the benefit of running better too probably idk
 * 
 * NOTE: This does NOT support animations on the rendered notes!!
 */
// TODO: sustain support :p
@:allow(funkin.states.editors.ChartEditor)
class CharterNoteRenderer extends FlxObject {
    public var charter(default, null):ChartEditor;

    public var onNoteHit(default, null):FlxTypedSignal<ChartEditorNote->Void> = new FlxTypedSignal<ChartEditorNote->Void>(); 
    public var onEmptyCellClick(default, null):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>(); 
    public var onNoteClick(default, null):FlxTypedSignal<ChartEditorNote->Void> = new FlxTypedSignal<ChartEditorNote->Void>(); 
    public var onNoteRightClick(default, null):FlxTypedSignal<ChartEditorNote->Void> = new FlxTypedSignal<ChartEditorNote->Void>(); 

    /**
     * The notes from the chart that will directly
     * be rendered onto this object.
     */
    public var notes:Array<ChartEditorNote> = [];

    public var isHoveringNote:Bool = false;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y, 1, 1);
        charter = cast FlxG.state;
    }

    override function update(elapsed:Float) {
        final direction:Int = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
        if(_movingObjects) {
            final snapMult:Float = ChartEditor.CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
            final snapY:Float = (FlxG.keys.pressed.SHIFT) ? charter._mousePos.y : Math.floor(charter._mousePos.y / snapMult) * snapMult;
            
            if(FlxG.mouse.justReleased)
                _movingObjects = false;
            
            for(object in charter.selectedObjects) {
                switch(object) {
                    case CNote(note):
                        note.data.direction = FlxMath.boundInt(note.lastDirection + (direction - _lastDirection), 0, (Constants.KEY_COUNT * 2) - 1);
                        
                        final newStep:Float = note.lastStep + (charter._mousePos.y - _lastMouseY);
                        note.step = Math.max((FlxG.keys.pressed.SHIFT) ? (newStep / ChartEditor.CELL_SIZE) : (Math.floor(newStep / snapMult) * snapMult) / ChartEditor.CELL_SIZE, 0);

                        if(!_movingObjects)
                            note.data.time = Conductor.instance.getTimeAtStep(note.step);

                    default:
                        continue;
                }
            }
            return;
        }
        if(direction >= 0 && direction < (Constants.KEY_COUNT * 2) && ((FlxG.mouse.pressed && FlxG.mouse.justMoved) || FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight)) {
            final max:Float = FlxG.height / 70 / getDefaultCamera().zoom;
    
            final begin:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep - max, _getVarForEachAdd);
            final end:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep + max, _getVarForEachRemove);
    
            var note:ChartEditorNote = null;
            var sprite:FlxSprite = null;
    
            var isEmptyCell:Bool = true;
            for(i in begin...end) {
                note = notes[i];
                
                sprite = _getSprite(note.data.type, note.data.direction % Constants.KEY_COUNT);
                sprite.setPosition(x + (ChartEditor.CELL_SIZE * direction), y + (ChartEditor.CELL_SIZE * note.step));
            
                if(FlxG.mouse.overlaps(sprite)) {
                    isHoveringNote = true;
                    if(FlxG.mouse.pressed && FlxG.mouse.justMoved && note.selected && !charter.selectionBox.exists) {
                        for(object in charter.selectedObjects) {
                            switch(object) {
                                case CNote(note):
                                    note.lastStep = note.step * ChartEditor.CELL_SIZE;
                                    note.lastDirection = note.data.direction;
            
                                default:
                                    continue;
                            }
                        }
                        _lastDirection = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
                        _lastMouseY = sprite.y;

                        _movingObjects = true;
                        return;
                    }
                    else if(FlxG.mouse.justReleased)
                        onNoteClick.dispatch(note);

                    else if(FlxG.mouse.justReleasedRight)
                        onNoteRightClick.dispatch(note);
                    
                    isEmptyCell = false;
                    break;
                }
            }
            if(isEmptyCell && FlxG.mouse.justReleased && !charter.selectionBox.exists)
                onEmptyCellClick.dispatch();
        }
        else
            isHoveringNote = false;
    }

    override function draw():Void {
        // draw all of the notes in the chart
        final max:Float = FlxG.height / 70 / getDefaultCamera().zoom;

        final begin:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep - max, _getVarForEachAdd);
        final end:Int = SortedArrayUtil.binarySearch(notes, Conductor.instance.curStep + max, _getVarForEachRemove);
        
        var note:ChartEditorNote = null;
        var sprite:FlxSprite = null;
        var sustain:CharterSustain = null;

        for(i in begin...end) {
            note = notes[i];

            sprite = _getSprite(note.data.type, note.data.direction % Constants.KEY_COUNT);
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
            sustain.height = note.stepLength * ChartEditor.CELL_SIZE;
            
            sustain.setPosition(x + (ChartEditor.CELL_SIZE * note.data.direction) + ((ChartEditor.CELL_SIZE - sustain.strip.width) * 0.5) + offsetX, y + (ChartEditor.CELL_SIZE * note.step) + (ChartEditor.CELL_SIZE * 0.5));
            sustain.draw();

            final colorOffset:Float = (note.selected) ? 65 : 0;
            sprite.colorTransform.redOffset = sprite.colorTransform.greenOffset = sprite.colorTransform.blueOffset = colorOffset;
            
            sprite.setPosition(x + (ChartEditor.CELL_SIZE * note.data.direction) + offsetX, y + (ChartEditor.CELL_SIZE * note.step));
            sprite.draw();
        }

        // draw the cursor note
        final direction:Int = Math.floor((charter._mousePos.x - x) / ChartEditor.CELL_SIZE);
        if(!charter.selectionBox.exists && direction >= 0 && direction < (Constants.KEY_COUNT * 2))
            drawCursorNote(charter.noteTypes[charter.curNoteType], direction);
    }

    public function drawCursorNote(noteType:String, direction:Int):Void {
        final snapX:Int = Math.floor(charter._mousePos.x / ChartEditor.CELL_SIZE) * ChartEditor.CELL_SIZE;

        final snapMult:Float = ChartEditor.CELL_SIZE * (16 / ChartEditor.editorSettings.gridSnap);
        final snapY:Float = (FlxG.keys.pressed.SHIFT) ? charter._mousePos.y : Math.floor(charter._mousePos.y / snapMult) * snapMult;

        final sprite:FlxSprite = _getSprite(noteType, direction % Constants.KEY_COUNT);
        sprite.alpha = 0.3;
        sprite.setPosition(snapX, snapY);
        sprite.draw();
    }

    public function checkSelection():Array<ChartEditorObject> {
        var sprite:FlxSprite = null;
        var selectedObjs:Array<ChartEditorObject> = [];

        for(note in notes) {
            sprite = _getSprite(note.data.type, note.data.direction % Constants.KEY_COUNT);
            sprite.setPosition(x + (ChartEditor.CELL_SIZE * note.data.direction), y + (ChartEditor.CELL_SIZE * note.step));

            final minX:Int = Std.int((charter.selectionBox.x - x) / ChartEditor.CELL_SIZE);
            final minY:Float = ((charter.selectionBox.y - y) / ChartEditor.CELL_SIZE) - 1;

            final maxX:Int = Std.int(Math.ceil(((charter.selectionBox.x + charter.selectionBox.width) - x) / ChartEditor.CELL_SIZE));
            final maxY:Float = (((charter.selectionBox.y + charter.selectionBox.height) - y) / ChartEditor.CELL_SIZE);

            if(note.data.direction >= minX && note.data.direction < maxX && note.step >= minY && note.step < maxY)
                selectedObjs.push(CNote(note));
        }
        return selectedObjs;
    }

    override function destroy():Void {
        for(spr in _spriteMap)
            spr.destroy();

        for(spr in _sustainMap)
            spr.destroy();

        _spriteMap = null;
        _sustainMap = null;

        super.destroy();
    }

    //----------- [ Private API ] -----------//

    private var _movingObjects:Bool = false;

    private var _lastDirection:Int = 0;
    private var _lastMouseY:Float = 0;

    private static function _getVarForEachAdd(n:ChartEditorNote):Float {
		return n.step + n.stepLength;
    }

	private static function _getVarForEachRemove(n:ChartEditorNote):Float {
		return n.step - n.stepLength;
    }

    /**
     * Contains a bunch of helper sprites used to render
     * the notes, the keys are the names of note types
     */
    private var _spriteMap:Map<String, FlxSprite> = [];

    /**
     * Contains a bunch of helper sprites used to render
     * the notes, the keys are the names of note types
     */
    private var _sustainMap:Map<String, CharterSustain> = [];

    private function _getSprite(noteType:String, direction:Int):FlxSprite {
        if(!_spriteMap.exists(noteType)) {
            final sprite:FlxSprite = new FlxSprite();
            sprite.frames = Paths.getSparrowAtlas('editors/charter/images/notes');
            
            for(i in 0...Constants.KEY_COUNT)
                sprite.animation.addByPrefix(Constants.NOTE_DIRECTIONS[i], '${Constants.NOTE_DIRECTIONS[i]} scroll', 24, false);

            sprite.animation.play(Constants.NOTE_DIRECTIONS[0], true);
            sprite.setGraphicSize(ChartEditor.CELL_SIZE);
            sprite.updateHitbox();

            _spriteMap.set(noteType, sprite);
        }
        final sprite:FlxSprite = _spriteMap.get(noteType);
        sprite.cameras = getCameras();
        sprite.animation.play(Constants.NOTE_DIRECTIONS[direction], true);
        return sprite;
    }

    private function _getSustain(noteType:String, direction:Int):CharterSustain {
        if(!_sustainMap.exists(noteType)) {
            final sprite:CharterSustain = new CharterSustain();
            _sustainMap.set(noteType, sprite);
        }
        final sprite:CharterSustain = _sustainMap.get(noteType);
        sprite.cameras = getCameras();
        sprite.updateSustain(direction, _getSprite(noteType, direction).scale.x);
        return sprite;
    }
}