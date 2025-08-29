package funkin.gameplay.scoring.system;

import funkin.gameplay.notes.Note;

/**
 * The Psych Engine scoring system.
 */
class PsychSystem extends ScoringSystem {
    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.getJudgements)
    override function getJudgements():Array<String> {
        return (useKillers) ? _judgementList : _noKillerJudgementList;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.setJudgements)
    override function setJudgements(judgements:Array<String>):Void {
        if(useKillers)
            _judgementList = judgements;
        else
            _noKillerJudgementList = judgements;
    }
    
    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.getJudgementTiming)
    override function getJudgementTiming(judgement:String):Float {
        switch(judgement) {
            case "killer": return 22.5;
            case "sick":   return 45.0;
            case "good":   return 90.0;
            case "bad":    return 135.0;
            case "shit":   return 180.0;
        }
        return Math.POSITIVE_INFINITY;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.getAccuracyScore)
    override function getAccuracyScore(judgement:String):Float {
        switch(judgement) {
            case "killer": return 1.0;
            case "sick":   return (useKillers) ? 0.9 : 1.0;
            case "good":   return 0.67;
            case "bad":    return 0.34;
            case "shit":   return 0.0;
        }
        return 0.0;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.scoreNote)
    override function scoreNote(note:Note, timestamp:Float):Int {
        final judgement:String = judgeNote(note, timestamp);
        switch(judgement) {
            case "killer": return 500;
            case "sick":   return 350;
            case "good":   return 200;
            case "bad":    return 100;
            case "shit":   return 50;
        }
        return 0;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.splashAllowed)
    override function splashAllowed(judgement:String):Bool {
        return (judgement == "killer" || judgement == "sick");
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.holdHealthIncreasingAllowed)
    override function holdHealthIncreasingAllowed():Bool {
        return true;
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private var _judgementList:Array<String> = ["killer", "sick", "good", "bad", "shit"];
    private var _noKillerJudgementList:Array<String> = ["sick", "good", "bad", "shit"];
}