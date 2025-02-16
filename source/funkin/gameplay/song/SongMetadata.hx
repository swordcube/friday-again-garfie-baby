package funkin.gameplay.song;

import haxe.DynamicAccess;

typedef SongData = {
    var title:String;

    var mixes:Array<String>;
    var difficulties:Array<String>;

    var bpm:Float;
    var timingPoints:Array<CompressedTimingPoint>;

    var artist:String;
    var charter:String;
}

typedef FreeplayData = {
    var ratings:DynamicAccess<Int>;

    var icon:String;
    var album:String;
}

typedef GameplayData = {
    var characters:DynamicAccess<String>;
    var scrollSpeed:DynamicAccess<Float>;

    var stage:String;
    var uiSkin:String;
}

typedef SongMetadata = {
    var song:SongData;
    var freeplay:FreeplayData;
    var game:GameplayData;
}