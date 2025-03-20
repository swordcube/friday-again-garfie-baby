package funkin.backend;

import funkin.assets.loaders.AssetLoader;

@:structInit
class WeekData {
    @:optional
    @:default("NO TAGLINE SPECIFIED")
    public var tagline:String;

    @:optional
    @:default([null, "bf", null])
    public var characters:Array<String>;

    @:optional
    @:default({story: [], freeplay: []})
    public var hiddenSongs:HiddenSongs;
    
    @:optional
    @:default([])
    public var songs:Array<String>;

    @:optional
    @:default("main")
    public var freeplayCategory:String;

    @:optional
    @:default([])
    public var mixes:Array<String>;

    @:optional
    @:default(["default" => ["easy", "normal", "hard"]])
    public var difficulties:Map<String, Array<String>>;
}

@:structInit
class HiddenSongs {
    @:optional
    @:default([])
    public var story:Array<String>;
    
    @:optional
    @:default([])
    public var freeplay:Array<String>;
}