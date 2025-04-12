package funkin.backend.scripting.events.gameplay;

import funkin.gameplay.Countdown;

class CountdownStartEvent extends ScriptEvent {
    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(COUNTDOWN_START);
    }
}