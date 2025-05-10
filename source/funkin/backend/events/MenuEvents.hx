package funkin.backend.events;

@:dce(full)
class MenuEvents {} // needs to be here otherwise haxe will shit it's pants

class PauseMenuCreateEvent extends ActionEvent {
    /**
     * The name of the music to play on the pause menu.
     */
    public var pauseMusic:String;

    /**
     * The volume of the pause menu music.
     */
    public var musicVolume:Float;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(PAUSE_MENU_CREATE);
    }
}