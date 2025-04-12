package funkin.backend.scripting.events.gameplay;

import funkin.gameplay.ComboDisplay;

class DisplayRatingEvent extends ScriptEvent {
    /**
     * The rating to display.
     */
    public var rating:String;

    /**
     * The sprite to display the rating on (only available on post).
     */
    public var sprite:RatingSprite;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(DISPLAY_RATING);
    }
}