package funkin.ui;

class Checkbox extends FlxSprite {
    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        frames = Paths.getSparrowAtlas("menus/options/checkbox");
        animation.addByPrefix("unselected", "unselected", 24, false);
        animation.setOffset("unselected", 0, 0);
    
        animation.addByPrefix("selecting", "selecting", 24, false);
        animation.setOffset("selecting", 25, 100);
    
        scale.set(0.7, 0.7);
        unselect();
    }
    
    public function unselect():Void {
        animation.play("unselected", true);
        updateHitbox();
    }
    
    public function select():Void {
        animation.play("selecting", true);
        updateHitbox();
    }
}