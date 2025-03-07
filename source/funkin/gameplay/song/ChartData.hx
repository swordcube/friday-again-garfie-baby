package funkin.gameplay.song;

/**
 * Data for a note object, as a class.
 */
@:structInit
class NoteData {
	@:alias("t")
    public var time:Float;

	@:alias("d")
    public var direction:Int;

	@:alias("l")
    public var length:Float;

	@:alias("k")
    public var type:String;

    public function toString():String {
        return 'NoteData(time: ${time}, direction: ${direction}, length: ${length}, type: ${type})';
    }
}

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

    public function toString():String {
        return 'EventData(time: ${time}, params: ${params}, type: ${type})';
    }
}

/**
 * Data for a chart object, as a class.
 */
@:structInit
class ChartData {
	@:jignored
    public var meta:SongMetadata;

	@:alias("n")
	public var notes:Map<String, Array<NoteData>>;//DynamicAccess<Array<NoteData>>;

	@:alias("e")
	public var events:Array<EventData>;//DynamicAccess<Array<EventData>>;

	public static function load(song:String, ?mix:String = "default", ?loaderID:String):ChartData {
		if(mix == null || mix.length == 0)
			mix = "default";
	
		final parser:JsonParser<ChartData> = new JsonParser<ChartData>();
		parser.ignoreUnknownVariables = true;
	
		final result:ChartData = parser.fromJson(FlxG.assets.getText(Paths.json('gameplay/songs/${song}/${mix}/chart', loaderID)));
		result.meta = SongMetadata.load(song, mix, loaderID);
		return result;
	}

	public static function stringify(chart:ChartData):String {
		final writer:JsonWriter<ChartData> = new JsonWriter<ChartData>();
		return writer.write(chart);
	}
}