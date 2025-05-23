package funkin.gameplay.notes;

import funkin.graphics.SkinnableSprite;

@:structInit
class NoteSkinData {
	@:optional
	@:default(50)
	public var baseStrumY:Float; // i don't think i can extend SkinnableSpriteData so i have to put this here instead

	public var strum:SkinnableSpriteData;
	public var note:SkinnableSpriteData;
	public var splash:SkinnableSpriteData;
	public var hold:SkinnableSpriteData;

	public var holdCovers:SkinnableSpriteData;
	public var holdGradients:SkinnableSpriteData;
}

class NoteSkin {
    public static function get(name:String):NoteSkinData {
        if(Cache.noteSkinCache.get(name) == null) {
			final parser:JsonParser<NoteSkinData> = new JsonParser<NoteSkinData>();
			parser.ignoreUnknownVariables = true;
			Cache.noteSkinCache.set(name, parser.fromJson(FlxG.assets.getText(Paths.json('gameplay/noteskins/${name}/config'))));
        }
        return Cache.noteSkinCache.get(name);
    }
}