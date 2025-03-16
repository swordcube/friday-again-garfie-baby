package funkin.ui;

import flixel.text.FlxText;

class Label extends FlxText {
    public function new(x:Float = 0, y:Float = 0, text:String, ?size:Int = 14, ?bold:Bool = true) {
        super(x, y, 0, text, size);
        setFormat(Paths.font('fonts/montserrat/${(bold) ? "semibold" : "regular"}'), size, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
    }
}