package funkin.gameplay;

import flixel.util.FlxSort;
import flixel.util.FlxSignal;

import funkin.gameplay.ComboDisplay;
import funkin.gameplay.hud.BaseHUD;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.NoteSkin;
import funkin.gameplay.notes.StrumLine;
import funkin.gameplay.notes.NoteSpawner;

import funkin.gameplay.song.NoteData;
import funkin.gameplay.song.EventData;
import funkin.gameplay.song.ChartData;

import funkin.backend.events.Events;
import funkin.backend.events.GameplayEvents;
import funkin.backend.events.NoteEvents;

import funkin.states.PlayState;
import funkin.gameplay.scoring.Scoring;

class PlayField extends FlxContainer {
    public var strumLines:FlxTypedGroup<StrumLine>;

    public var opponentStrumLine:StrumLine;
    public var playerStrumLine:StrumLine;

    public var stats:PlayerStats;
    public var hud:BaseHUD;

    public var hitSound:FlxSound;
    public var missSounds:Map<String, Array<FlxSound>> = [];
    public var curMissSound:Int = 0;

    public var comboDisplay:ComboDisplay;

    public var currentChart:ChartData;
    public var currentDifficulty:String;

    public var noteSpawner:NoteSpawner;
    public var attachedConductor:Conductor = Conductor.instance;

    public var onNoteHit:FlxTypedSignal<NoteHitEvent->Void> = new FlxTypedSignal<NoteHitEvent->Void>();
    public var onNoteHitPost:FlxTypedSignal<NoteHitEvent->Void> = new FlxTypedSignal<NoteHitEvent->Void>();
    
    public var onNoteMiss:FlxTypedSignal<NoteMissEvent->Void> = new FlxTypedSignal<NoteMissEvent->Void>();
    public var onNoteMissPost:FlxTypedSignal<NoteMissEvent->Void> = new FlxTypedSignal<NoteMissEvent->Void>();

    public var onDisplayRating:FlxTypedSignal<DisplayRatingEvent->Void> = new FlxTypedSignal<DisplayRatingEvent->Void>();
    public var onDisplayRatingPost:FlxTypedSignal<DisplayRatingEvent->Void> = new FlxTypedSignal<DisplayRatingEvent->Void>();

    public var onDisplayCombo:FlxTypedSignal<DisplayComboEvent->Void> = new FlxTypedSignal<DisplayComboEvent->Void>();
    public var onDisplayComboPost:FlxTypedSignal<DisplayComboEvent->Void> = new FlxTypedSignal<DisplayComboEvent->Void>();

    public var onUpdateStats:FlxTypedSignal<PlayerStats->Void> = new FlxTypedSignal<PlayerStats->Void>();

