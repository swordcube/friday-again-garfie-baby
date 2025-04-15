package funkin.gameplay.events;

import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.backend.events.Events;
import funkin.backend.events.GameplayEvents;
import funkin.backend.events.NoteEvents;

import funkin.gameplay.song.NoteData;
import funkin.gameplay.song.EventData;

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

    public function loadBehavior(eventType:String):EventBehavior {
        return switch(eventType) {
            case "Camera Pan":
                new CameraPanBehavior();

            case "Add Camera Zoom":
                new AddCameraZoomBehavior();

            #if SCRIPTING_ALLOWED
            case "Script Call":
                new ScriptCallBehavior();
            #end

            default:
                new EventBehavior(eventType);
        }; 
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

            final behavior:EventBehavior = loadBehavior(e.type);
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
        
        if(e.cancelled)
            return;
        
        var b:EventBehavior = behaviors.get(e.eventType);
        if(b == null) {
            b = loadBehavior(e.eventType);
            behaviors.set(e.eventType, b);
        }
        b.execute(e);

        if(e.cancelled)
            return;

        onExecutePost.dispatch(cast e.flagAsPost());
    }
}