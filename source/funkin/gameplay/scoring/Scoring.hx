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
     * Whether or not killers are enabled.
     */
    public static var useKillers(get, set):Bool;

    /**
     * Returns a list of every judgement type.
     */
    public static function getJudgements():Array<String> {
        return currentSystem.getJudgements();
    }

    /**
     * Sets the list of every available judgement.
     * 
     * Make sure to order them from best to worst, otherwise
     * you won't get the correct ratings for the correct timings!
     * 
     * @param  judgements  The new set of judgements.
     */
    public static function setJudgements(judgements:Array<String>):Void {
        currentSystem.setJudgements(judgements);
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

    //----------- [ Private API ] -----------//

    @:noCompletion
    private static function get_useKillers():Bool {
        return currentSystem.useKillers;
    }

    @:noCompletion
    private static function set_useKillers(value:Bool):Bool {
        return currentSystem.useKillers = value;
    }
}