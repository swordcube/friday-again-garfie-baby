package funkin.backend.scripting.events.gameplay;

import flixel.math.FlxPoint;

class CameraMoveEvent extends ScriptEvent {
    /**
     * The position to move the camera to.
     */
    public var position:FlxPoint;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(CAMERA_MOVE);
    }
}