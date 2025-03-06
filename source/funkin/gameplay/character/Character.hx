package funkin.gameplay.character;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import funkin.backend.Conductor.IBeatReceiver;

import funkin.graphics.AtlasType;
import funkin.graphics.SkinnableSprite;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.FunkinScript;
#end

import funkin.utilities.SpriteUtil;

enum abstract AnimationContext(String) from String to String {
    /**
     * This animation will play uninterrupted
     * until the character's current animation is finished.
     * 
     * This only applies to characters with one dance step,
     * if there are more, it will immediately switch to the next one
     * depending on if the current beat matches the character's dance interval.
     */
    final DANCE = "dance";

    /**
     * This animation will stay on the current frame
     * until the amount of steps defined by the character's
     * sing duration have passed.
     */
    final SING = "sing";

    /**
     * This animation will play uninterrupted
     * by the dancing animations until it is finished.
     */
    final NONE = null;
}

@:allow(funkin.states.PlayState)
class Character extends FlxSprite implements IBeatReceiver {
    public var data(default, null):CharacterData;
    public var characterID(default, null):String;
    public var isPlayer(default, null):Bool = false;
    
    public var danceInterval:Int = 1;
    public var curDanceStep:Int = -1;

    public var holdTimer:Float = 0;
    public var curAnimContext:AnimationContext = DANCE;

    public var footOffset:FlxPoint = FlxPoint.get(0, 0);

    #if SCRIPTING_ALLOWED
    public var script:FunkinScript;
    #end

    public function new(characterID:String, isPlayer:Bool = false) {
        super();
        if(characterID == null || characterID.length == 0)
            characterID = Constants.DEFAULT_CHARACTER;

        data = CharacterData.load(characterID);
        characterID = data.id;
        
        this.characterID = characterID;
        this.isPlayer = isPlayer;

        #if SCRIPTING_ALLOWED
        final scriptPath:String = Paths.script('gameplay/characters/${characterID}/script');
        if(FlxG.assets.exists(scriptPath)) {
            script = FunkinScript.fromFile(scriptPath);
            script.setParent(this);
            script.set("this", this);
            
            script.execute();
            script.call("onCreate");
        }
        #end

        switch(data.atlas.type) {
            case SPARROW:
                frames = Paths.getSparrowAtlas('gameplay/characters/${characterID}/${data.atlas.path}');
                for(name in Reflect.fields(data.animations)) {
                    final data:AnimationData = Reflect.field(data.animations, name);
                    if(data.indices != null && data.indices.length != 0)
                        animation.addByIndices(name, data.prefix, data.indices, "", data.fps, data.looped);
                    else
                        animation.addByPrefix(name, data.prefix, data.fps, data.looped);
                    
                    animation.setOffset(name, data.offset?.x ?? 0, data.offset?.y ?? data.offset?.x ?? 0);
                }

            case GRID:
                final gridSize:PointData<Int> = data.atlas.gridSize ?? {x: 0, y: 0};
                loadGraphic(Paths.image('gameplay/characters/${characterID}/${data.atlas.path}'), true, gridSize.x ?? 0, gridSize.y ?? gridSize.x ?? 0);

                for(name in Reflect.fields(data.animations)) {
                    final data:AnimationData = Reflect.field(data.animations, name);
                    animation.add(name, data.indices, data.fps, data.looped);
                    animation.setOffset(name, data.offset?.x ?? 0, data.offset?.y ?? data.offset?.x ?? 0);
                }

            case ANIMATE:
                // TODO: that shit
        }
        flipX = data.flip.x;
        flipY = data.flip.y;

        scale.set(data.scale, data.scale);
        antialiasing = data.antialiasing ?? FlxSprite.defaultAntialiasing;

        if(isPlayer != data.isPlayer)
            swapLeftRightAnimations();

        if(isPlayer)
            flipX = !flipX;

		_baseFlipped = flipX;
        dance();

        updateHitbox();
        footOffset.set(0, height);

        offset.set(-data.position.x, height - data.position.y);

        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onUpdate", [elapsed]);
        #end

        if(curAnimContext == SING) {
            holdTimer -= elapsed * 1000;
            if(holdTimer <= 0)
                holdTimer = 0;
        }
        super.update(elapsed);

        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onUpdatePost", [elapsed]);
        #end
    }

