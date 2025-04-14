package funkin.gameplay.events;

import funkin.backend.events.GameplayEvents;
import funkin.states.PlayState;

class EventBehavior {
    public var game(default, null):PlayState;
    public var eventType(default, null):String;

    public function new(eventType:String) {
        game = PlayState.instance;
        this.eventType = eventType;
    }

    public function execute(e:SongEvent):Void {}
    public function destroy():Void {}
}