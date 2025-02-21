package funkin.ui;

import funkin.graphics.SkinnableSprite.AtlasData;

@:structInit
class AtlasFont {
    public var atlas:AtlasData;

    @:optional
    @:default({x: 0, y: 0})
    public var offset:PointData<Float>;
    
    @:optional
    @:default(24)
    public var fps:Float;

    @:optional
    @:default(1.0)
    public var scale:Float;

    @:optional
    @:default(60)
    public var lineHeight:Float;

    @:optional
    @:default(false)
    public var noLowerCase:Bool;

    public var glyphs:Map<String, AtlasFontGlyph>;
}

@:structInit
class AtlasFontGlyph {
    @:optional
    public var prefix:String;

    @:optional
    @:default({x: 0, y: 0})
    public var offset:PointData<Float>;

    @:optional
    @:default(0.0)
    public var width:Float;

    @:optional
    @:default(0.0)
    public var height:Float;

    @:optional
    @:default(true)
    public var visible:Bool;
}