package funkin.gameplay.modchart.events;

class BaseEvent {
    public var manager:Manager;
    public var targetStep:Float;

    public var ignoreExecution:Bool = false;
    public var finished:Bool = false;

    public function new(manager:Manager, targetStep:Float) {
        this.manager = manager;
        this.targetStep = targetStep;
    }

    public function execute(curStep:Float):Void {}
}