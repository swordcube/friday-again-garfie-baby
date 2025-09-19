package funkin.gameplay.modchart.events;

class StepCallbackEvent extends CallbackEvent {
	public var endStep:Float = 0;

	public function new(manager:Manager, targetStep:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void) {
		super(manager, targetStep, callback);
		this.endStep = endStep;
	}

	override function execute(curStep:Float) {
		if (curStep <= endStep)
			callback(this, curStep);
		else
			finished = true;
	}
}
