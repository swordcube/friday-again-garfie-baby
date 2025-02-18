package funkin.gameplay.song;

@:structInit
class SongData {
	public var title:String;

	public var mixes:Array<String>;
	public var difficulties:Array<String>;

	public var bpm:Float;
	public var timingPoints:Array<TimingPoint>;

	public var artist:String;
	public var charter:String;
}

@:structInit
class FreeplayData {
	public var ratings:Map<String, Int>;//DynamicAccess<Int>;

	public var icon:String;
	public var album:String;

    public function getRating(difficulty:String):Int {
        return ratings.get(difficulty);
    }
}

@:structInit
class GameplayData {
	public var characters:Map<String, String>;//DynamicAccess<String>;
	public var scrollSpeed:Map<String, Float>;//DynamicAccess<Float>;

	public var stage:String;
	public var uiSkin:String;

    public function getCharacter(type:String):String {
        return characters.get(type);
    }

    public function getScrollSpeed(difficulty:String):Float {
        return scrollSpeed.get(difficulty);
    }
}

class SongMetadata {
	public var song:SongData;
	public var freeplay:FreeplayData;
	public var game:GameplayData;
}