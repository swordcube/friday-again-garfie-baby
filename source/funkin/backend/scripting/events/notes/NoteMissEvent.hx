package funkin.backend.scripting.events.notes;

import funkin.gameplay.notes.Note;
import funkin.gameplay.character.Character;

class NoteMissEvent extends ScriptEvent {
    /**
     * The note that was missed.
     */
    public var note:Note;

    /**
     * The time at which the note was missed (in milliseconds).
     */
    public var time:Float;

    /**
     * The direction of the note that was missed.
     */
    public var direction:Int;

    /**
     * The length of the note that was missed (in milliseconds).
     */
    public var length:Float;

    /**
     * The type of the note that was missed.
     */
    public var noteType:String;

    /**
     * Whether or not the note that was missed
     * should reset the player's combo.
     */
    public var resetCombo:Bool;

    /**
     * Whether or not the note that was missed
     * should count towards the player's miss count.
     */
    public var countAsMiss:Bool;

    /**
     * Whether or not to show a miss graphic
     * when the note is missed.
     */
    public var showRating:Bool;

    /**
     * Whether or not to show a combo
     * of how many notes the player has missed in a row.
     */
    public var showCombo:Bool;

    /**
     * The amount of score lost from the note.
     */
    public var score:Int;

    /**
     * The amount of health lost from the note.
     */
    public var healthLoss:Float;

    /**
     * Whether or not to play the characters's miss animation.
     */
    public var playMissAnim:Bool;

    /**
     * Whether or not to mute the character's vocals.
     */
    public var muteVocals:Bool;

    /**
     * The character that will miss the note.
     */
    public var character:Character;

    /**
     * The suffix of the character's miss animation.
     */
    public var missAnimSuffix:String;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(NOTE_MISS);
    }
}