    public var strumsPressed:Array<Bool> = [false, false, false, false];
    public var controls:Array<Control> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];

    public function new(chart:ChartData, difficulty:String, ?noteSkin:String, ?uiSkin:String) {
        super();
        currentChart = chart;
        currentDifficulty = difficulty;

        var scrollSpeed:Float = currentChart.meta.game.scrollSpeed.get(currentDifficulty) ?? currentChart.meta.game.scrollSpeed.get("default");
        switch(Std.string(Options.gameplayModifiers.get("scrollType")).toLowerCase()) {
            case "multiplicative", "mult":
                final mult:Float = cast Options.gameplayModifiers.get("scrollSpeed");
                scrollSpeed *= mult;
                
            case "constant", "cmod":
                final value:Float = cast Options.gameplayModifiers.get("scrollSpeed");
                scrollSpeed = value;

            case "xmod", "bpm":
                final bpm:Float = currentChart.meta.song.timingPoints.first()?.bpm ?? 100.0;
                scrollSpeed = bpm / 60.0;
        }
        final noteSkinData:NoteSkinData = NoteSkin.get(noteSkin ?? currentChart.meta.game.noteSkin);

        strumLines = new FlxTypedGroup<StrumLine>();
        strumLines.memberAdded.add((m) -> {
            m.playField = this;
        });
        strumLines.memberRemoved.add((m) -> {
            m.playField = null;
        });
        add(strumLines);

        opponentStrumLine = new StrumLine(FlxG.width * 0.25, noteSkinData.baseStrumY, Options.downscroll, true, noteSkin ?? currentChart.meta.game.noteSkin);
        opponentStrumLine.scrollSpeed = scrollSpeed;
        strumLines.add(opponentStrumLine);

        playerStrumLine = new StrumLine(FlxG.width * 0.75, noteSkinData.baseStrumY, Options.downscroll, false, noteSkin ?? currentChart.meta.game.noteSkin);
        playerStrumLine.scrollSpeed = scrollSpeed;
        playerStrumLine.isPlayer = true;
        strumLines.add(playerStrumLine);
        
        if(Options.centeredNotes) {
            opponentStrumLine.visible = false;
            playerStrumLine.x = FlxG.width * 0.5;
        }
        hitSound = new FlxSound();
        hitSound.loadEmbedded(Options.getHitsoundPath());
        hitSound.volume = Options.hitsoundVolume;
        FlxG.sound.list.add(hitSound);

        for(i in 0...3) {
            final sndKey:String = 'gameplay/sfx/missnote${i + 1}';
            final sndPath:String = Paths.sound(sndKey);
            if(FlxG.assets.exists(sndPath)) {
                final sounds:Array<FlxSound> = [];
                for(i in 0...3) {
                    final sound:FlxSound = new FlxSound();
                    sound.loadEmbedded(sndPath);
                    FlxG.sound.list.add(sound);
                    sounds.push(sound);
                }
                missSounds.set(sndKey, sounds);
            }
        }
        comboDisplay = new ComboDisplay(FlxG.width * 0.474, (FlxG.height * 0.45) - 60, uiSkin ?? currentChart.meta.game.uiSkin);
        add(comboDisplay);

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
        stats.playField = this;
    }

    public inline function getFirstStrumLine():StrumLine {
        return strumLines.members[0];
    }

    public inline function getSecondStrumLine():StrumLine {
        return (strumLines.length > 1) ? strumLines.members[1] : strumLines.members[0];
    }

    public function hitNote(note:Note):Void {
        final event:NoteHitEvent = note.hitEvent; 

        final timestamp:Float = (note.strumLine.botplay) ? note.time : attachedConductor.time;
        final judgement:String = Scoring.judgeNote(note, timestamp);

        final score:Int = Scoring.scoreNote(note, timestamp);
        final savedRate:Float = (!(PlayState.instance?.isStoryMode ?? false)) ? Options.gameplayModifiers.get("playbackRate") : 1;

        final isPlayer:Bool = note.strumLine == playerStrumLine;
        onNoteHit.dispatch(event.recycle(
            note, note.time, note.direction, note.length, note.type,
            isPlayer, false, judgement, isPlayer && Scoring.splashAllowed(judgement), true, true, isPlayer, isPlayer,
            (savedRate >= 1) ? score : Std.int(score * savedRate), Scoring.getAccuracyScore(judgement), 0.0115,
            Scoring.holdHealthIncreasingAllowed(), Scoring.holdScoreIncreasingAllowed(),
            true, true, true, null, "", isPlayer && (Options.hitsoundBehavior == "Note Hit" || (playerStrumLine.botplay && Options.hitsoundBehavior == "Key Press"))
        ));
        if(event.cancelled)
            return;
        
        event.note.wasHit = true;
        event.note.wasMissed = false;
        
        final isPlayer:Bool = event.note.strumLine == playerStrumLine;
        if(event.note.length <= 0)
            killNote(event.note);
        else
            event.note.visible = false;
        
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
            stats.judgements.set(event.rating, stats.judgements.get(event.rating) + 1);
        }
        if(event.showRating) {
            final e:DisplayRatingEvent = cast Events.get(DISPLAY_RATING);
            onDisplayRating.dispatch(e.recycle(event.rating, null));

            if(!e.cancelled) {
                e.sprite = comboDisplay.displayRating(e.rating);
                onDisplayRatingPost.dispatch(cast e.flagAsPost());
            }
        }
        if(event.showCombo) {
            final e:DisplayComboEvent = cast Events.get(DISPLAY_COMBO);
            onDisplayCombo.dispatch(e.recycle(stats.combo, null));

            if(!e.cancelled) {
                e.sprites = comboDisplay.displayCombo(e.combo);
                onDisplayComboPost.dispatch(cast e.flagAsPost());
            }
        }
        if(event.showSplash)
            event.note.strumLine.showSplash(event.direction);

        if(event.playHitSound && Options.hitsoundVolume > 0) {
            hitSound.time = 0;
            hitSound.play(true);
        }
        if(event.showHoldCovers && event.length > 0)
            event.note.strumLine.showHoldCover(event.direction);
        else
            event.note.strumLine.holdCovers.members[event.direction].kill();
        
        if(event.showHoldGradients && event.length > 0)
            event.note.strumLine.showHoldGradient(event.direction);
        else
            event.note.strumLine.holdGradients.members[event.direction].holding = false;

        if(event.playConfirmAnim) {
            final strum:Strum = event.note.strumLine.strums.members[event.direction];
            strum.holdTime = Math.max(event.note.length, (event.note.strumLine.botplay) ? attachedConductor.stepLength : 250);
            strum.animation.play('${Constants.NOTE_DIRECTIONS[event.direction]} confirm', true);
        }
        if(event.note.strumLine == playerStrumLine && hud != null) {
            hud.updateHealthBar();
            hud.updatePlayerStats(stats);
        }
        onUpdateStats.dispatch(stats);
        onNoteHitPost.dispatch(cast event.flagAsPost());
    }

    public function killNote(note:Note):Void {
        note.kill();
        note.holdTrail.kill();
        note.strumLine.holdGradients.members[note.direction].kill();
    }

    public function missNote(note:Note):Void {
        final event:NoteMissEvent = note.missEvent;
        onNoteMiss.dispatch(event.recycle(
            note, note.time, note.direction, note.length, note.type,
            true, true, note.strumLine == playerStrumLine, note.strumLine == playerStrumLine,
            100, 0.02375 + (Math.min(note.length * 0.001, 0.25) * 0.5), true, true, null, "",
            Options.missSounds && FlxG.state == PlayState.instance, 'gameplay/sfx/missnote${FlxG.random.int(1, 3)}', FlxG.random.float(0.75, 0.9)
        ));
        if(event.cancelled)
            return;

        event.note.wasHit = false;
        event.note.wasMissed = true;

        final isPlayer:Bool = event.note.strumLine == playerStrumLine;
        if(isPlayer) {
            stats.score -= event.score;
            stats.health -= event.healthLoss;

            if(event.resetCombo)
                stats.combo = 0;
    
            if(event.countAsMiss) {
                stats.misses++;
                stats.missCombo++;
            }
        }
        if(event.length > 0) {
            event.note.strumLine.holdGradients.members[event.direction].holding = false;
            event.note.strumLine.holdCovers.members[event.direction].kill();
        }
        if(event.showRating) {
            final e:DisplayRatingEvent = cast Events.get(DISPLAY_RATING);
            onDisplayRating.dispatch(e.recycle("miss", null));

            if(!e.cancelled) {
                e.sprite = comboDisplay.displayRating(e.rating);
                onDisplayRatingPost.dispatch(cast e.flagAsPost());
            }
        }
        if(event.showCombo) {
            final e:DisplayComboEvent = cast Events.get(DISPLAY_COMBO);
            onDisplayCombo.dispatch(e.recycle(-stats.missCombo, null));

            if(!e.cancelled) {
                e.sprites = comboDisplay.displayCombo(e.combo);
                onDisplayComboPost.dispatch(cast e.flagAsPost());
            }
        }
        if(event.playMissSound) {
            final soundList:Array<FlxSound> = missSounds.get(event.missSound);
            final sound:FlxSound = soundList[(curMissSound + 1) % soundList.length];
            if(sound != null) {
                sound.volume = event.missVolume;
                sound.time = 0;
                sound.play(true);
            } else
                FlxG.sound.play(Paths.sound(event.missSound), event.missVolume);
        }
        // the note is now cum colored
        event.note.colorTransform.redOffset = event.note.colorTransform.greenOffset = event.note.colorTransform.blueOffset = 200;

        event.note.holdTrail.strip.colorTransform.redOffset = event.note.holdTrail.strip.colorTransform.greenOffset = event.note.holdTrail.strip.colorTransform.blueOffset = 200;
        event.note.holdTrail.tail.colorTransform.redOffset = event.note.holdTrail.tail.colorTransform.greenOffset = event.note.holdTrail.tail.colorTransform.blueOffset = 200;
        
        event.note.alpha = 0.3;
        event.note.holdTrail.alpha = 0.3;

        if(event.note.strumLine == playerStrumLine && hud != null) {
            hud.updateHealthBar();
            hud.updatePlayerStats(stats);
        }
        onUpdateStats.dispatch(stats);
        onNoteMissPost.dispatch(cast event.flagAsPost());
    }

    override function update(elapsed:Float) {
        for(strumLine in strumLines) {
            if(!strumLine.botplay) {
                final controls:Controls = Controls.instance;
                for(i in 0...this.controls.length) {
                    final control:Control = this.controls[i];
                    if(controls.justPressed.check(control))
                        onNotePress(strumLine, i);
                    
                    if(controls.justReleased.check(control))
                        onNoteRelease(strumLine, i);
    
                    strumsPressed[i] = controls.pressed.check(control);
                }
            }
        }
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private function onNotePress(strumLine:StrumLine, direction:Int):Void {
        final strum:Strum = strumLine.strums.members[direction];
        strum.animation.play('${Constants.NOTE_DIRECTIONS[direction]} press');

        if(Options.hitsoundBehavior == "Key Press" && Options.hitsoundVolume > 0) {
            hitSound.time = 0;
            hitSound.play(true);
        }
        final validNotes:Array<Note> = strumLine.notes.members.filter((note:Note) -> {
            return note.exists && note.alive && !note.wasHit && !note.wasMissed && note.direction == direction && note.isInRange();
        });
        if(validNotes.length == 0)
            return;

        validNotes.sort(noteInputSort);
        hitNote(validNotes[0]);
    }
    
    private function onNoteRelease(strumLine:StrumLine, direction:Int):Void {
        final strum:Strum = strumLine.strums.members[direction];
        strum.animation.play('${Constants.NOTE_DIRECTIONS[direction]} static');

        final validNotes:Array<Note> = strumLine.notes.members.filter((note:Note) -> {
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