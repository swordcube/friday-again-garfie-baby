package funkin.gameplay.modchart.events;

class SetEvent extends ModEvent {
	override function execute(curStep:Float) {
		manager.setValue(modifier.getName(), endVal, player);
		finished = true;
	}
}