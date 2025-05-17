package funkin.gameplay.stage;

enum abstract StagePropType(String) from String to String {
    final SPRITE = "sprite";
    final BOX = "box";
    
    final SPECTATOR = "spectator";
    final OPPONENT = "opponent";
    final PLAYER = "player";
    
    final COMBO = "combo";
}

@:structInit
class StageData {
    @:jignored
    @:optional
    public var id:String;

    public var zoom:Float;
    public var folders:Map<String, String>;

    @:optional
    @:default([])
    public var preload:Array<AssetPreload>;

    public var layers:Array<Array<StagePropData>>;

    @:optional
    @:default([0, 0])
    public var startingCamPos:Array<Float>;

    public static function load(stageID:String):StageData {
        final confPath:String = Paths.json('gameplay/stages/${stageID}/config');
        if(FlxG.assets.exists(confPath)) {
            var data:StageData = null;
            try {
                final parser:JsonParser<StageData> = new JsonParser<StageData>();
                parser.ignoreUnknownVariables = true;
                
                data = parser.fromJson(FlxG.assets.getText(confPath));
                data.id = stageID;
            }
            catch(e) {
                data = getDefaultData();
                Logs.error('Failed to load config for stage "${stageID}": ${e}');
            }
            return data;
        }
        Logs.error('Config for stage "${stageID}" doesn\'t exist!');
        return getDefaultData();
    }

    public static function getDefaultData():StageData {
        return {
            zoom: 0.95,
            folders: [
                "images" => "images",
                "sfx" => "sfx"
            ],
            layers: []
        }
    }

    public function getImageFolder():String {
        return 'gameplay/stages/${id}/${folders.get("images")}';
    }
    
    public function getSFXFolder():String {
        return 'gameplay/stages/${id}/${folders.get("sfx")}';
    }
}

@:structInit
class StagePropData {
    @:optional // NOTE: Characters are the only props that don't require IDs!!
    public var id:String;

    public var type:StagePropType;

    @:jcustomparse(funkin.utilities.DataParse.dynamicValue)
	@:jcustomwrite(funkin.utilities.DataWrite.dynamicValue)
    public var properties:Dynamic;
}