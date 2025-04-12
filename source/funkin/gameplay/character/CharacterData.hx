package funkin.gameplay.character;

import funkin.graphics.AtlasType;
import funkin.graphics.SkinnableSprite;

@:structInit
class CharacterData {
    @:jignored
    @:optional
    public var id:String;

    @:optional
    public var healthIcon:HealthIconData;

    public var atlas:AtlasData;

    @:optional
    @:default({x: 0, y: 0})
    public var gridSize:PointData<Float> = {x: 0, y: 0};
    
    public var animations:Map<String, AnimationData>;//DynamicAccess<AnimationData>;
    
    @:optional
    @:default({x: 0, y: 0})
    public var position:PointData<Float> = {x: 0, y: 0};
    
    @:optional
    @:default({x: 0, y: 0})
    public var camera:PointData<Float> = {x: 0, y: 0};

    @:optional
    @:default(1)
    public var scale:Float = 1;

    @:optional
    @:default({x: false, y: false})
    public var flip:PointData<Bool> = {x: false, y: false};

    @:optional
    @:default(false)
    public var isPlayer:Bool = false;

    @:optional
    @:default(true)
    public var antialiasing:Bool = true;

    @:optional
    @:default(4)
    public var singDuration:Float = 4;

    @:optional
    @:default(["idle"])
    public var danceSteps:Array<String> = ["idle"];

    @:optional
    @:default(["singLEFT", "singDOWN", "singUP", "singRIGHT"])
    public var singSteps:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

    @:optional
    @:default(["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"])
    public var missSteps:Array<String> = ["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"];

    /**
     * Returns fallback character data in the case that
     * loading it from JSON fails.
     */
    public static function getDefaultData():CharacterData {
        return {
            id: Constants.DEFAULT_CHARACTER,
            atlas: {
                type: SPARROW,
                path: "sprite"
            },
            healthIcon: {
                isPixel: false,
                scale: 1,
                flip: {x: false, y: false},
                offset: {x: 0, y: 0},
                color: "#FFFFFF"
            },
            animations: []
        };
    }

    /**
     * Returns the character data for a given character.
     * 
     * @param  charID  The name of the character to fetch data from.
     */
    public static function load(charID:String):CharacterData {
        var confPath:String = Paths.json('gameplay/characters/${charID}/config');
        if(FlxG.assets.exists(confPath)) {
            var data:CharacterData = null;
            try {
                final parser:JsonParser<CharacterData> = new JsonParser<CharacterData>();
                parser.ignoreUnknownVariables = true;

                data = parser.fromJson(FlxG.assets.getText(confPath));
                data.id = charID;
            }
            catch(e) {
                data = getDefaultData();
                Logs.error('Failed to load config for character "${charID}": ${e}');
            }
            return data;
        }
        Logs.error('Config for character "${charID}" doesn\'t exist!');
        
        charID = Constants.DEFAULT_CHARACTER;
        confPath = Paths.json('gameplay/characters/${charID}/config');
        
        var data:CharacterData = null;
        try {
            final parser:JsonParser<CharacterData> = new JsonParser<CharacterData>();
            parser.ignoreUnknownVariables = true;

            data = parser.fromJson(FlxG.assets.getText(confPath));
            data.id = charID;
        }
        catch(e) {
            data = getDefaultData();
            Logs.error('Failed to load default character config: ${e}');
        }
        return data;
    }
}

@:structInit
class HealthIconData {
	@:optional
	@:default(false)
	public var isPixel:Bool = false;

	@:optional
	@:default(1)
	public var scale:Float = 1;

	@:optional
	@:default({x: false, y: false})
	public var flip:PointData<Bool> = {x: false, y: false};

	@:optional
	@:default({x: 0, y: 0})
	public var offset:PointData<Float> = {x: 0, y: 0};

	@:optional
	@:default("#FFFFFF")
	public var color:String = "#FFFFFF";
}