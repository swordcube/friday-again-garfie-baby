package funkin.backend;

import funkin.assets.loaders.AssetLoader;

import funkin.graphics.SkinnableSprite.AtlasData;
import funkin.graphics.SkinnableSprite.AnimationData;

enum abstract WeekPropType(Int) from Int to Int {
    final UNKNOWN = -1;

    final OPPONENT = 0;
    final PLAYER = 1;
    final SPECTATOR = 2;
}

@:structInit
class WeekSongData {
    public var id:String;

    @:optional
    @:default(false)
    public var hiddenOnStory:Bool;

    @:optional
    @:default(false)
    public var hiddenOnFreeplay:Bool;

    /**
     * Whether or not this song needs to be
     * played in story mode before being able
     * to play it through freeplay.
     */
    @:optional
    @:default(false)
    public var needsUnlock:Bool;
}

@:structInit
class WeekPropData {
    @:optional
    @:default(-1)
    public var id:WeekPropType;

    @:optional
    @:default(0.0)
    public var x:Float;
    
    @:optional
    @:default(0.0)
    public var y:Float;

	public var atlas:AtlasData;
	public var scale:Float;

	@:optional
    @:default(null)
	public var antialiasing:Null<Bool>;

	public var animation:Map<String, AnimationData>;//DynamicAccess<AnimationData>;
}

@:structInit
class WeekList {
    public var loaderID:String;
    public var data:Array<String>;
}

@:structInit
class WeekData {
    @:jignored
    public var loaderID:String;

    public var tagline:String;
    public var songs:Array<WeekSongData>;

    public var color:String;
    public var props:Array<WeekPropData>;

    public static function getWeekLists():Array<WeekList> {
        final weekList:Array<WeekList> = [];
        final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;

        for(i in 0...loaders.length) {
            final loader:AssetLoader = loaders[i];
            final path:String = loader.getPath("gameplay/weeks/weekList.txt");
            if(FlxG.assets.exists(path)) {
                weekList.push({
                    loaderID: loader.id,
                    data: FlxG.assets.getText(path).replace("\r", "").split('\n')
                });
            }
        }
        return weekList;
    }

    public static function getDefaultData():WeekData {
        return {
            loaderID: null,

            tagline: "N/A",
            songs: [
                {
                    id: "error",
                    hiddenOnStory: false
                }
            ],
            color: "#FF0000",
            props: []
        };
    }

    public static function load(weekID:String, ?loaderID:String):WeekData {
        if(loaderID != null && loaderID.length != 0) {
            final loaders:Map<String, AssetLoader> = Paths._registeredAssetLoadersMap;
            final loader:AssetLoader = loaders.get(loaderID);
            
            final path:String = loader.getPath('gameplay/weeks/${weekID}.json');
            if(FlxG.assets.exists(path)) {
                final parser:JsonParser<WeekData> = new JsonParser<WeekData>();
                parser.ignoreUnknownVariables = true;

                final data:WeekData = parser.fromJson(FlxG.assets.getText(path));
                data.loaderID = loaderID;
                return data;
            }
        } else {
            final path:String = Paths.json('gameplay/weeks/${weekID}');
            if(FlxG.assets.exists(path)) {
                final parser:JsonParser<WeekData> = new JsonParser<WeekData>();
                parser.ignoreUnknownVariables = true;

                final data:WeekData = parser.fromJson(FlxG.assets.getText(path));
                if(path.startsWith('${ModManager.MOD_DIRECTORY}/'))
                    data.loaderID = path.split('/')[1];

                return data;
            }
        }
        return getDefaultData();
    }
}