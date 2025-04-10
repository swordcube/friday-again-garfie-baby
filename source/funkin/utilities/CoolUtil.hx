package funkin.utilities;

class CoolUtil {
    public static function playMusic(name:String, ?volume:Float = 1, ?looped:Bool = true):Void {
        final parser:JsonParser<MusicConfig> = new JsonParser<MusicConfig>();
        parser.ignoreUnknownVariables = true;

        final config:MusicConfig = parser.fromJson(FlxG.assets.getText(Paths.json('${name}/config')));
        FlxG.sound.playMusic(Paths.sound('${name}/music'), volume, looped);

        Conductor.instance.music = FlxG.sound.music;
        Conductor.instance.reset(config.timingPoints.first().bpm);
        Conductor.instance.setupTimingPoints(config.timingPoints);
    }

    public static function playMenuMusic(?volume:Float = 1):Void {
        playMusic("menus/music/freakyMenu", volume);
    }
}

@:structInit
class MusicConfig {
    public var timingPoints:Array<TimingPoint>;
}