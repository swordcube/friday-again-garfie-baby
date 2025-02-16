package funkin.assets;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.gameplay.UISkin.UISkinData;

class Cache {
    public static var atlasCache(default, never):Map<String, FlxFramesCollection> = [];
    public static var uiSkinCache(default, never):Map<String, UISkinData> = [];

    public static function clearAll():Void {
        for(atlas in atlasCache) {
            if(atlas.parent != null) {
                atlas.parent.persist = false;
                atlas.parent.destroyOnNoUse = true;
                atlas.parent.decrementUseCount();
            }
            atlas.destroy();
        }
        atlasCache.clear();
        uiSkinCache.clear();
    }
}