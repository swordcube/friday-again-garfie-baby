package funkin.gameplay.notes;

import funkin.gameplay.song.ChartData.NoteData;

class NoteSpawner extends FlxBasic {
    public var playField:PlayField;

    public var curNoteIndex:Int = 0;
    public var pendingNotes(default, set):Array<NoteData> = [];

    public function new(playField:PlayField) {
        super();
        this.playField = playField;

        visible = false;
    }

    override function update(elapsed:Float) {
        if(pendingNotes.length == 0)
            return;

        while(curNoteIndex < pendingNotes.length) {
            final noteData:NoteData = pendingNotes[curNoteIndex];
            final strumLine:StrumLine = (noteData.direction < 4) ? playField.opponentStrumLine : playField.playerStrumLine;
            
            if(playField.attachedConductor.time < noteData.time - (1500 / strumLine.scrollSpeed))
                break;
            
            final note:Note = strumLine.notes.recycle(_noteFactory);
            note.stepLength = 100;//playField.attachedConductor.stepLength;
            note.setup(strumLine, noteData.time, noteData.direction, noteData.length - playField.attachedConductor.stepLength, noteData.type, strumLine.strums.members[noteData.direction % Constants.KEY_COUNT].skin);
            
            if(!strumLine.holdTrails.members.contains(note.holdTrail))
                strumLine.holdTrails.add(note.holdTrail);

            ++curNoteIndex;
        }
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function _noteFactory():Note {
        return new Note(-999999, -999999);
    }

    @:noCompletion
    private function _holdTrailFactory():HoldTrail {
        return new HoldTrail(-999999, -999999);
    }

    @:noCompletion
    private function set_pendingNotes(newPendingNotes:Array<NoteData>):Array<NoteData> {
        newPendingNotes.sort((a, b) -> Std.int(a.time - b.time));
        return pendingNotes = newPendingNotes;
    }
}