    public function swapLeftRightAnimations():Void {
		SpriteUtil.switchAnimFrames(animation.getByName('singRIGHT'), animation.getByName('singLEFT'));
		SpriteUtil.switchAnimFrames(animation.getByName('singRIGHTmiss'), animation.getByName('singLEFTmiss'));

		SpriteUtil.switchAnimOffset(animation.getByName('singLEFT'), animation.getByName('singRIGHT'));
		SpriteUtil.switchAnimOffset(animation.getByName('singLEFTmiss'), animation.getByName('singRIGHTmiss'));
	}

    public function playAnim(name:String, ?context:AnimationContext = NONE, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0):Void {
        final lastAnimContext:AnimationContext = curAnimContext;
        switch(context) {
            case DANCE:
                if(lastAnimContext == NONE && !(animation.curAnim?.finished ?? false))
                    return;

            case SING:
                if(lastAnimContext == NONE && !(animation.curAnim?.finished ?? false))
                    return;

                holdTimer = Conductor.instance.stepLength * data.singDuration;

            default:
        }
        curAnimContext = context;
        animation.play(name, force, reversed, frame);
        offset.set(-data.position.x, height - data.position.y);
    }

    public inline function playSingAnim(direction:Int, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0):Void {
        playAnim(data.singSteps[direction % data.singSteps.length], SING, force, reversed, frame);
    }

    public inline function playMissAnim(direction:Int, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0):Void {
        playAnim(data.missSteps[direction % data.missSteps.length], SING, force, reversed, frame);
    }

    public function dance():Void {
        #if SCRIPTING_ALLOWED
        final event:ScriptEvent = Events.get(UNKNOWN).flagAsPre();
        if(script != null) {
            script.call("onDance", [event]);
            if(event.cancelled)
                return;
        }
        #end
        if(data.danceSteps.length != 0) {
            curDanceStep = (curDanceStep + 1) % data.danceSteps.length;
            playAnim(data.danceSteps[curDanceStep], DANCE);
        } else {
            curDanceStep = 0;
            playAnim(data.danceSteps[curDanceStep], DANCE);
        }
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onDancePost", [event.flagAsPost()]);
        #end
    }

    public function isFlippedOffsets():Bool {
		return (isPlayer != data.isPlayer) != (flipX != _baseFlipped);
    }

    public function getCameraPosition(?point:FlxPoint):FlxPoint {
        if(point == null)
            point = FlxPoint.get();

		final midpoint:FlxPoint = getMidpoint();
		final camPos:FlxPoint = point.set(
            (midpoint.x + (isPlayer ? -100 : 150) + data.position.x + data.camera.x) - footOffset.x,
			midpoint.y - (100 + footOffset.y) + data.position.y + data.camera.y
        );
		midpoint.put();
		return camPos;
	}

    public function stepHit(step:Int):Void {
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onStepHit", [step]);
        #end
    }

    public function beatHit(beat:Int):Void {
        // TODO: script calls??
        final canDance:Bool = danceInterval > 0 && (beat % danceInterval == 0);
        switch(curAnimContext) {
            case SING:
                if(holdTimer <= 0 && canDance && !_holdingPose)
                    dance();

            default:
                if(canDance)
                    dance();
        }
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onBeatHit", [beat]);
        #end
    }

    public function measureHit(measure:Int):Void {
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onMeasureHit", [measure]);
        #end
    }

    override function draw():Void {
		if(isFlippedOffsets()) {
			flipX = !flipX;
			scale.x *= -1;

			super.draw();

			flipX = !flipX;
			scale.x *= -1;
		}
        else
            super.draw();
	}

    override function destroy():Void {
        #if SCRIPTING_ALLOWED
        if(script != null) {
            script.call("onDestroy");
            script.close();
            script = null;
        }
        #end
        footOffset = FlxDestroyUtil.put(footOffset);
        super.destroy();
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private var _baseFlipped:Bool = false;

    @:noCompletion
    private var _holdingPose:Bool = false;
}