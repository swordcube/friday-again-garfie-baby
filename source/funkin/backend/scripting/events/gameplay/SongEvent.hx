package funkin.backend.scripting.events.gameplay;

class SongEvent extends ScriptEvent {
    /**
     * The time of the event in the chart.
     */
    public var time:Float;

    /**
     * The parameters of the event.
     */
    public var params:Dynamic;

    /**
     * The type of the event.
     */
    public var eventType:String;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(SONG_EVENT);
    }
}