package funkin.ui.charter;

import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;

import funkin.graphics.TiledSprite;
import funkin.states.editors.ChartEditor;

class CharterSustain extends FlxSpriteGroup {
    /**
     * The note that this hold trail belongs to.
     */
    public var note:ChartEditorNote;

    public var strip:TiledSprite;
    public var tail:FlxSprite;

    /**
     * Makes a new `CharterSustain` instance.
     */
    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        strip = new TiledSprite();
        add(strip);

        tail = new FlxSprite();
        add(tail);

        strip.frames = Paths.getSparrowAtlas('editors/charter/images/notes');
        tail.frames = Paths.getSparrowAtlas('editors/charter/images/notes');
        
        for(i in 0...Constants.KEY_COUNT) {
            strip.animation.addByPrefix(Constants.NOTE_DIRECTIONS[i], '${Constants.NOTE_DIRECTIONS[i]} hold', 24, false);
            tail.animation.addByPrefix(Constants.NOTE_DIRECTIONS[i], '${Constants.NOTE_DIRECTIONS[i]} tail', 24, false);
        }
        strip.alpha = 1;
        tail.alpha = 1;
        
        @:bypassAccessor alpha = 1;
        height = height;

        directAlpha = true;
    }

    public function updateSustain(direction:Int, scale:Float):Void {
        strip.animation.play(Constants.NOTE_DIRECTIONS[direction]);
        tail.animation.play(Constants.NOTE_DIRECTIONS[direction]);

        strip.scale.set(scale, scale);
        strip.updateHitbox();

        tail.scale.set(scale, scale);
        tail.updateHitbox();
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    @:noCompletion
    override function set_height(Value:Float):Float {
        if(strip != null) {
            final calcHeight:Float = Value - tail.height;
            strip.visible = calcHeight > 0;
            strip.height = Math.max(calcHeight, 0);

            tail.flipY = strip.flipY;
            visible = Value > 0;

            if(tail.flipY) {
                strip.y = y - calcHeight;
                tail.y = strip.y - tail.height;
            } else {
                strip.y = y;
                tail.y = y + calcHeight;
            }
            final strumCenter:Float = y;
            final clipRect:FlxRect = (tail.clipRect ?? FlxRect.get()).set(0, 0, tail.frameWidth, tail.frameHeight);
            if(tail.flipY) {
                clipRect.height = (strumCenter - tail.y) / tail.scale.y;
                clipRect.y = tail.frameHeight - clipRect.height;
            } else {
                clipRect.y = (strumCenter - tail.y) / tail.scale.y;
                clipRect.height -= clipRect.y;
            }
            tail.clipRect = clipRect;
        }
        return Value;
    }
}