package funkin.utilities;

import haxe.Timer;
import sys.thread.Thread;

import lime.app.Future;
import openfl.media.Sound;

import flixel.util.FlxTimer;
import flixel.util.FlxSignal.FlxTypedSignal;

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
    public static function playMusic(name:String, ?volume:Float = 1, ?looped:Bool = true, ?snd:Sound):Void {
        final parser:JsonParser<MusicConfig> = new JsonParser<MusicConfig>();
        parser.ignoreUnknownVariables = true;

        final config:MusicConfig = parser.fromJson(FlxG.assets.getText(Paths.json('${name}/config')));
        FlxG.sound.playMusic((snd != null) ? snd : Paths.sound('${name}/music'), volume, looped);

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
        // Ensure you can't open protocols such as steam://, file://, etc
        var protocol:Array<String> = url.split("://");
        if(protocol.length == 1)
            url = 'https://${url}';
        
        else if (protocol[0] != 'http' && protocol[0] != 'https')
            throw "openURL can only open http and https links.";

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

    public static function createASyncFuture<T>(job:Void->T):Future<T> {
        return new Future(job, true);
    }

    public static function createASyncFutureWithResult(job:Void->Dynamic):Future<ScriptedFutureResult> {
        return new Future<ScriptedFutureResult>(() -> {
            return {data: job()};
        }, true);
    }

    public static function loadBitmapDataASync(path:String, ?args:Array<Dynamic>):ScriptedThreadResult {
        final result:ScriptedThreadResult = new ScriptedThreadResult();
        result.run(() -> FlxG.assets.getBitmapData(path, false), args);
        return result;
    }

    public static function loadSoundASync(path:String, ?args:Array<Dynamic>):ScriptedThreadResult {
        final result:ScriptedThreadResult = new ScriptedThreadResult();
        result.run(() -> FlxG.assets.getSound(path, false), args);
        return result;
    }
}

@:structInit
class MusicConfig {
    public var timingPoints:Array<TimingPoint>;
}

@:structInit
class ScriptedFutureResult {
    public var data:Dynamic;
}

class ScriptedThreadResult {
    public var onComplete:FlxTypedSignal<(data:Dynamic, args:Array<Dynamic>)->Void>;
    public var onError:FlxTypedSignal<(data:Dynamic, args:Array<Dynamic>)->Void>;

    public function new() {
        this.onComplete = new FlxTypedSignal<(data:Dynamic, args:Array<Dynamic>)->Void>();
        this.onError = new FlxTypedSignal<(data:Dynamic, args:Array<Dynamic>)->Void>();
    }

    public function run(job:Void->Dynamic, ?args:Array<Dynamic>):Void {
        if(args == null)
            args = [];

        // wait until approx next frame to allow the user
        // to setup the signals first
        FlxTimer.wait(0.001, () -> {
            Thread.create(() -> {
                try {
                    final result:Dynamic = job();
                    Timer.delay(() -> this.onComplete.dispatch(result, args), 0); // relay result to main thread
                } catch(e) {
                    // relay error to main thread
                    Timer.delay(() -> this.onError.dispatch(e, args), 0);
                }
            });
        });
    }
}