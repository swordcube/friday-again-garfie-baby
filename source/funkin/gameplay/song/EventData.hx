package funkin.gameplay.song;

/**
 * Data for an event object, as a class.
 */
@:structInit
class EventData {
	@:alias("t")
    public var time:Float;

	@:alias("p")
	@:jcustomparse(funkin.utilities.DataParse.dynamicValue)
	@:jcustomwrite(funkin.utilities.DataWrite.dynamicValue)
    public var params:Dynamic;//DynamicAccess<Dynamic>;

	@:alias("k")
    public var type:String;

	public function new(time:Float, params:Dynamic, type:String) {
		this.time = time;
		this.params = params;
		this.type = type;
	}

    public function toString():String {
        return 'EventData(time: ${time}, params: ${params}, type: ${type})';
    }
}