package funkin.backend.assets;

import sys.FileSystem;
import sys.thread.Thread;

import openfl.media.Sound;
import openfl.geom.Rectangle;
import openfl.utils.AssetCache as OpenFLAssetCache;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;

import funkin.gameplay.UISkin;
import funkin.gameplay.notes.NoteSkin;
import funkin.gameplay.character.CharacterData;

import funkin.states.FunkinState;

enum abstract AssetPreloadType(String) from String to String {
	var IMAGE = "image";
	var SOUND = "sound";
}

typedef AssetPreload = {
	var path:String;
	@:optional var type:AssetPreloadType;
}

class Cache {
    public static var atlasCache(default, never):Map<String, FlxFramesCollection> = [];
    public static var characterCache(default, never):Map<String, CharacterData> = [];
    
    public static var uiSkinCache(default, never):Map<String, UISkinData> = [];
    public static var noteSkinCache(default, never):Map<String, NoteSkinData> = [];

    // takenm from troll engine   🪵
    // https://github.com/riconuts/FNF-Troll-Engine/blob/a4a1933284b1be0ff6becb4e5af52f84f760c9eb/source/funkin/data/Cache.hx#L36
    public static function preloadAssets(assetsToLoad:Array<AssetPreload>):Void {
        for(asset in assetsToLoad) {
            switch(asset.type) {
                case IMAGE:
                    if(FlxG.assets.exists(asset.path)) {
                        final graphic:FlxGraphic = FlxG.bitmap.add(asset.path);
                        if(FlxG.state is FunkinState) {
                            // most states are FunkinStates, so this probably
                            // doesn't matter, but you just never know!
                            final state:FunkinState = cast FlxG.state;
                            state.graphicCache.cache(graphic);
                        }
                    }
                
                case SOUND:
                    if(FlxG.assets.exists(asset.path) && !OpenFLAssets.cache.hasSound(asset.path)) {
                        if(OpenFLAssets.exists(asset.path, SOUND))
                            OpenFLAssets.cache.setSound(asset.path, OpenFLAssets.getSound(asset.path, false));
                        else
                            OpenFLAssets.cache.setSound(asset.path, Sound.fromFile(FileSystem.absolutePath(asset.path)));
                    }
            }
        }
    }

    public static function clearAll():Void {
        Logs.verbose('Clearing cache... (0/5)');
        
        // Clear atlases
        Logs.verbose('- Clearing atlases... (1/5)');
        final pendingAtlasGraphics:Map<String, FlxGraphic> = [];
        for(atlas in atlasCache) {
            if(atlas.parent != null) {
                atlas.parent.persist = false;
                atlas.parent.decrementUseCount();
            }
            atlas.destroy();
        }
        atlasCache.clear();
        
        // Clear graphics
        Logs.verbose('- Clearing graphics... (2/5)');
        @:privateAccess {
            for(key => graph in FlxG.bitmap._cache) {
                // I check for destroyOnNoUse because if i don't, interacting
                // with some HaxeUI elements will try to access an invalid graphic
                // and immediately crash the game
                if(pendingAtlasGraphics.exists(key)) {
                    final pendingGraph:FlxGraphic = pendingAtlasGraphics.get(key);
                    pendingGraph._useCount--;
                }
                if(graph != null && !graph.persist && graph.destroyOnNoUse) {
                    // The extra disposing code that was here has
                    // been added to the flixel fork
                    graph.destroy();
                    
                    FlxG.bitmap.removeKey(key);
                    OpenFLAssets.cache.removeBitmapData(key);
                }
            }
        }
        // Clear fonts
        Logs.verbose('- Clearing fonts... (3/5)');
        @:privateAccess {
            final cache:OpenFLAssetCache = (OpenFLAssets.cache is OpenFLAssetCache) ? cast OpenFLAssets.cache : null;
            if(cache != null) {
                for(key in cache.font.keys())
                    cache.removeFont(key);
            }
        }
        // Clear sounds
        Logs.verbose('- Clearing sounds... (4/5)');
        @:privateAccess {
            final cache:OpenFLAssetCache = (OpenFLAssets.cache is OpenFLAssetCache) ? cast OpenFLAssets.cache : null;
            if(cache != null) {
                for(key in cache.sound.keys()) {
                    final snd:Sound = cache.sound.get(key);
                    if(FlxG.sound.music != null && FlxG.sound.music._sound != snd)
                        snd.close();

                    cache.removeSound(key);
                }
            }
        }
        // Clear gameplay related caches
        Logs.verbose('- Clearing gameplay caches... (5/5)');
        uiSkinCache.clear();
        noteSkinCache.clear();
        characterCache.clear();
    }
}