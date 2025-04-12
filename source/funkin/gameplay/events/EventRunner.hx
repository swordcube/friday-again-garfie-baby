package funkin.gameplay.events;

import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.gameplay.*;

import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.gameplay.song.ChartData.EventData;

class EventRunner extends FlxBasic {
    public var curEvent:Int = 0;

    public var events:Array<EventData>;
    public var behaviors:Map<String, EventBehavior> = [];

    public var onExecute:FlxTypedSignal<SongEvent->Void> = new FlxTypedSignal<SongEvent->Void>();
    public var onExecutePost:FlxTypedSignal<SongEvent->Void> = new FlxTypedSignal<SongEvent->Void>();

    public function new(events:Array<EventData>) {
        super();
        events.sort((a, b) -> Std.int(a.time - b.time));

        this.events = events;
        loadBehaviors(events);
    }

    public function loadBehaviors(events:Array<EventData>):Void {
        for(b in behaviors) {
            if(b != null)
                b.destroy();
        }
        behaviors.clear();

        for(e in events) {
            if(behaviors.exists(e.type))
                continue;

            final behavior:EventBehavior = switch(e.type) {
                case "Camera Pan":
                    new CameraPanBehavior();

                case "Add Camera Zoom":
                    new AddCameraZoomBehavior();

                default:
                    new ScriptedEventBehavior(e.type);
            };
            behaviors.set(e.type, behavior);
        }
    }

    override function update(elapsed:Float):Void {
        while(curEvent < events.length && events[curEvent].time <= Conductor.instance.time)
            execute(events[curEvent++]);
    }

    public function execute(event:EventData):Void {
        final e:SongEvent = cast Events.get(SONG_EVENT);
        e.recycle(event.time, event.params, event.type);
        onExecute.dispatch(e);

        final b:EventBehavior = behaviors.get(event.type);
        if(b != null)
            b.execute(e);

        if(e.cancelled)
            return;

        onExecutePost.dispatch(cast e.flagAsPost());
    }
}