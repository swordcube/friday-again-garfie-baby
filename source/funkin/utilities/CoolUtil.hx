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
        FlxG.sound.music.loopTime = config.loopTime;

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

    /**
     * Meant for running jobs/methods asyncronously
     * while in the context of a script.
     * 
     * In order to obtain the result of the job, you must
     * use the `onComplete` and/or `onError` signals of the
     * returned `ScriptedThreadResult` object.
     * 
     * @param  job   The job/method to run. 
     * @param  args  Arguments to pass to the `onComplete` or `onError` signals when they are dispatched.
     * 
     * @return ScriptedThreadResult
     */
    public static function runScriptedASyncJob(job:Void->Dynamic, ?args:Array<Dynamic>):ScriptedThreadResult {
        final result:ScriptedThreadResult = new ScriptedThreadResult();
        result.run(job, args);
        return result;
    }

    /**
     * Meant for loading bitmap data asyncronously
     * while in the context of a script.
     * 
     * In order to obtain the resulting bitmap data, you must
     * use the `onComplete` and/or `onError` signals of the
     * returned `ScriptedThreadResult` object.
     * 
     * @param  path  File path to the bitmap data.
     * @param  args  Arguments to pass to the `onComplete` or `onError` signals when they are dispatched.
     * 
     * @return ScriptedThreadResult
     */
    public static function loadBitmapDataASync(path:String, ?args:Array<Dynamic>):ScriptedThreadResult {
        return runScriptedASyncJob(() -> FlxG.assets.getBitmapData(path, false), args);
    }

    /**
     * Meant for loading sound data asyncronously
     * while in the context of a script.
     * 
     * In order to obtain the resulting sound data, you must
     * use the `onComplete` and/or `onError` signals of the
     * returned `ScriptedThreadResult` object.
     * 
     * @param  path  File path to the sound data.
     * @param  args  Arguments to pass to the `onComplete` or `onError` signals when they are dispatched.
     * 
     * @return ScriptedThreadResult
     */
    public static function loadSoundASync(path:String, ?args:Array<Dynamic>):ScriptedThreadResult {
        return runScriptedASyncJob(() -> FlxG.assets.getSound(path, false), args);
    }

    public static function getEaseFromString(ease:String) {
		if(ease == null)
            return FlxEase.linear;
		
        return switch(ease.toLowerCase().trim()) {
			case 'backin': FlxEase.backIn;
			case 'backinout': FlxEase.backInOut;
			case 'backout': FlxEase.backOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'bounceout': FlxEase.bounceOut;
			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'elasticout': FlxEase.elasticOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			case 'smoothstepout': FlxEase.smoothStepOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
			default: FlxEase.linear;
		}
	}
}

@:structInit
class MusicConfig {
    public var timingPoints:Array<TimingPoint>;
    
    @:optional
    @:default(0.0)
    public var loopTime:Float = 0.0;
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