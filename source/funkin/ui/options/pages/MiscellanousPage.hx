package funkin.ui.options.pages;

class MiscellanousPage extends OptionPage {
    public function new() {
        super("Miscellanous");
    }

    override function initOptions():Void {
        addOption({
            name: "Auto Pause",
            description: "Changes whether or not the game will automatically\npause when the window is unfocused.",

            id: "autoPause",
            type: TCheckbox,

            callback: (value:Dynamic, _) -> FlxG.autoPause = value
        });
        addOption({
            name: "Verbose Logging",
            description: "Whether or not detailed engine logs can appear for debugging purposes.",
        
            id: "verboseLogging",
            type: TCheckbox
        });
        addOption({
            name: "Loading Screen",
            description: "Whether or not the game should display\na loading screen while loading into gameplay.",
        
            id: "loadingScreen",
            type: TCheckbox
        });
        #if LINUX_CASE_INSENSITIVE_FILES
        addOption({
            name: "Case Insensitive Files",
            description: "Whether or not the game should use case insensitive file paths.\n\nLeaving this on may cause loading times to be a bit worse, but will\nensure mods load their assets correctly.",
        
            id: "caseInsensitiveFiles",
            type: TCheckbox
        });
        #end
        final fpsOption:NumberOption = cast addOption({
            name: "Framerate",
            description: "Changes the target FPS the game will try to run at.",
        
            id: "frameRate",
            type: TInt(5, 1000, 5), // actual minimum is 10, will be set to unlimited if set below 10

            callback: (value:Dynamic, option:Option) -> {
                final fps:Int = cast value;
                if(fps < 10) {
                    // unlimited
                    FlxG.updateFramerate = 0;
                    FlxG.drawFramerate = 0;
                } else {
                    // capped
                    if(fps > FlxG.drawFramerate) {
                        FlxG.updateFramerate = fps;
                        FlxG.drawFramerate = fps;
                    } else {
                        FlxG.drawFramerate = fps;
                        FlxG.updateFramerate = fps;
                    }
                }
            }
        });
        fpsOption.updateValue = (value:Dynamic) -> {
            final fps:Int = cast value;
            if(fps < 10) {
                // unlimited
                fpsOption.valueText.text = "Unlimited";
            } else {
                // capped
                fpsOption.valueText.text = Std.string(fps);
            }
        }
        fpsOption.updateValue(fpsOption.getValue());
        super.initOptions();
    }
}