package funkin.gameplay.scoring;

import funkin.gameplay.notes.Note;

/**
 * A class used for judging the score and
 * rating of notes.
 * 
 * There is multiple scoring systems available,
 * and each one judge/score notes differently.
 */
class ScoringSystem {
    /**
     * Constructs a new `ScoringSystem`.
     */
    public function new() {}

    /**
     * Returns a list of every judgement type,
     * from best to worst.
     */
    public function getJudgements():Array<String> {
        return [];
    }

    /**
     * Returns the timing of a given judgement.
     * 
     * @param  judgement  The judgement to get the timing of. 
     */
    public function getJudgementTiming(judgement:String):Float {
        return Math.POSITIVE_INFINITY;
    }

    /**
     * Returns the accuracy score of a given judgement.
     * 
     * @param  judgement  The judgement to get the timing of. 
     */
    public function getAccuracyScore(judgement:String):Float {
        return 0.0;
    }
    
    /**
     * Returns the judgement of a given note.
     * 
     * @param  note       The note to get the judgement from.
     * @param  timestamp  The timestamp that the note was hit at. (in milliseconds)
     */
    public function judgeNote(note:Note, timestamp:Float):String {
        return null;
    }

    /**
     * Returns the score of a given note.
     * 
     * @param  note       The note to get the score from.
     * @param  timestamp  The timestamp that the note was hit at. (in milliseconds)
     */
    public function scoreNote(note:Note, timestamp:Float):Int {
        return 0;
    }

    /**
     * Returns whether or not a splash should be shown for a given judgement.
     * 
     * @param  judgement  The judgement to get the result from.
     */
    public function splashAllowed(judgement:String):Bool {
        return false;
    }

    /**
     * Returns whether or not the health can increase
     * from hold notes.
     */
    public function holdHealthIncreasingAllowed():Bool {
        return false;
    }

    /**
     * Returns whether or not the score can increase
     * from hold notes.
     */
    public function holdScoreIncreasingAllowed():Bool {
        return false;
    }
}