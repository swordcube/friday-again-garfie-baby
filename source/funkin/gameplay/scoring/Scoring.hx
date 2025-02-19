package funkin.gameplay.scoring;

import funkin.gameplay.notes.Note;
import funkin.gameplay.scoring.system.*;

/**
 * A class used for nicely judging the score and
 * rating of notes.
 */
class Scoring {
    /**
     * The current scoring system being used.
     */
    public static var currentSystem:ScoringSystem = new PBotSystem();

    /**
     * Returns a list of every judgement type.
     */
    public static function getJudgements():Array<String> {
        return currentSystem.getJudgements();
    }

    /**
     * Returns the timing of a given judgement.
     * 
     * @param  judgement  The judgement to get the timing of. 
     */
    public static function getJudgementTiming(judgement:String):Float {
        return currentSystem.getJudgementTiming(judgement);
    }

    /**
     * Returns the accuracy score of a given judgement.
     * 
     * @param  judgement  The judgement to get the timing of. 
     */
    public static function getAccuracyScore(judgement:String):Float {
        return currentSystem.getAccuracyScore(judgement);
    }
    
    /**
     * Returns the judgement of a given note.
     * 
     * @param  note       The note to get the judgement from.
     * @param  timestamp  The timestamp that the note was hit at. (in milliseconds)
     */
    public static function judgeNote(note:Note, timestamp:Float):String {
        return currentSystem.judgeNote(note, timestamp);
    }

    /**
     * Returns the score of a given note.
     * 
     * @param  note       The note to get the score from.
     * @param  timestamp  The timestamp that the note was hit at. (in milliseconds)
     */
    public static function scoreNote(note:Note, timestamp:Float):Int {
        return currentSystem.scoreNote(note, timestamp);
    }

    /**
     * Returns whether or not a splash should be shown for a given judgement.
     * 
     * @param  judgement  The judgement to get the result from.
     */
    public static function splashAllowed(judgement:String):Bool {
        return currentSystem.splashAllowed(judgement);
    }

    /**
     * Returns whether or not the health can increase
     * from hold notes.
     */
    public static function holdHealthIncreasingAllowed():Bool {
        return currentSystem.holdHealthIncreasingAllowed();
    }

    /**
     * Returns whether or not the score can increase
     * from hold notes.
     */
     public static function holdScoreIncreasingAllowed():Bool {
        return currentSystem.holdScoreIncreasingAllowed();
    }
}