package funkin.backend.scripting.events;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.ScriptEvent;

class Events {
    public static function get<T:ScriptEvent>(type:ScriptEventType):T {
        if(_events.get(type) == null) {
            switch(type) {
                case HUD_GENERATION:
                    _events.set(type, new HUDGenerationEvent());

                default:
                    _events.set(type, new ScriptEvent());
            }
        }
        return cast _events.get(type);
    }

    //----------- [ Private API ] -----------//

    private static var _events:Map<ScriptEventType, ScriptEvent> = [];
}
#end