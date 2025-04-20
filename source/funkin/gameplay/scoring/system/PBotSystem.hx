package funkin.gameplay.scoring.system;

import funkin.gameplay.notes.Note;

/**
 * The PBot scoring system, used in Funkin' post-0.3.
 */
class PBotSystem extends ScoringSystem {
    /**
     * The threshold at which a note hit is considered perfect and always given the max score.
     */
    public static final PERFECT_THRESHOLD:Float = 5.0;

    /**
     * The threshold at which a note hit is considered missed.
     */
    public static final MISS_THRESHOLD:Float = 160.0;

    /**
     * The score a note receives when it is missed.
     */
    public static final MISS_SCORE:Int = 0;

    /**
     * The minimum score a note can receive while still being considered a hit.
     */
    public static final MIN_SCORE:Float = 9.0;

    /**
     * The maximum score a note can receive.
     */
    public static final MAX_SCORE:Int = 500;

    /**
     * The offset of the sigmoid curve for the scoring function.
     */
    public static final SCORING_OFFSET:Float = 54.99;

    /**
     * The slope of the sigmoid curve for the scoring function.
     */
    public static final SCORING_SLOPE:Float = 0.080;

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
            case "good":   return 0.7;
            case "bad":    return 0.3;
            case "shit":   return 0.0;
        }
        return 0.0;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.scoreNote)
    override function scoreNote(note:Note, timestamp:Float):Int {
        final diff:Float = Math.abs(note.time - timestamp);
        if(diff >= MISS_THRESHOLD)
            return MISS_SCORE;

        if(diff <= PERFECT_THRESHOLD)
            return MAX_SCORE;

        final factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-SCORING_SLOPE * (diff - SCORING_OFFSET))));
        return Std.int(MAX_SCORE * factor + MIN_SCORE);
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.splashAllowed)
    override function splashAllowed(judgement:String):Bool {
        return judgement == "killer" || judgement == "sick";
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.holdHealthIncreasingAllowed)
    override function holdHealthIncreasingAllowed():Bool {
        return true;
    }

    @:inheritDoc(funkin.gameplay.scoring.ScoringSystem.holdScoreIncreasingAllowed)
    override function holdScoreIncreasingAllowed():Bool {
        return true;
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private var _judgementList:Array<String> = ["killer", "sick", "good", "bad", "shit"];
    private var _noKillerJudgementList:Array<String> = ["sick", "good", "bad", "shit"];
}