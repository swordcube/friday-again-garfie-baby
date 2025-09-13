package funkin.graphics;

// independent video sprite kinda thing
// could theoretically be made to use other video libs
// for now only hxvlc will be supported

#if VIDEOS_ALLOWED
#if hxvlc
import hxvlc.flixel.FlxVideoSprite;

class VideoSprite extends FlxVideoSprite {
    /**
	 * Video loading argument to make the video loop
	 * 
	 * Usage:
	 * ```haxe
	 * video.load(Paths.video('vid.mp4'),[VideoSprite.looping]);
	 * ```
	 */
	public static final looping:String = ':input-repeat=65535';
	
	/**
	 * Video loading argument to make the video muted
	 * Use if your video doesnt require audio
	 * 
	 * Usage:
	 * ```haxe
	 * video.load(Paths.video('vid.mp4'),[VideoSprite.muted]);
	 * ```
	 */
	public static final muted:String = ':no-audio';
}
#else
class VideoSprite extends FlxSprite {
    /**
	 * Video loading argument to make the video loop
	 * 
	 * Usage:
	 * ```haxe
	 * video.load(Paths.video('vid.mp4'),[VideoSprite.looping]);
	 * ```
	 */
	public static final looping:String = '';
	
	/**
	 * Video loading argument to make the video muted
	 * Use if your video doesnt require audio
	 * 
	 * Usage:
	 * ```haxe
	 * video.load(Paths.video('vid.mp4'),[VideoSprite.muted]);
	 * ```
	 */
	public static final muted:String = '';

    public function load(location:String, ?options:Array<String>):Bool {
        return true;
    }

    public function play():Void {}

    public function pause():Void {}

    public function resume():Void {}

    public function stop():Void {}
}
#end
#end