package funkin.graphics;

// independent video sprite kinda thing
// could theoretically be made to use other video libs
// for now only hxvlc will be supported

#if VIDEOS_ALLOWED
#if hxvlc
import hxvlc.flixel.FlxVideoSprite;

class VideoSprite extends FlxVideoSprite {}
#else
class VideoSprite extends FlxSprite {
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