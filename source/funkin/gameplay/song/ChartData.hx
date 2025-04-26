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

		final stackedNotes:Map<String, Int> = removeStackedNotes(result);
		if(stackedNotes != null) {
			for(diff in stackedNotes.keys())
				trace('Removed ${stackedNotes.get(diff)} stacked notes in difficulty "${diff}"');
		}
		return result;
	}

	public static function removeStackedNotes(chart:ChartData):Map<String, Int> {
		var totalStackedNotes:Int = 0;
		var stackedNotes:Map<String, Int> = [];
		
		for(diff in chart.notes.keys()) {
			final allNotes:Array<NoteData> = chart.notes.get(diff);
			stackedNotes.set(diff, 0);

			final notesToCheck:Array<Array<NoteData>> = [
				allNotes.filter((note:NoteData) -> note.direction < Constants.KEY_COUNT), // opponent
				allNotes.filter((note:NoteData) -> note.direction > Constants.KEY_COUNT - 1) // player
			];
			for(s => notes in notesToCheck) {
				final strumOffset:Int = s * Constants.KEY_COUNT;
				for(i in strumOffset...Constants.KEY_COUNT + strumOffset) {
					final dirSpecificNotes:Array<NoteData> = notes.filter((note:NoteData) -> note.direction == i);
					dirSpecificNotes.sort((a:NoteData, b:NoteData) -> Std.int(a.time - b.time));
					
					var lastNote:NoteData = null;
					for(j in 0...dirSpecificNotes.length - 1) {
						final dirNote:NoteData = dirSpecificNotes[j];
						if(lastNote != null && Math.abs(dirNote.time - lastNote.time) <= 5) {
							totalStackedNotes++;
							stackedNotes.set(diff, stackedNotes.get(diff) + 1);
							allNotes.remove(dirNote);
						}
						lastNote = dirNote;
					}
				}
			}
		}
		return (totalStackedNotes != 0) ? stackedNotes : null;
	}

	public static function stringify(chart:ChartData):String {
		final writer:JsonWriter<ChartData> = new JsonWriter<ChartData>();
		return writer.write(chart);
	}
}