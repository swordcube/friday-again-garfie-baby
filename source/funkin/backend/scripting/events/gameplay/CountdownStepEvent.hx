package funkin.backend.scripting.events.gameplay;

import funkin.gameplay.Countdown;

class CountdownStepEvent extends ScriptEvent {
    /**
     * The index of the step.
     */
    public var counter:Int;

    /**
     * A path to the sound to play.
     */
    public var soundPath:String;

    /**
     * The sprite to display the countdown on (only available on post).
     */
    public var sprite:CountdownSprite;

    /**
     * The tween to animate the sprite with (only available on post).
     */
    public var tween:FlxTween;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(COUNTDOWN_STEP);
    }
}