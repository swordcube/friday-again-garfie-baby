package funkin.gameplay;

import flixel.util.FlxSort;

import funkin.gameplay.hud.BaseHUD;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.StrumLine;
import funkin.gameplay.notes.NoteSpawner;

import funkin.gameplay.song.Chart.NoteData;
import funkin.gameplay.song.Chart.ChartData;

class PlayField extends FlxGroup {
    public var opponentStrumLine:StrumLine;
    public var playerStrumLine:StrumLine;

    public var hud:BaseHUD;

    public var currentChart:ChartData;
    public var currentDifficulty:String;

    public var noteSpawner:NoteSpawner;
    public var attachedConductor:Conductor = Conductor.instance;

    public var controls:Array<Control> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];

    public function new(chart:ChartData, difficulty:String) {
        super();
        currentChart = chart;
        currentDifficulty = difficulty;

        memberAdded.add((m) -> {
            if(m is StrumLine) {
                final strumLine:StrumLine = cast m;
                strumLine.playField = this;
            }
        });
        memberRemoved.add((m) -> {
            if(m is StrumLine) {
                final strumLine:StrumLine = cast m;
                strumLine.playField = null;
            }
        });
        opponentStrumLine = new StrumLine(FlxG.width * 0.25, 50, Options.downscroll, true, "funkin");
        opponentStrumLine.scrollSpeed = currentChart.meta.game.scrollSpeed.get(currentDifficulty) ?? currentChart.meta.game.scrollSpeed.get("default");
        add(opponentStrumLine);

        playerStrumLine = new StrumLine(FlxG.width * 0.75, 50, Options.downscroll, false, "funkin");
        playerStrumLine.scrollSpeed = currentChart.meta.game.scrollSpeed.get(currentDifficulty) ?? currentChart.meta.game.scrollSpeed.get("default");
        add(playerStrumLine);

        for(strumLine in [opponentStrumLine, playerStrumLine]) {
            if(Options.downscroll)
                strumLine.y = FlxG.height - strumLine.strums.height - strumLine.y;
            
            for(i in 0...strumLine.strums.length) {
                final strum:Strum = strumLine.strums.members[i];
                strum.y -= 10;
                strum.alpha = 0.001;
                FlxTween.tween(strum, {alpha: 1, y: strum.y + 10}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
            }
        }
        noteSpawner = new NoteSpawner(this);
        noteSpawner.pendingNotes = currentChart.notes.get(currentDifficulty);
        add(noteSpawner);
    }

    override function update(elapsed:Float) {
        if(!playerStrumLine.botplay) {
            final controls:Controls = Controls.instance;
            for(i in 0...this.controls.length) {
                final control:Control = this.controls[i];
                if(controls.justPressed.check(control))
                    onNotePress(i);
                
                if(controls.justReleased.check(control))
                    onNoteRelease(i);
            }
        }
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private function onNotePress(direction:Int):Void {
        final strum:Strum = playerStrumLine.strums.members[direction];
        strum.animation.play('${Constants.NOTE_DIRECTIONS[direction]} press');

        final validNotes:Array<Note> = playerStrumLine.notes.members.filter((note:Note) -> {
            return note.exists && note.alive && !note.wasHit && !note.wasMissed && note.direction == direction && note.isInRange();
        });
        if(validNotes.length == 0)
            return;

        validNotes.sort(noteInputSort);
        playerStrumLine.hitNote(validNotes[0]);
    }
    
    private function onNoteRelease(direction:Int):Void {
        final strum:Strum = playerStrumLine.strums.members[direction];
        strum.animation.play('${Constants.NOTE_DIRECTIONS[direction]} static');

        final validNotes:Array<Note> = playerStrumLine.notes.members.filter((note:Note) -> {
            return note.exists && note.alive && note.wasHit && !note.wasMissed && note.direction == direction && note.time > attachedConductor.time - (note.length - 200);
        });
        if(validNotes.length == 0)
            return;

        for(i in 0...validNotes.length)
            playerStrumLine.missNote(validNotes[i]);
    }

    private function noteInputSort(a:Note, b:Note):Int {
        return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    }
}