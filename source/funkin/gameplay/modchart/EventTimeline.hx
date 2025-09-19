package funkin.gameplay.modchart;

import funkin.gameplay.modchart.events.ModEvent;
import funkin.gameplay.modchart.events.BaseEvent;

class EventTimeline {
	public var modEvents:Map<String, Array<ModEvent>> = [];
	public var events:Array<BaseEvent> = [];

	public function new() {}

	public function addMod(modName:String):Void {
		modEvents.set(modName, []);
    }

	public function addEvent(event:BaseEvent):Void {
		if(event is ModEvent) {
			var modEvent:ModEvent = cast event;
			var name = modEvent.modifier.getName();

			if(!modEvents.exists(name))
				addMod(name);

			if(!modEvents.get(name).contains(modEvent))
				modEvents.get(name).push(modEvent);

			modEvents.get(name).sort((a, b) -> Std.int(a.targetStep - b.targetStep));
		}
        else if(!events.contains(event)) {
			events.push(event);
			events.sort((a, b) -> Std.int(a.targetStep - b.targetStep));
		}
	}

	public function update(step:Float) {
		for(modName in modEvents.keys()) {
			final garbage:Array<ModEvent> = [];
			final schedule:Array<ModEvent> = modEvents.get(modName);

			for(event in schedule) {
				if(event.finished)
					garbage.push(event);

				if(event.ignoreExecution || event.finished)
					continue;

				if(step >= event.targetStep)
					event.execute(step);
				else
					break;

				if(event.finished)
					garbage.push(event);
			}
			for(trash in garbage)
				schedule.remove(trash);
		}
		final garbage:Array<BaseEvent> = [];
		for(event in events) {
			if(event.finished)
				garbage.push(event);

			if(event.ignoreExecution || event.finished)
				continue;

			if(step >= event.targetStep)
				event.execute(step);
			else
				break;

			if(event.finished)
				garbage.push(event);
		}
		for(trash in garbage)
			events.remove(trash);
	}
}
