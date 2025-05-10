package funkin.gameplay.song;

import thx.semver.Version;
import flixel.util.FlxSave;

class Highscore {
    public static final RECORD_VERSION:Version = "1.0.0";
    public static final ALL_RANKS:Array<Rank> = [GOLD, PERFECT, EXCELLENT, GREAT, GOOD, LOSS, UNKNOWN];

    public static function init():Void {
        _save = new FlxSave();
        _save.bind("highscore", Constants.SAVE_DIR);
        reload();
    }

    public static function reload():Void {
        _scoreRecords.clear();
        _levelRecords.clear();

        if(_save.data.levelRecords == null) {
            _save.data.levelRecords = _levelRecords;
            _save.flush();
        }
        final ignoreIDs:Array<String> = ["levelRecords"];
        for(id in Reflect.fields(_save.data)) {
            if(ignoreIDs.contains(id))
                continue;
            
            final record:Dynamic = Reflect.field(_save.data, id);
            if(record != null)
                _scoreRecords.set(id, migrateScoreRecord(record));
        }
        final savedRecords:Map<String, Dynamic> = cast _save.data.levelRecords;
        for(id in savedRecords.keys()) {
            final record:Dynamic = savedRecords.get(id);
            if(record != null)
                _levelRecords.set(id, migrateLevelRecord(record));
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

    public static function migrateScoreRecord(record:Dynamic):ScoreRecord {
        // not needed yet, but here for when it is needed
        return cast record;
    }

    public static function migrateLevelRecord(record:Dynamic):LevelRecord {
        // not needed yet, but here for when it is needed
        return cast record;
    }

    public static function getScoreRecordID(song:String, difficulty:String, ?mix:String, ?contentPack:String):String {
        if(contentPack == null || contentPack.length == 0)
            contentPack = Paths.forceContentPack;

        return '${song.toLowerCase()}:${difficulty.toLowerCase()}:${mix.getDefaultString("default")}:${contentPack.getDefaultString("default")}';
    }

    public static function getLevelRecordID(level:String, difficulty:String, ?contentPack:String):String {
        if(contentPack == null || contentPack.length == 0)
            contentPack = Paths.forceContentPack;

        return '${level}:${difficulty}:${contentPack.getDefaultString("default")}';
    }

    public static function getDefaultScoreRecord():ScoreRecord {
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

    public static function getDefaultLevelRecord():LevelRecord {
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

    public static function getScoreRecord(id:String):ScoreRecord {
        if(_scoreRecords.exists(id))
            return _scoreRecords.get(id);

        return getDefaultScoreRecord();
    }

    public static function saveScoreRecord(id:String, record:ScoreRecord, ?force:Bool = false):Void {
        final prevRecord:ScoreRecord = _scoreRecords.get(id) ?? getDefaultScoreRecord();
        if(force || (record.score > prevRecord.score || record.accuracy > prevRecord.accuracy || record.rank > prevRecord.rank)) {
            _scoreRecords.set(id, record);
            Reflect.setField(_save.data, id, record);
            _save.flush();
        }
    }
    
    public static function forceSaveScoreRecord(id:String, record:ScoreRecord):Void {
        saveScoreRecord(id, record, true);
    }
    
    public static function getLevelRecord(id:String):LevelRecord {
        if(_levelRecords.exists(id))
            return _levelRecords.get(id);

        return getDefaultLevelRecord();
    }

    public static function saveLevelRecord(id:String, record:LevelRecord, ?force:Bool = false):Void {
        final prevRecord:LevelRecord = _levelRecords.get(id) ?? getDefaultLevelRecord();
        if(force || (record.score > prevRecord.score || record.accuracy > prevRecord.accuracy || record.rank > prevRecord.rank)) {
            _levelRecords.set(id, record);
            _save.data.levelRecords.set(id, record);
            _save.flush();
        }
    }

    public static function forceSaveLevelRecord(id:String, record:LevelRecord):Void {
        saveLevelRecord(id, record, true);
    }

    public static function resetScoreRecord(id:String):Void {
        _scoreRecords.remove(id);
        Reflect.deleteField(_save.data, id);
        _save.flush();
    }

    public static function resetLevelRecord(id:String):Void {
        _levelRecords.remove(id);
        Reflect.deleteField(_save.data.levelRecords, id);
        _save.flush();
    }

    //----------- [ Private API ] -----------//

    private static var _save:FlxSave;
    private static var _scoreRecords:Map<String, ScoreRecord> = [];
    private static var _levelRecords:Map<String, LevelRecord> = [];
}

typedef ScoreRecord = {
    var score:Int;
    var misses:Int;
    var accuracy:Float;
    var rank:Rank;
    var judges:Map<String, Int>;
    var version:SemVer;
}

typedef LevelRecord = {
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
        return ranksInOrder.indexOf(a) > ranksInOrder.indexOf(b);
    }

    @:op(A > B)
    public static function greaterThan(a:Rank, b:Rank):Bool {
        final ranksInOrder:Array<Rank> = Highscore.ALL_RANKS;
        return ranksInOrder.indexOf(a) < ranksInOrder.indexOf(b);
    }
}
