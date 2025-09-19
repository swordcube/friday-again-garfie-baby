package funkin.gameplay.modchart.events;

class CallbackEvent extends BaseEvent {
	public var callback:(CallbackEvent, Float) -> Void;

	public function new(manager:Manager, targetStep:Float, callback:(CallbackEvent, Float) -> Void) {
		super(manager, targetStep);
		this.callback = callback;
	}

	override function execute(curStep:Float) {
		callback(this, curStep);
		finished = true;
	}
}
