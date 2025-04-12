package funkin.backend.scripting.events.gameplay;

import funkin.gameplay.ComboDisplay;

class DisplayComboEvent extends ScriptEvent {
    /**
     * The combo to display.
     */
    public var combo:Int;

    /**
     * The sprites to display the combo on (only available on post).
     */
    public var sprites:Array<ComboDigitSprite>;
    
    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(DISPLAY_COMBO);
    }
}