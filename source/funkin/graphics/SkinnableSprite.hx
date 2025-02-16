package funkin.graphics;

import haxe.DynamicAccess;

typedef AtlasData = {
    var type:AtlasType;
    var path:String;
    var ?gridSize:PointData<Int>;
}

typedef AnimationData = {
    var ?prefix:String;
    var ?indices:Array<Int>;

    var fps:Float;
    var ?looped:Bool;

    var ?offset:PointData<Float>;
}

typedef SkinnableSpriteData = {
    var atlas:AtlasData;
    var scale:Float;
    var ?antialiasing:Bool;
    var animation:DynamicAccess<DynamicAccess<AnimationData>>;
}

class SkinnableSprite extends FlxSprite {
    public var skin(get, never):String;
    public var skinData(get, never):SkinnableSpriteData;

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

    public function loadSkinComplex(newSkin:String, skinData:SkinnableSpriteData, skinDir:String, ?allowAnimateAtlas:Bool = true):Void {
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
        }
        for(key => data in _skinData.animation) {
            for(key2 => data2 in data) {
                final animName:String = '${key2} ${key}';
                if(data2.prefix != null) {
                    if(!data2.indices.isEmpty())
                        animation.addByIndices(animName, data2.prefix, data2.indices, "", data2.fps, data2.looped ?? false);
                    else
                        animation.addByPrefix(animName, data2.prefix, data2.fps, data2.looped ?? false);
                } else
                    animation.add(animName, data2.indices, data2.fps, data2.looped ?? false);
                
                animation.setOffset(animName, data2.offset?.x ?? 0.0, data2.offset?.y ?? 0.0);
            }
        }
        antialiasing = _skinData.antialiasing ?? FlxSprite.defaultAntialiasing;
        
        scale.set(_skinData.scale, _skinData.scale);
        updateHitbox();
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private var _skin:String;

    @:unreflective
    private var _skinData:SkinnableSpriteData;

    @:noCompletion
    private inline function get_skin():String {
        return _skin;
    }

    @:noCompletion
    private inline function get_skinData():SkinnableSpriteData {
        return _skinData;
    }
}