package funkin.utilities;

class Constants {
    /**
     * The name of the current operating system.
     * 
     * Possible values are: `Windows`, `macOS`, `Linux`, `Android`, and `iOS`.
     * 
     * If you are not running on any of the possible systems,
     * then `Unknown` will be returned.
     */
    public static final CURRENT_OS:String = {
        #if windows
        "Windows";
        #elseif (mac || macos)
        "macOS";
        #elseif linux
        "Linux";
        #elseif android
        "Android";
        #elseif ios
        "iOS";
        #else
        "Unknown";
        #end
    };

    /**
     * The width of the game area (in pixels).
     */
    public static final GAME_WIDTH:Int = 1280;

    /**
     * The height of the game area (in pixels).
     */
    public static final GAME_HEIGHT:Int = 720;

    /**
     * The maximum FPS allowed to be set in the options menu.
     */
    public static final MAX_FPS:Int = 360;

    /**
     * The number of keys per strumline.
     */
    public static final KEY_COUNT:Int = 4;

    /**
     * The amount of spacing between each strum (in pixels).
     */
    public static final STRUM_SPACING:Float = 112;

    /**
     * Magic number for note positioning.
     */
    public static final PIXELS_PER_MS:Float = 0.45;

    /**
     * The maximum amount of undos allowed in editors.
     */
    public static final MAX_UNDOS:Int = 120;

    /**
     * The save directory for the game in your system's appdata.
     */
    public static final SAVE_DIR:String = "swordcube/GarfieFunkin";

    /**
     * Whether or not the game is a development build.
     */
    public static final DEVELOPMENT_BUILD:Bool = true;

    /**
     * The default character used as a fallback.
     */
    public static final DEFAULT_CHARACTER:String = "bf";

    /**
     * The default health icon used as a fallback.
     */
    public static final DEFAULT_HEALTH_ICON:String = "face";

    /**
     * The default note skin used as a fallback.
     */
    public static final DEFAULT_NOTE_SKIN:String = "funkin";

    /**
     * The default UI skin used as a fallback.
     */
    public static final DEFAULT_UI_SKIN:String = "funkin";

    /**
     * A list of every possible note direction in order.
     */
    public static final NOTE_DIRECTIONS:Array<String> = ["left", "down", "up", "right"];
}