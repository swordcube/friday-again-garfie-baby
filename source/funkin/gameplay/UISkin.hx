package funkin.gameplay;

import funkin.graphics.SkinnableSprite;

@:structInit
class CountdownStepData {
	public var name:String;
	public var soundPath:String;
}

@:structInit
class CountdownData {
	public var atlas:AtlasData;
	public var scale:Float;

	@:optional
	public var antialiasing:Bool;

	public var animation:Map<String, Map<String, AnimationData>>;//DynamicAccess<DynamicAccess<AnimationData>>;

	public var steps:Array<CountdownStepData>;
}

@:structInit
class UISkinData {
	public var strum:SkinnableSpriteData;
	public var note:SkinnableSpriteData;
	public var hold:SkinnableSpriteData;

	public var rating:SkinnableSpriteData;
	public var combo:SkinnableSpriteData;

	public var countdown:CountdownData;
}

class UISkin {
    public static function get(name:String):UISkinData {
        if(Cache.uiSkinCache.get(name) == null) {
			final parser:JsonParser<UISkinData> = new JsonParser<UISkinData>();
			parser.ignoreUnknownVariables = true;
			Cache.uiSkinCache.set(name, parser.fromJson(FlxG.assets.getText(Paths.json('gameplay/uiskins/${name}/conf'))));
        }
        return Cache.uiSkinCache.get(name);
    }
}