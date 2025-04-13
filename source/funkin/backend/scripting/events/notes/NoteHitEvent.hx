package funkin.backend.scripting.events.notes;

import funkin.gameplay.notes.Note;
import funkin.gameplay.character.Character;

class NoteHitEvent extends ScriptEvent {
    /**
     * The note that was hit.
     */
    public var note:Note;

    /**
     * The time at which the note was hit (in milliseconds).
     */
    public var time:Float;

    /**
     * The direction of the note that was hit.
     */
    public var direction:Int;

    /**
     * The length of the note that was hit (in milliseconds).
     */
    public var length:Float;

    /**
     * The type of the note that was hit.
     */
    public var noteType:String;
    
    /**
     * Whether or not the note that was hit
     * should increase the player's combo.
     */
    public var increaseCombo:Bool;

    /**
     * Whether or not the note that was hit
     * should cause a miss to occur.
     */
    public var hitCausesMiss:Bool;

    /**
     * The rating of the note that was hit.
     */
    public var rating:String;

    /**
     * Whether or not to show a note splash, usually
     * similar to a firework effect, upon hitting this note.
     */
    public var showSplash:Bool;

    /**
     * Whether or not to show the hold covers
     * of the note that was hit.
     */
    public var showHoldCovers:Bool;

    /**
     * Whether or not to show the hold gradients
     * of the note that was hit.
     */
    public var showHoldGradients:Bool;

    /**
     * Whether or not to show the rating of
     * the note that was hit.
     */
    public var showRating:Bool;

    /**
     * Whether or not to show the combo of
     * the note that was hit.
     */
    public var showCombo:Bool;

    /**
     * The amount of score gained from the note.
     */
    public var score:Int;

    /**
     * The accuracy multiplier of the note that was hit.
     */
    public var accuracyScore:Float;

    /**
     * The amount of health gained from the note.
     */
    public var healthGain:Float;

    /**
     * Whether or not to gain health from hold notes.
     */
    public var gainHealthFromHolds:Bool;

    /**
     * Whether or not to gain score from hold notes.
     */
    public var gainScoreFromHolds:Bool;

    /**
     * Whether or not to play the strum's confirm animation.
     */
    public var playConfirmAnim:Bool;

    /**
     * Whether or not to play the characters's sing animation.
     */
    public var playSingAnim:Bool;

    /**
     * Whether or not to unmute the character's vocals.
     */
    public var unmuteVocals:Bool;

    /**
     * The character that will sing the note.
     */
    public var character:Character;

    /**
     * The suffix of the character's sing animation.
     */
    public var singAnimSuffix:String;

    /**
     * Whether or not to jitter the strum animation
     * on holds, like older versions of Funkin' (pre 0.3).
     */
    public var strumHoldJitter:Bool = false;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(NOTE_HIT);
    }
}