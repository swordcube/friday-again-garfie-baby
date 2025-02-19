package funkin.backend.scripting.events.gameplay;

class HUDGenerationEvent extends ScriptEvent {
    /**
     * The HUD type to generate, this will usually be
     * the name of the HUD type chosen in the Options menu.
     */
    public var hudType:String;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(HUD_GENERATION);
    }
}