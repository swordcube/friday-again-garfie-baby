package funkin.gameplay.notes;

import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.gameplay.song.NoteData;

import funkin.backend.events.Events;
import funkin.backend.events.NoteEvents;

class NoteSpawner extends FlxBasic {
    public var playField:PlayField;

    public var curNoteIndex:Int = 0;
    public var pendingNotes(default, set):Array<NoteData> = [];

    public var onNoteSpawn:FlxTypedSignal<NoteSpawnEvent->Void> = new FlxTypedSignal<NoteSpawnEvent->Void>();
    public var onNoteSpawnPost:FlxTypedSignal<NoteSpawnEvent->Void> = new FlxTypedSignal<NoteSpawnEvent->Void>();

    public function new(playField:PlayField) {
        super();
        this.playField = playField;

        visible = false;
    }

    public function skipToTime(time:Float):Void {
        curNoteIndex = 0;
        while(curNoteIndex < pendingNotes.length && pendingNotes[curNoteIndex].time < time - 0.01)
            ++curNoteIndex;
    }

    override function update(elapsed:Float) {
        if(pendingNotes.length == 0)
            return;

        while(curNoteIndex < pendingNotes.length) {
            final noteData:NoteData = pendingNotes[curNoteIndex];
            final strumLine:StrumLine = (noteData.direction < Constants.KEY_COUNT) ? playField.opponentStrumLine : playField.playerStrumLine;
            
            if(playField.attachedConductor.time < noteData.time - (1500 / (strumLine.scrollSpeed / FlxG.timeScale)))
                break;

            final event:NoteSpawnEvent = cast Events.get(NOTE_SPAWN);
            event.recycle(noteData, null, noteData.time, noteData.direction, noteData.length, noteData.type);
            onNoteSpawn.dispatch(event);
            
            if(event.cancelled) {
                ++curNoteIndex;
                continue;
            }
            final note:Note = strumLine.notes.recycle(_noteFactory);
            note.stepLength = playField.attachedConductor.stepLength;
            
            if(note.length <= 0)
                note.holdTrail.kill();
            else
                note.holdTrail.revive();
            
            var length:Float = noteData.length - playField.attachedConductor.stepLength;
            if(length <= playField.attachedConductor.stepLength)
                length = 0;
            
            note.setup(strumLine, noteData.time, noteData.direction, length, noteData.type, strumLine.strums.members[noteData.direction % Constants.KEY_COUNT].skin);
            
            if(!strumLine.holdTrails.members.contains(note.holdTrail))
                strumLine.holdTrails.add(note.holdTrail);
            
            ++curNoteIndex;

            event.note = note;
            onNoteSpawnPost.dispatch(cast event.flagAsPost());
        }
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function _noteFactory():Note {
        return new Note(-999999, -999999);
    }

    @:noCompletion
    private function set_pendingNotes(newPendingNotes:Array<NoteData>):Array<NoteData> {
        newPendingNotes.sort((a, b) -> Std.int(a.time - b.time));
        return pendingNotes = newPendingNotes;
    }
}