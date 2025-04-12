package funkin.graphics;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import funkin.gameplay.scoring.Scoring;
import haxe.DynamicAccess;
import flixel.graphics.atlas.FlxAtlas;

import funkin.graphics.SkinnableSprite;

@:structInit
class SkinnableUISpriteData {
	public var atlas:AtlasData;
	
    @:optional
    @:default(1.0)
    public var alpha:Float;

    @:optional
    @:default(1.0)
	public var scale:Float;

	@:optional
    @:default(null)
	public var antialiasing:Null<Bool>;

    @:optional
	@:default({x: 0, y: 0})
	public var offset:PointData<Float>;

	public var animation:Map<String, AnimationData>;//DynamicAccess<DynamicAccess<AnimationData>>;
}

class SkinnableUISprite extends FlxSprite {
    public var skin(get, never):String;
    public var skinData(get, never):SkinnableUISpriteData;

    /**
     * Loads a new skin of a given ID.
     * 
     * Override this function in your own classes to provide custom skin loading.
     * 
     * @param  newSkin  The ID of the skin to load. 
     */
    public function loadSkin(newSkin:String):Void {
        if(_skin == newSkin)
            return;

        loadSkinComplex(newSkin, null, "");
    }

    public function loadSkinComplex(newSkin:String, skinData:SkinnableUISpriteData, skinDir:String, ?allowAnimateAtlas:Bool = true):Void {
        _skin = newSkin;
        _skinData = skinData;

        switch(_skinData.atlas.type) {
            case SPARROW:
                frames = Paths.getSparrowAtlas('${skinDir}/${_skinData.atlas.path}');

            case GRID:
                final gridSize:PointData<Int> = _skinData.atlas.gridSize ?? {x: 0, y: 0};
                loadGraphic(Paths.image('${skinDir}/${_skinData.atlas.path}'), true, gridSize.x, gridSize.y);

            case ANIMATE:
                // TODO: this shit

            case IMAGE:
                final atlasKey:String = '#_ATLAS_${skinDir}:${_skinData.atlas.path}';
                final graph:FlxGraphic = FlxG.bitmap.get(atlasKey);

                if(graph != null)
                    frames = graph.atlasFrames;
                else {
                    final keys:Array<String> = [];
                    final bitmaps:Array<BitmapData> = [];
                    
                    for(animName => data in _skinData.animation) {
                        final bitmapPath:String = Paths.image('${skinDir}/${_skinData.atlas.path}/${data.texture ?? animName}');
                        if(!FlxG.assets.exists(bitmapPath)) {
                            Logs.error('Could not find image at ${bitmapPath}, this image won\'t be packed!');
                            continue;
                        }
                        keys.push('${animName}0000');
                        bitmaps.push(FlxG.assets.getBitmapData(bitmapPath));
                    }
                    final atlas:FlxAtlas = new FlxAtlas(atlasKey);
                    atlas.addNodes(bitmaps, keys);
    
                    frames = atlas.getAtlasFrames();

                    // FlxAtlas creates a new graphic containing
                    // the spritesheet for the stuff, so delete the bitmaps we loaded
                    @:privateAccess
                    for(bitmap in bitmaps) {
                        if(bitmap == null)
                            continue;

                        if(bitmap.__texture != null)
                            bitmap.__texture.dispose();

                        bitmap.disposeImage();
                        bitmap.dispose();
                    }
                }
        }
        for(animName => data in _skinData.animation) {
            if(data.prefix != null) {
                if(!data.indices.isEmpty())
                    animation.addByIndices(animName, data.prefix, data.indices, "", data.fps ?? 24, data.looped ?? false);
                else
                    animation.addByPrefix(animName, data.prefix, data.fps ?? 24, data.looped ?? false);
            } else
                animation.add(animName, data.indices, data.fps ?? 24, data.looped ?? false);
            
            animation.setOffset(animName, data.offset?.x ?? 0.0, data.offset?.y ?? 0.0);
        }
        antialiasing = _skinData.antialiasing ?? FlxSprite.defaultAntialiasing;
        
        scale.set(_skinData.scale, _skinData.scale);
        updateHitbox();
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private var _skin:String;

    @:unreflective
    private var _skinData:SkinnableUISpriteData;

    @:noCompletion
    private inline function get_skin():String {
        return _skin;
    }

    @:noCompletion
    private inline function get_skinData():SkinnableUISpriteData {
        return _skinData;
    }
}