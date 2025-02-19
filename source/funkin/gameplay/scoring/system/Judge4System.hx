package funkin.gameplay.scoring.system;

import funkin.gameplay.notes.Note;

/**
 * The Judge4 scoring system, used in Etterna.
 */
class Judge4System extends ScoringSystem {
    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.getJudgements)
    override function getJudgements():Array<String> {
        return _judgementList;
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
            case "sick":   return 1.0;
            case "good":   return 0.7;
            case "bad":    return 0.3;
            case "shit":   return 0.0;
        }
        return 0.0;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.judgeNote)
    override function judgeNote(note:Note, timestamp:Float):String {
        var diff:Float = Math.abs(note.time - timestamp);
        var result:String = _judgementList[_judgementList.length - 1];
        
        for(i in 0..._judgementList.length) {
            final judgement:String = _judgementList[i];
            if(diff >= getJudgementTiming(judgement))
                result = judgement;
        }
        return result;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.scoreNote)
    override function scoreNote(note:Note, timestamp:Float):Int {
        final judgement:String = judgeNote(note, timestamp);
        switch(judgement) {
            case "killer": return 350;
            case "sick":   return 300;
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

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private static final _judgementList:Array<String> = ["killer", "sick", "good", "bad", "shit"];
}