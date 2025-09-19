package funkin.gameplay.modchart.events;

class ModEvent extends BaseEvent {
	public var modifier:Modifier;

	public var endVal:Float = 0;
	public var player:Int = -1;

	public function new(manager:Manager, targetStep:Float, modName:String, target:Float, player:Int = -1) {
		super(manager, targetStep);

		this.player = player;
		endVal = target;

		this.modifier = manager.getModifier(modName);
	}
}
