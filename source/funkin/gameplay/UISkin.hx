package funkin.gameplay;

import funkin.graphics.SkinnableSprite;

typedef CountdownStepData = {
    var name:String;
    var soundPath:String;
}

typedef CountdownData = {
    > SkinnableSpriteData,

    var steps:Array<CountdownStepData>;
}

typedef UISkinData = {
    var strum:SkinnableSpriteData;
    var note:SkinnableSpriteData;
    var hold:SkinnableSpriteData;

    var rating:SkinnableSpriteData;
    var combo:SkinnableSpriteData;

    var countdown:SkinnableSpriteData;
}

class UISkin {
    public static function get(name:String):UISkinData {
        if(Cache.uiSkinCache.get(name) == null) {
            Cache.uiSkinCache.set(name, Json.parse(FlxG.assets.getText(Paths.json('gameplay/uiskins/${name}/conf'))));
        }
        return Cache.uiSkinCache.get(name);
    }
}