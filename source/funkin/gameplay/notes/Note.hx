package funkin.gameplay.notes;

import flixel.util.FlxColor;

import funkin.backend.events.NoteEvents;

import funkin.gameplay.notes.NoteSkin;
import funkin.graphics.SkinnableSprite;

import funkin.states.PlayState;

/**
 * A class representing a step at which you
 * should be given score.
 * 
 * This is primarily used for scoring systems which
 * allow hold notes to give you score, such as PBOT.
 */
@:structInit
class ScoreStep {
    public var time:Float;
    public var score:Int;
}

class Note extends SkinnableSprite {
    public var strumLine:StrumLine;

    public var time:Float;
    public var direction(default, set):Int;
    public var length:Float;
    public var type:String;

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

    public var wasHit:Bool = false;
    public var wasMissed:Bool = false;

    public var holdTrail:HoldTrail;
    public var stepLength:Float;

    public var curScoreStep:Int = 0;
    public var scoreSteps:Array<ScoreStep> = [];

    @:noCompletion
    public var hitEvent:NoteHitEvent; // meant for internal use, don't care enough to make it private :/

    @:noCompletion
    public var missEvent:NoteMissEvent; // meant for internal use, don't care enough to make it private :/

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        hitEvent = new NoteHitEvent();
        missEvent = new NoteMissEvent();
        holdTrail = new HoldTrail(-999999, -999999);
    }

    public function setup(strumLine:StrumLine, time:Float, direction:Int, length:Float, type:String, skin:String):Note {
        loadSkin(skin);
        scale.set(_skinData.scale, _skinData.scale);

        this.strumLine = strumLine;
        this.time = time;
        this.direction = direction % Constants.KEY_COUNT;
        this.length = Math.max(length, 0.0);
        this.type = type;

        curScoreStep = 0;
        scoreSteps.resize(0);

        final playbackRate:Float = (!(PlayState.instance?.isStoryMode ?? false)) ? Options.gameplayModifiers.get("playbackRate") : 1;
        for(i in 0...Std.int(this.length / stepLength))
            scoreSteps.push({time: time + ((i + 1) * stepLength), score: Std.int(145 * playbackRate)});
        
        holdTrail.setup(this, skin);

        // reset a bunch of properties the programmer
        // could end up changing via note types

        // which i underestimated when writing this comment
        // holy SHIT there's a lot to account for
        angle = 0;
        alpha = _skinData.alpha;
        shader = null;
        visible = true;
        wasHit = false;
        wasMissed = false;
        frameOffset.set();
        color = FlxColor.WHITE;

        @:privateAccess {
            holdTrail.alpha = holdTrail.strip._skinData.alpha;
            holdTrail.strip.alpha = holdTrail.strip._skinData.alpha;
            holdTrail.tail.alpha = holdTrail.strip._skinData.alpha;
        }
        holdTrail.angle = 0;
        holdTrail.visible = true;

        holdTrail.strip.shader = null;
        holdTrail.tail.shader = null;

        holdTrail.strip.color = FlxColor.WHITE;
        holdTrail.tail.color = FlxColor.WHITE;

        holdTrail.strip.frameOffset.set();
        holdTrail.tail.frameOffset.set();

        colorTransform.redOffset = colorTransform.greenOffset = colorTransform.blueOffset = 0;
        colorTransform.redMultiplier = colorTransform.greenMultiplier = colorTransform.blueMultiplier = 1;

        holdTrail.strip.colorTransform.redOffset = holdTrail.strip.colorTransform.greenOffset = holdTrail.strip.colorTransform.blueOffset = 0;
        holdTrail.strip.colorTransform.redMultiplier = holdTrail.strip.colorTransform.greenMultiplier = holdTrail.strip.colorTransform.blueMultiplier = 1;

        holdTrail.tail.colorTransform.redOffset = holdTrail.tail.colorTransform.greenOffset = holdTrail.tail.colorTransform.blueOffset = 0;
        holdTrail.tail.colorTransform.redMultiplier = holdTrail.tail.colorTransform.greenMultiplier = holdTrail.tail.colorTransform.blueMultiplier = 1;

        setPosition(-99999, -99999);
        holdTrail.setPosition(-99999, -99999);

        return this;
    }

    public function isInRange():Bool {
        return Math.abs(time - (strumLine?.playField.attachedConductor.time ?? Conductor.instance.time)) <= Options.hitWindow;
    }

    override function loadSkin(newSkin:String) {
        if(_skin == newSkin)
            return;

        final json:NoteSkinData = NoteSkin.get(newSkin);
        loadSkinComplex(newSkin, json.note, 'gameplay/noteskins/${newSkin}');

        direction = direction; // force animation update
    }
    
    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_direction(newDirection:Int):Int {
        direction = newDirection;
        animation.play('${Constants.NOTE_DIRECTIONS[direction]} scroll');

        centerOrigin();        
        updateHitbox();

        centerOffsets();
        offset.add(skinData.offset[0] ?? 0.0, skinData.offset[1] ?? 0.0);

        return direction;
    }
}