package funkin.utilities;

class Constants {
    public static final CURRENT_OS:String = {
        #if windows
        "Windows";
        #elseif (mac || macos)
        "MacOS";
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
    public static final KEY_COUNT:Int = 4;
    public static final STRUM_SPACING:Float = 112;
    public static final PIXELS_PER_MS:Float = 0.45;
    public static final SAVE_DIR:String = "swordcube/GarfieFunkin";
    public static final DEFAULT_CHARACTER:String = "bf";
    public static final DEFAULT_HEALTH_ICON:String = "face";
    public static final NOTE_DIRECTIONS:Array<String> = ["left", "down", "up", "right"];
}