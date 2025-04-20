package funkin.gameplay.song;

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