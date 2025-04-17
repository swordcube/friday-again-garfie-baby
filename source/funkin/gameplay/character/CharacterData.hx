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
    @:default([0, 0])
    public var gridSize:Array<Float>;
    
    public var animations:Map<String, AnimationData>;//DynamicAccess<AnimationData>;
    
    @:optional
    @:default([0, 0])
    public var position:Array<Float>;
    
    @:optional
    @:default([0, 0])
    public var camera:Array<Float>;

    @:optional
    @:default(1)
    public var scale:Float = 1;

    @:optional
    @:default([false, false])
    public var flip:Array<Bool>;

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
    @:default("bf-dead")
    public var deathCharacter:String = "bf-dead";

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
                flip: [false, false],
                offset: [0, 0],
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

    public static function stringify(data:CharacterData):String {
        final writer:JsonWriter<CharacterData> = new JsonWriter<CharacterData>();
		return writer.write(data, "\t");
    }
}

@:structInit
class HealthIconData {
	@:optional
	@:default(false)
	public var isPixel:Bool;

	@:optional
	@:default(1)
	public var scale:Float;

	@:optional
	@:default([false, false])
	public var flip:Array<Bool>;

	@:optional
	@:default([0, 0])
	public var offset:Array<Float>;

	@:optional
	@:default("#FFFFFF")
	public var color:String = "#FFFFFF";
}