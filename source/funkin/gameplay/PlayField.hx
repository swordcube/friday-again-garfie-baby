package funkin.gameplay;

import flixel.util.FlxSort;
import flixel.util.FlxSignal;

import funkin.gameplay.hud.BaseHUD;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.StrumLine;
import funkin.gameplay.notes.NoteSpawner;

import funkin.gameplay.song.ChartData.NoteData;
import funkin.gameplay.song.ChartData.ChartData;

import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.notes.*;

import funkin.gameplay.scoring.Scoring;

class PlayField extends FlxGroup {
    public var opponentStrumLine:StrumLine;
    public var playerStrumLine:StrumLine;

    public var stats:PlayerStats;
    public var hud:BaseHUD;

    public var currentChart:ChartData;
    public var currentDifficulty:String;

    public var noteSpawner:NoteSpawner;
    public var attachedConductor:Conductor = Conductor.instance;

    public var onNoteHit:FlxTypedSignal<NoteHitEvent->Void> = new FlxTypedSignal<NoteHitEvent->Void>();
    public var onNoteHitPost:FlxTypedSignal<NoteHitEvent->Void> = new FlxTypedSignal<NoteHitEvent->Void>();
    
    public var onNoteMiss:FlxTypedSignal<NoteMissEvent->Void> = new FlxTypedSignal<NoteMissEvent->Void>();
    public var onNoteMissPost:FlxTypedSignal<NoteMissEvent->Void> = new FlxTypedSignal<NoteMissEvent->Void>();

    public var strumsPressed:Array<Bool> = [false, false, false, false];
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

        stats = new PlayerStats();
    }

    public function hitNote(note:Note):Void {
        final event:NoteHitEvent = Events.get(NOTE_HIT);

        final timestamp:Float = attachedConductor.time;
        final judgement:String = Scoring.judgeNote(note, timestamp);

        final isPlayer:Bool = note.strumLine == playerStrumLine;
        onNoteHit.dispatch(event.recycle(
            note, note.time, note.direction, note.length, note.type,
            true, false, judgement, isPlayer, !isPlayer,
            Scoring.scoreNote(note, timestamp), Scoring.getAccuracyScore(judgement), 0.0115,
            Scoring.holdHealthIncreasingAllowed(), Scoring.holdScoreIncreasingAllowed(), true, true, null
        ));
        if(event.cancelled)
            return;
        
        event.note.wasHit = true;
        event.note.wasMissed = false;
        event.note.hitEvent = event;
        
        final isPlayer:Bool = event.note.strumLine == playerStrumLine;
        if(event.note.length <= 0)
            killNote(event.note);
        else
            event.note.colorTransform.redOffset = event.note.colorTransform.greenOffset = event.note.colorTransform.blueOffset = 45;
        
        if(isPlayer) {
            stats.score += event.score;
            stats.health += event.healthGain;
        }
        if(event.increaseCombo)
            stats.combo++;
        
        if(event.hitCausesMiss) {
            event.note.wasHit = false;
            missNote(event.note);
        }
        else if(isPlayer) {
            stats.accuracyScore += event.accuracyScore;
            stats.totalNotesHit++;
        }
        if(event.showRating) {
            // TODO: this shit
        }
        if(event.showCombo) {
            // TODO: this shit
        }
        if(event.playConfirmAnim) {
            final strum:Strum = event.note.strumLine.strums.members[event.direction];
            strum.holdTime = Math.max(event.note.length, (event.note.strumLine.botplay) ? attachedConductor.stepLength : 250);
            strum.animation.play('${Constants.NOTE_DIRECTIONS[event.direction]} confirm', true);
        }
        if(event.note.strumLine == playerStrumLine && hud != null) {
            hud.updateHealthBar();
            hud.updatePlayerStats();
        }
        onNoteHitPost.dispatch(cast event.flagAsPost());
    }

    public function killNote(note:Note):Void {
        note.kill();
        note.holdTrail.kill();
    }

    public function missNote(note:Note):Void {
        final event:NoteMissEvent = Events.get(NOTE_MISS);
        onNoteMiss.dispatch(event.recycle(
            note, note.time, note.direction, note.length, note.type,
            true, true, note.strumLine == playerStrumLine, note.strumLine == playerStrumLine,
            10, 0.02375 + (Math.min(note.length * 0.001, 0.25) * 0.5), true, null
        ));
        if(event.cancelled)
            return;

        event.note.wasHit = false;
        event.note.wasMissed = true;
        event.note.missEvent = event;

        final isPlayer:Bool = event.note.strumLine == playerStrumLine;
        if(isPlayer) {
            stats.score -= event.score;
            stats.health -= event.healthLoss;

            if(event.resetCombo)
                stats.combo = 0;
    
            if(event.countAsMiss)
                stats.missCombo++;
        }
        if(event.showRating) {
            // TODO: this shit
        }
        if(event.showCombo) {
            // TODO: this shit
        }

        // the note is now cum colored
        event.note.colorTransform.redOffset = event.note.colorTransform.greenOffset = event.note.colorTransform.blueOffset = 200;

        event.note.holdTrail.strip.colorTransform.redOffset = event.note.holdTrail.strip.colorTransform.greenOffset = event.note.holdTrail.strip.colorTransform.blueOffset = 200;
        event.note.holdTrail.tail.colorTransform.redOffset = event.note.holdTrail.tail.colorTransform.greenOffset = event.note.holdTrail.tail.colorTransform.blueOffset = 200;
        
        event.note.alpha = 0.3;
        event.note.holdTrail.alpha = 0.3;

        if(event.note.strumLine == playerStrumLine && hud != null) {
            hud.updateHealthBar();
            hud.updatePlayerStats();
        }
        onNoteMissPost.dispatch(cast event.flagAsPost());
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

                strumsPressed[i] = controls.pressed.check(control);
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
        hitNote(validNotes[0]);
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
            missNote(validNotes[i]);
    }

    private function noteInputSort(a:Note, b:Note):Int {
        return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    }
}