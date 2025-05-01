package funkin.ui.story.character;

import funkin.graphics.AtlasType;
import funkin.graphics.SkinnableSprite;

@:structInit
class StoryCharacterData {
    @:jignored
    @:optional
    public var id:String;

    public var atlas:AtlasData;

    @:optional
    @:default([0, 0])
    public var gridSize:Array<Float>;
    
    public var animations:Map<String, AnimationData>;//DynamicAccess<AnimationData>;
    
    @:optional
    @:default([0, 0])
    public var position:Array<Float>;

    @:optional
    @:default(1)
    public var scale:Float = 1;

    @:optional
    @:default(false)
    public var flipX:Bool;

    @:optional
    @:default(false)
    public var flipY:Bool;

    @:optional
    @:default(true)
    public var antialiasing:Bool;

    @:optional
    @:default(["idle"])
    public var danceSteps:Array<String>;

    @:optional
    @:default("hey")
    public var confirmAnim:String;

    /**
     * Returns fallback character data in the case that
     * loading it from JSON fails.
     */
    public static function getDefaultData():StoryCharacterData {
        return {
            id: Constants.DEFAULT_CHARACTER,
            atlas: {
                type: SPARROW,
                path: "sprite"
            },
            animations: []
        };
    }

    /**
     * Returns the character data for a given character.
     * 
     * @param  charID  The name of the character to fetch data from.
     */
    public static function load(charID:String):StoryCharacterData {
        var confPath:String = Paths.json('menus/story/characters/${charID}/config');
        if(FlxG.assets.exists(confPath)) {
            var data:StoryCharacterData = null;
            try {
                final parser:JsonParser<StoryCharacterData> = new JsonParser<StoryCharacterData>();
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
        confPath = Paths.json('menus/story/characters/${charID}/config');
        
        var data:StoryCharacterData = null;
        try {
            final parser:JsonParser<StoryCharacterData> = new JsonParser<StoryCharacterData>();
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

    public static function stringify(data:StoryCharacterData):String {
        final writer:JsonWriter<StoryCharacterData> = new JsonWriter<StoryCharacterData>();
		return writer.write(data, "\t");
    }
}