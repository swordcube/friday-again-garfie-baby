package funkin.backend.scripting.events;

import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.notes.*;
import funkin.backend.scripting.events.gameplay.*;

import funkin.backend.scripting.events.ScriptEvent;

class Events {
    public static function get<T:ScriptEvent>(type:ScriptEventType):T {
        if(_events.get(type) == null) {
            switch(type) {
                case UNKNOWN:
                    _events.set(type, new ScriptEvent(UNKNOWN));

                case HUD_GENERATION:
                    _events.set(type, new HUDGenerationEvent());

                case NOTE_HIT:
                    _events.set(type, new NoteHitEvent());

                case NOTE_MISS:
                    _events.set(type, new NoteMissEvent());

                case CAMERA_MOVE:
                    _events.set(type, new CameraMoveEvent());

                default:
                    _events.set(type, new ScriptEvent(UNKNOWN));
            }
        }
        return cast _events.get(type);
    }

    //----------- [ Private API ] -----------//

    private static var _events:Map<ScriptEventType, ScriptEvent> = [];
}