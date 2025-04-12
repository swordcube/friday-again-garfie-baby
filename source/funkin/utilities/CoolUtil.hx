package funkin.utilities;

import lime.app.Future;

class CoolUtil {
    /**
     * Plays music from a given name.
     * 
     * Also sets up timing points from a file named `config.json`
     * located in the same directory as the music file.
     * 
     * @param  name    The name to the music to play.
     * @param  volume  The volume of the music from 0 to 1.
     * @param  looped  Whether or not the music will loop.
     */
    public static function playMusic(name:String, ?volume:Float = 1, ?looped:Bool = true):Void {
        final parser:JsonParser<MusicConfig> = new JsonParser<MusicConfig>();
        parser.ignoreUnknownVariables = true;

        final config:MusicConfig = parser.fromJson(FlxG.assets.getText(Paths.json('${name}/config')));
        FlxG.sound.playMusic(Paths.sound('${name}/music'), volume, looped);

        Conductor.instance.music = FlxG.sound.music;
        Conductor.instance.reset(config.timingPoints.first().bpm);
        Conductor.instance.setupTimingPoints(config.timingPoints);
    }

    /**
     * Plays the default menu music.
     */
    public static function playMenuMusic(?volume:Float = 1):Void {
        playMusic("menus/music/freakyMenu", volume);
    }

    /**
     * A utility function to open a URL in the default browser.
     * 
     * This function works correctly on linux, and should be
     * preferred over `FlxG.openURL()`.
     * 
     * @param  url  The URL to open. 
     */
    public static function openURL(url:String):Void {
        #if linux
        Sys.command('/usr/bin/xdg-open', [url]);
        #else
        FlxG.openURL(url);
        #end
    }

    /**
     * Returns an array containing multiple string
     * arrays from given CSV data.
     * 
     * @param  csv  The CSV data to parse.
     */
    public static function parseCSV(csv:String):Array<Array<String>> {
        final list:Array<Array<String>> = [];

        for(line in csv.trim().replace("\r", "").split("\n"))
            list.push(line.split(","));

        return list;
    }

    /**
     * Returns a random item from a given array.
     * 
     * Returns `null` if unsuccessful.
     * 
     * @param  array  The array to pick an item from.
     */
    public static function pickRandom<T>(array:Array<T>):T {
        return (array.length != 0) ? array[FlxG.random.int(0, array.length - 1)] : null;
    }

    public static function createASyncFuture<T>(job:Void->T):Future<T> {
        return new Future(job, true);
    }

    /**
     * Resets an FlxSprite.
     * 
     * @param  spr  Sprite to reset
     * @param  x    New X position
     * @param  y    New Y position
     */
    public static function resetSprite(spr:FlxSprite, x:Float, y:Float):Void {
        spr.reset(x, y);
        spr.alpha = 1;
        spr.visible = true;
        spr.active = true;
        spr.acceleration.set();
        spr.velocity.set();
        spr.drag.set();
        spr.antialiasing = FlxSprite.defaultAntialiasing;
        spr.frameOffset.set();
        FlxTween.cancelTweensOf(spr);
    }
}

@:structInit
class MusicConfig {
    public var timingPoints:Array<TimingPoint>;
}