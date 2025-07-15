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

	public function clone():EventData {
		final clone:EventData = new EventData(time, params, type);
		return clone;
	}

    public function toString():String {
        return 'EventData(time: ${time}, params: ${params}, type: ${type})';
    }
}

enum EventParameterType {
	Bool;
    String;
    Int(min:Int, max:Int, step:Int);
    Float(min:Float, max:Float, step:Float, decimals:Int);
    Dropdown(values:Array<String>);
    ColorWheel;
}

typedef EventConfig = {
	var params:Array<RawEventParameterConfig>;
	var useNamedParams:Bool;
}

typedef RawEventParameterConfig = {
	var id:String;
	var title:String;
	
	var type:String;
	var defaultValue:Dynamic;
}

typedef EventParameterConfig = {
	var id:String;
	var title:String;
	
	var type:EventParameterType;
	var defaultValue:Dynamic;
}