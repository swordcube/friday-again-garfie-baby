package funkin.backend;

@:structInit
class ContentMetadata {
    @:jignored
    public var folder:String;

    @:optional
    @:default("0.1.0")
    public var apiVersion:String;

    @:optional
    @:default(false)
    @:unreflective
    public var allowUnsafeScripts:Bool;

    @:optional
    @:default(false)
    public var runGlobally:Bool;
    
    @:optional
    @:default([])
    public var weeks:Array<WeekData>;

    @:optional
    @:default([{id: "main", name: "Main"}])
    public var freeplayCategories:Array<FreeplayCategory>;

    @:optional
    @:default("main")
    public var defaultCategory:String;
}

@:structInit
class FreeplayCategory {
    public var id:String;
    public var name:String;
}