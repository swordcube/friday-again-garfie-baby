package funkin.gameplay.notes;

import funkin.graphics.SkinnableSprite;

@:structInit
class NoteSkinData {
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
			Cache.noteSkinCache.set(name, parser.fromJson(FlxG.assets.getText(Paths.json('gameplay/noteskins/${name}/conf'))));
        }
        return Cache.noteSkinCache.get(name);
    }
}