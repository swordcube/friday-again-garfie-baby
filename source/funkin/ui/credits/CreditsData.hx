package funkin.ui.credits;

@:structInit
class CreditsData {
    public var categories:Array<CreditCategoryData> = [];

    public static function getDefaultData():CreditsData {
        return {
            categories: [
                {
                    name: "Unknown",
                    items: [
                        {
                            name: "Unknown",
                            description: "Unknown",

                            icon: "unknown",
                            color: "#FFFFFF",

                            roles: ["Unknown"],
                            url: "https://example.com"
                        }
                    ]
                }
            ]
        };
    }

    public static function load(?contentPack:String):CreditsData {
        var confPath:String = (contentPack != null && contentPack.length > 0) ? Paths.json("credits", contentPack, false) : Paths.json("credits");
        var contentPackName:String = (contentPack != null && contentPack.length > 0) ? contentPack : "default";
        if(FlxG.assets.exists(confPath)) {
            var data:CreditsData = null;
            try {
                final parser:JsonParser<CreditsData> = new JsonParser<CreditsData>();
                parser.ignoreUnknownVariables = true;
                data = parser.fromJson(FlxG.assets.getText(confPath));
            }
            catch(e) {
                data = getDefaultData();
                Logs.error('Failed to load credits config for ${contentPackName}: ${e}');
            }
            return data;
        }
        Logs.error('Credits config for ${contentPackName} doesn\'t exist!');
        return getDefaultData();
    }
}

@:structInit
class CreditCategoryData {
    public var name:String;
    public var items:Array<CreditEntryData> = [];
}

@:structInit
class CreditEntryData {
    public var name:String;
    public var description:String;

    public var icon:String;
    public var color:String;

    public var roles:Array<String> = [];
    public var url:String;
}