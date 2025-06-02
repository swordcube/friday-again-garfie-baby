package funkin.gameplay.notes;

import flixel.math.FlxRect;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;

import flixel.system.FlxAssets.FlxShader;

class HoldTrail extends FlxSpriteContainer {
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
        strip.holdTrail = this;
        add(strip);

        tail = new HoldTail();
        tail.holdTrail = this;
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
            strip.updateHitbox();
            strip.setPosition(-999999, -999999);
            strip.offset.add(strip.skinData.offset[0] ?? 0.0, strip.skinData.offset[1] ?? 0.0);
            
            tail.animation.play('${laneStr} tail', true);
            tail.updateHitbox();
            tail.setPosition(-999999, -999999);
            tail.offset.add(tail.skinData.offset[0] ?? 0.0, tail.skinData.offset[1] ?? 0.0);

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
            @:privateAccess {
                strip.loadSkin(skin);
                strip.alpha = strip._skinData.alpha;
    
                tail.loadSkin(skin);
                tail.alpha = strip._skinData.alpha;
                
                @:bypassAccessor alpha = strip._skinData.alpha;
            }
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

            if(tail.clipRect == null)
                tail.clipRect = FlxRect.get();
            
            final clipRect:FlxRect = tail.clipRect.set(0, 0, tail.frameWidth, tail.frameHeight);
            if(note == null || (note.wasHit && !note.wasMissed)) {
                if(tail.flipY) {
                    clipRect.height = (strumCenter - tail.y) / tail.scale.y;
                    clipRect.y = tail.frameHeight - clipRect.height;
                } else {
                    clipRect.y = (strumCenter - tail.y) / tail.scale.y;
                    clipRect.height -= clipRect.y;
                }
            }
        }
        return Value;
    }

    @:noCompletion
    override function set_shader(newShader:FlxShader):FlxShader {
        strip.shader = newShader;
        tail.shader = newShader;
        return newShader;
    }
}