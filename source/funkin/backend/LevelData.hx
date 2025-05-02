package funkin.backend;

@:structInit
class LevelData {
    @:optional
    public var loaderID:String;

    public var name:String;

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
    @:default(true)
    public var showInStory:Bool;

    @:optional
    @:default(true)
    public var showInFreeplay:Bool;

    @:optional
    @:default(true)
    public var startUnlocked:Bool;

    @:optional
    public var levelBefore:String;

    @:optional
    @:default("main")
    public var freeplayCategory:String;

    @:optional
    @:default([])
    public var mixes:Array<String>;

    @:optional
    @:default(["default" => ["easy", "normal", "hard"]])
    public var difficulties:Map<String, Array<String>>;

    @:optional
    @:default("#F9CF51")
    public var banner:String;
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