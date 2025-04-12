package funkin.gameplay;

import funkin.graphics.SkinnableSprite;
import funkin.graphics.SkinnableUISprite;

@:structInit
class CountdownStepData {
	public var name:String;
	public var soundPath:String;

	@:optional
	@:default(true)
	public var visible:Bool;
}

@:structInit
class CountdownData extends SkinnableUISpriteData {
	public var steps:Array<CountdownStepData>;
}

@:structInit
class UISkinData {
	public var rating:SkinnableUISpriteData;
	public var combo:SkinnableUISpriteData;

	public var countdown:CountdownData;
}

class UISkin {
    public static function get(name:String):UISkinData {
        if(Cache.uiSkinCache.get(name) == null) {
			final parser:JsonParser<UISkinData> = new JsonParser<UISkinData>();
			parser.ignoreUnknownVariables = true;
			Cache.uiSkinCache.set(name, parser.fromJson(FlxG.assets.getText(Paths.json('gameplay/uiskins/${name}/config'))));
        }
        return Cache.uiSkinCache.get(name);
    }
}