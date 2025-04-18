package funkin.gameplay.song;

import thx.semver.Version;
import flixel.util.FlxSave;

class Highscore {
    public static final RECORD_VERSION:Version = "1.0.0";
    public static final ALL_RANKS:Array<Rank> = [GOLD, PERFECT, EXCELLENT, GREAT, GOOD, LOSS];

    public static function init():Void {
        _save = new FlxSave();
        _save.bind("highscore", Constants.SAVE_DIR);
        reload();
    }

    public static function reload():Void {
        _scoreRecords.clear();

        for(id in Reflect.fields(_save.data)) {
            final record:Dynamic = Reflect.field(_save.data, id);
            if(record != null)
                _scoreRecords.set(id, migrateRecord(record));
        }
    }

    public static function getRankFromStats(stats:PlayerStats):Rank {
        final acc:Int = Math.round(stats.accuracy * 100);
        return switch(acc) {
            case (_ >= 100 && stats.misses == 0) => true:
                GOLD;

            case (_ >= 90) => true:
                PERFECT;

            case (_ >= 80) => true:
                EXCELLENT;

            case (_ >= 70) => true:
                GREAT;

            case (_ >= 60) => true:
                GOOD;

            default:
                LOSS;
        }
    }

    public static function migrateRecord(record:Dynamic):ScoreRecord {
        // not needed yet, but here for when it is needed
        return cast record;
    }

    public static function getRecordID(song:String, difficulty:String, ?mix:String, ?contentPack:String):String {
        if(contentPack == null || contentPack.length == 0)
            contentPack = Paths.forceContentPack;

        return '${song.toLowerCase()}:${difficulty.toLowerCase()}:${mix.getDefaultString("default")}:${contentPack.getDefaultString("default")}';
    }

    public static function getDefaultRecord():ScoreRecord {
        return {
            score: 0,
            misses: 0,
            accuracy: 0,
            rank: Rank.UNKNOWN,
            judges: [
                "killer" => 0,
                "sick" => 0,
                "good" => 0,
                "bad" => 0,
                "shit" => 0,
                "miss" => 0,
                "cb" => 0
            ],
            version: RECORD_VERSION
        };
    }

    public static function getRecord(id:String):ScoreRecord {
        if(_scoreRecords.exists(id))
            return _scoreRecords.get(id);

        return getDefaultRecord();
    }

    public static function saveRecord(id:String, record:ScoreRecord, ?force:Bool = false):Void {
        final prevRecord:ScoreRecord = _scoreRecords.get(id) ?? getDefaultRecord();
        if(force || (record.score > prevRecord.score || record.accuracy > prevRecord.accuracy || record.rank > prevRecord.rank)) {
            _scoreRecords.set(id, record);
            Reflect.setField(_save.data, id, record);
            _save.flush();
        }
    }

    public static function forceSaveRecord(id:String, record:ScoreRecord):Void {
        saveRecord(id, record, true);
    }

    public static function resetRecord(id:String):Void {
        _scoreRecords.remove(id);
        Reflect.deleteField(_save.data, id);
        _save.flush();
    }

    //----------- [ Private API ] -----------//

    private static var _save:FlxSave;
    private static var _scoreRecords:Map<String, ScoreRecord> = [];
}

typedef ScoreRecord = {
    var score:Int;
    var misses:Int;
    var accuracy:Float;
    var rank:Rank;
    var judges:Map<String, Int>;
    var version:SemVer;
}

enum abstract Rank(String) from String to String {
    final GOLD = "gold";
    final PERFECT = "perfect";
    final EXCELLENT = "excellent";
    final GREAT = "great";
    final GOOD = "good";
    final LOSS = "loss";
    final UNKNOWN = "unknown";

    @:op(A < B)
    public static function lessThan(a:Rank, b:Rank):Bool {
        final ranksInOrder:Array<Rank> = Highscore.ALL_RANKS;
        return ranksInOrder.indexOf(a) < ranksInOrder.indexOf(b);
    }

    @:op(A > B)
    public static function greaterThan(a:Rank, b:Rank):Bool {
        final ranksInOrder:Array<Rank> = Highscore.ALL_RANKS;
        return ranksInOrder.indexOf(a) > ranksInOrder.indexOf(b);
    }
}
