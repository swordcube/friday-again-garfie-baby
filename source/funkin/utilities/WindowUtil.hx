package funkin.utilities;

class WindowUtil {
    public static var title(default, set):String = "";
    public static var titlePrefix(default, set):String = "";
    public static var titleSuffix(default, set):String = "";

    public static function resetTitle():Void {
        title = FlxG.stage.application.meta.get("name");
    }

    public static function updateTitle():Void {
        FlxG.stage.window.title = '${titlePrefix}${title}${titleSuffix}';
    }

    public static function resetTitleAffixes():Void {
        titlePrefix = titleSuffix = "";
        updateTitle();
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private static function set_title(newTitle:String):String {
        if(title == newTitle)
            return title;
        
        title = newTitle;
        updateTitle();

        return title;
    }

    @:noCompletion
    private static function set_titlePrefix(newPrefix:String):String {
        if(titlePrefix == newPrefix)
            return titlePrefix;
        
        titlePrefix = newPrefix;
        updateTitle();

        return titlePrefix;
    }

    @:noCompletion
    private static function set_titleSuffix(newSuffix:String):String {
        if(titleSuffix == newSuffix)
            return titleSuffix;
        
        titleSuffix = newSuffix;
        updateTitle();

        return titleSuffix;
    }
}