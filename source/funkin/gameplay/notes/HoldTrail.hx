package funkin.gameplay.notes;

import flixel.math.FlxRect;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;

class HoldTrail extends FlxSpriteGroup {
    /**
     * The note that this hold trail belongs to.
     */
    public var note:Note;

    public var strip:HoldTiledSprite;
    public var tail:HoldTail;

    /**
     * The name of the noteskin applied to this hold trail.
     */
    public var skin(default, set):String;

    /**
     * Determines how offset the X position of this hold trail
     * should be, in pixels.
     */
    public var offsetX:Float = 0;

    /**
     * Determines how offset the Y position of this hold trail
     * should be, in pixels.
     */
    public var offsetY:Float = 0;

    /**
     * Makes a new `HoldTrail` instance.
     */
    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        strip = new HoldTiledSprite();
        add(strip);

        tail = new HoldTail();
        add(tail);

        directAlpha = true;
    }

    /**
     * Sets up this note to be spawned on-screen.
     */
    public function setup(note:Note, skin:String):Void {
        this.note = note;
        this.skin = skin;

        if(note.length <= 0)
            kill();
        else {
            revive();
            final laneStr:String = Constants.NOTE_DIRECTIONS[note.direction];

            strip.animation.play('${laneStr} hold', true);
            strip.setPosition(-999999, -999999);
            
            tail.animation.play('${laneStr} tail', true);
            tail.setPosition(-999999, -999999);

            height = height;
        }
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    @:noCompletion
    private function set_skin(newSkin:String):String {
        if(skin != newSkin) {
            skin = newSkin;
    
            strip.loadSkin(skin);
            strip.alpha = 1;

            tail.loadSkin(skin);
            tail.alpha = 1;
            
            @:bypassAccessor alpha = 1;
            height = height;
        }
        return skin;
    }

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
            final strum:Strum = note.strumLine.strums.members[note.direction];
            final strumCenter:Float = (strum != null) ? strum.y + (strum.height * 0.5) : y;
            
            final clipRect:FlxRect = (tail.clipRect ?? FlxRect.get()).set(0, 0, tail.frameWidth, tail.frameHeight);
            if(note == null || (note.wasHit && !note.wasMissed)) {
                if(tail.flipY) {
                    clipRect.height = (strumCenter - tail.y) / tail.scale.y;
                    clipRect.y = tail.frameHeight - clipRect.height;
                } else {
                    clipRect.y = (strumCenter - tail.y) / tail.scale.y;
                    clipRect.height -= clipRect.y;
                }
            }
            tail.clipRect = clipRect;
        }
        return Value;
    }
}