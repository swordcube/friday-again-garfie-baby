package funkin.backend.events;

import funkin.backend.events.Events;
import funkin.backend.events.ActionEvent;

import funkin.backend.events.CountdownEvents;
import funkin.backend.events.GameplayEvents;
import funkin.backend.events.MenuEvents;
import funkin.backend.events.NoteEvents;

class Events {
    public static function get<T:ActionEvent>(type:ActionEventType):T {
        if(_events.get(type) == null) {
            switch(type) {
                case HUD_GENERATION: _events.set(type, new HUDGenerationEvent());
                case NOTE_SPAWN: _events.set(type, new NoteSpawnEvent());
                case NOTE_HIT: _events.set(type, new NoteHitEvent());
                case NOTE_MISS: _events.set(type, new NoteMissEvent());
                case CAMERA_MOVE: _events.set(type, new CameraMoveEvent());
                case SONG_EVENT: _events.set(type, new SongEvent());
                case DISPLAY_RATING: _events.set(type, new DisplayRatingEvent());
                case DISPLAY_COMBO: _events.set(type, new DisplayComboEvent());
                case COUNTDOWN_START: _events.set(type, new CountdownStartEvent());
                case COUNTDOWN_STEP: _events.set(type, new CountdownStepEvent());
                case GAME_OVER: _events.set(type, new GameOverEvent());
                case GAME_OVER_CREATE: _events.set(type, new GameOverCreateEvent());
                case PAUSE_MENU_CREATE: _events.set(type, new PauseMenuCreateEvent());
                default: _events.set(type, new ActionEvent(UNKNOWN));
            }
        }
        return cast _events.get(type);
    }

    //----------- [ Private API ] -----------//

    private static var _events:Map<ActionEventType, ActionEvent> = [];
}