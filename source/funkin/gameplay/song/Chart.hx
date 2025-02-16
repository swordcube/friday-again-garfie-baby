package funkin.gameplay.song;

import haxe.DynamicAccess;

/**
 * Compressed note data for storing in JSON files
 */
typedef CompressedNoteData = {
    var t:Float; // time
    var d:Int; // direction
    var l:Float; // length
    var k:String; // type/kind
}

/**
 * Compressed event data for storing in JSON files
 */
typedef CompressedEventData = {
    var t:Float; // time
    var p:DynamicAccess<Dynamic>; // params
    var k:String; // type/kind
}

/**
 * Compressed chart data for storing in JSON files
 */
typedef CompressedChartData = {
    var n:DynamicAccess<Array<CompressedNoteData>>;
    var e:Array<CompressedEventData>;
}

/**
 * Data for a note object, as a class.
 * 
 * Do not used the compressed variants of these
 * classes unless you are parsing a chart JSON manually!
 */
@:structInit
class NoteData {
    public var time:Float;
    public var direction:Int;
    public var length:Float;
    public var type:String;

    public function toString():String {
        return 'NoteData(time: ${time}, direction: ${direction}, length: ${length}, type: ${type})';
    }
}

/**
 * Data for an event object, as a class.
 * 
 * Do not used the compressed variants of these
 * classes unless you are parsing a chart JSON manually!
 */
@:structInit
class EventData {
    public var time:Float;
    public var params:DynamicAccess<Dynamic>;
    public var type:String;

    public function toString():String {
        return 'EventData(time: ${time}, params: ${params}, type: ${type})';
    }
}

/**
 * Data for a chart object, as a class.
 * 
 * Do not used the compressed variants of these
 * classes unless you are parsing a chart JSON manually!
 */
@:structInit
class ChartData {
    public var meta:SongMetadata;
    public var notes:Array<NoteData>;
    public var events:Array<EventData>;
}

class Chart {
    public static function loadMeta(song:String, ?mix:String, ?loaderID:String):SongMetadata {
        if(mix == null || mix.length == 0)
            mix = "default";

        return Json.parse(FlxG.assets.getText(Paths.json('gameplay/songs/${song}/${mix}/meta', loaderID)));
    }

    public static function load(song:String, difficulty:String, ?mix:String = "default", ?loaderID:String):ChartData {
        if(mix == null || mix.length == 0)
            mix = "default";

        var result:CompressedChartData = null;
        try {
            result = Json.parse(FlxG.assets.getText(Paths.json('gameplay/songs/${song}/${mix}/chart', loaderID)));
        }
        catch(e) {
            result = {n: {}, e: []};
            FlxG.log.warn('${song} [mix: ${mix} - diff: ${difficulty}] could not load: ${e}');
        }
        final compressedNotes:Array<CompressedNoteData> = result.n.get(difficulty);
        final compressedEvents:Array<CompressedEventData> = result.e;

        final finalNotes:Array<NoteData> = [];
        for(i in 0...compressedNotes.length) {
            final note:CompressedNoteData = compressedNotes[i];
            finalNotes.push({
                time: note.t,
                direction: note.d,
                length: note.l,
                type: note.k
            });
        }
        final finalEvents:Array<EventData> = [];
        for(i in 0...compressedEvents.length) {
            final event:CompressedEventData = compressedEvents[i];
            finalEvents.push({
                time: event.t,
                params: event.p,
                type: event.k
            });
        }
        final finalResult:ChartData = {
            meta: Chart.loadMeta(song, mix, loaderID),
            notes: finalNotes,
            events: finalEvents
        };
        return finalResult;
    }
}