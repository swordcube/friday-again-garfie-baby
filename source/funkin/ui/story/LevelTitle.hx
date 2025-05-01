package funkin.ui.story;

class LevelTitle extends FlxSpriteContainer {
    public static final Y_OFFSET:Float = 476;
    public static final FLASH_FPS:Float = 20;

    public var title:FlxSprite;
    
    public var flashTimer:Float = 0;
    public var isFlashing:Bool = false;

    public function new(x:Float = 0, y:Float = 0, levelName:String, ?loaderID:String) {
        super(x, y);
        final imgPath:String = Paths.image("menus/story/levels/" + levelName, loaderID);
        
        title = new FlxSprite().loadGraphic((FlxG.assets.exists(imgPath)) ? imgPath : Paths.image("menus/story/levels/unknown"));
        add(title);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        visible = y > 112;
    
        if(isFlashing) {
            flashTimer += elapsed;
            if(flashTimer >= 1 / FLASH_FPS) {
                flashTimer = 0;
                title.color = (title.color == FlxColor.WHITE) ? 0xFF33FFFF : FlxColor.WHITE;
            }
        }
    }

    public function startFlashing():Void {
        isFlashing = true;
        flashTimer = 0;
    }

    public function stopFlashing():Void {
        isFlashing = false;
        title.color = FlxColor.WHITE;
    }
}