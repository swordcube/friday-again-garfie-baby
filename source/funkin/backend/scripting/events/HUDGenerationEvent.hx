package funkin.backend.scripting.events;

class HUDGenerationEvent extends ScriptEvent {
    /**
     * The HUD type to generate, this will usually be
     * the name of the HUD type chosen in the Options menu.
     */
    public var hudType:String;
}