package funkin.gameplay.character;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import funkin.backend.ContentMetadata;
import funkin.backend.assets.loaders.AssetLoader;

import funkin.graphics.AtlasType;
import funkin.graphics.AttachedSprite;
import funkin.graphics.SkinnableSprite;

import funkin.states.PlayState;
import funkin.utilities.SpriteUtil;

#if SCRIPTING_ALLOWED
import funkin.backend.events.Events;
import funkin.backend.events.ActionEvent;

import funkin.scripting.FunkinScript;
#end

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
class Character extends AttachedSprite implements IBeatReceiver {
    public var game:PlayState = PlayState.instance;

    public var data(default, null):CharacterData;
    public var debugMode:Bool = false;

    public var characterID(default, null):String;
    public var isPlayer(default, set):Bool = false;
    
    public var danceInterval:Int = 1;
    public var curDanceStep:Int = -1;

    public var holdTimer:Float = 0;
    public var curAnimContext:AnimationContext = DANCE;

    public var healthColor:Null<FlxColor> = null;
    public var footOffset:FlxPoint = FlxPoint.get(0, 0);

    public var canDance:Bool = true;
    public var holdingPose:Bool = false;

    #if SCRIPTING_ALLOWED
    public var script:FunkinScript;
    #end

    public function new(characterID:String, ?isPlayer:Bool = false, ?debugMode:Bool = false) {
        super();
        if(characterID == null || characterID.length == 0)
            characterID = Constants.DEFAULT_CHARACTER;

        data = CharacterData.load(characterID);
        characterID = data.id;
        
        this.characterID = characterID;
        @:bypassAccessor this.isPlayer = isPlayer;
        this.debugMode = debugMode;

        #if SCRIPTING_ALLOWED
        if(game == null || (game != null && game.scriptsAllowed)) {
            if(!debugMode) {
                final scriptPath:String = Paths.script('gameplay/characters/${characterID}/script');
                if(FlxG.assets.exists(scriptPath)) {
                    final contentPack:String = Paths.getContentPackFromPath(scriptPath);
                    final contentMetadata:ContentMetadata = Paths.contentMetadata.get(contentPack);

                    script = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
                    script.setParent(this);
                    script.set("isCurrentPack", () -> return Paths.forceContentPack == contentPack);

                    _initializedScript = true;
                }
            }
            if(_initializedScript && game != null && game.scriptsAllowed && game.scripts != null) {
                game.scripts.add(script);
                script.setParent(this);
            }
            if(_initializedScript) {
                script.execute();
                script.call("onLoad", [data]);
            }
        }
        #end
        applyData(data);

        #if SCRIPTING_ALLOWED
        if(_initializedScript && (game == null || (game != null && game.scriptsAllowed)))
            script.call("onLoadPost", [data]);
        #end
    }

    override function update(elapsed:Float):Void {
        #if SCRIPTING_ALLOWED
        if(_initializedScript && game == null)
            script.call("onUpdate", [elapsed]);
        #end
        if(!debugMode && curAnimContext == SING) {
            holdTimer -= elapsed * 1000;
            if(holdTimer <= 0)
                holdTimer = 0;
        }
        if(!debugMode && animation.finished && animation.exists('${animation.name}-loop'))
            playAnim('${animation.name}-loop', curAnimContext);

        if(holdingPose && holdTimer <= 0 && (game == null || !game.playField.strumsPressed.contains(true)))
            holdingPose = false;

        super.update(elapsed);

        #if SCRIPTING_ALLOWED
        if(_initializedScript && game == null)
            script.call("onUpdatePost", [elapsed]);
        #end
    }

    override function kill():Void {
        super.kill();
        #if SCRIPTING_ALLOWED
        if(_initializedScript && (game == null || (game != null && game.scriptsAllowed)))
            script.call("onKill");
        #end
    }

    override function revive():Void {
        super.revive();
        #if SCRIPTING_ALLOWED
        if(_initializedScript && (game == null || (game != null && game.scriptsAllowed)))
            script.call("onRevive");
        #end
    }

    public function applyData(data:CharacterData):Void {
        switch(data.atlas.type) {
            case SPARROW:
                frames = Paths.getSparrowAtlas('gameplay/characters/${characterID}/${data.atlas.path}');
                for(name in data.animations.keys()) {
                    final data:AnimationData = data.animations.get(name);
                    if(data.indices != null && data.indices.length != 0)
                        animation.addByIndices(name, data.prefix, data.indices, "", data.fps, data.looped);
                    else
                        animation.addByPrefix(name, data.prefix, data.fps, data.looped);
                    
                    animation.setOffset(name, data.offset[0] ?? 0.0, data.offset[1] ?? data.offset[0] ?? 0.0);
                }

            case GRID:
                final gridSize:Array<Int> = data.atlas.gridSize;
                loadGraphic(Paths.image('gameplay/characters/${characterID}/${data.atlas.path}'), true, gridSize[0] ?? 0, gridSize[1] ?? gridSize[0] ?? 0);

                for(name in Reflect.fields(data.animations)) {
                    final data:AnimationData = Reflect.field(data.animations, name);
                    animation.add(name, data.indices, data.fps, data.looped);
                    animation.setOffset(name, data.offset[0] ?? 0.0, data.offset[1] ?? data.offset[0] ?? 0.0);
                }

            case ANIMATE:
                // TODO: that shit

            default:
        }
        flipX = data.flipX;
        flipY = data.flipY;

        scale.set(data.scale, data.scale);
        antialiasing = data.antialiasing ?? FlxSprite.defaultAntialiasing;

        final color:String = data.healthIcon?.color;
        healthColor = (color != null && color.length != 0) ? FlxColor.fromString(color) : null;

        if(!debugMode)
            correctAnimations();
        
        dance();
        updateHitbox();
        
        footOffset.set(0, height * 0.5);
        offset.set(footOffset.x - data.position[0], footOffset.y - data.position[1]);
    }

    public function correctAnimations():Void {
        if(isPlayer != data.isPlayer)
            swapLeftRightAnimations();

        if(isPlayer)
            flipX = !flipX;

		_baseFlipped = flipX;
    }

    public function swapLeftRightAnimations():Void {
        SpriteUtil.switchAnimFrames(animation.getByName(data.singSteps.last()), animation.getByName(data.singSteps.first()));
		SpriteUtil.switchAnimOffset(animation.getByName(data.singSteps.first()), animation.getByName(data.singSteps.last()));
        
        if(!animation.exists(data.missSteps.first()) || !animation.exists(data.missSteps.last()))
            return;

		SpriteUtil.switchAnimFrames(animation.getByName(data.missSteps.last()), animation.getByName(data.missSteps.first()));
		SpriteUtil.switchAnimOffset(animation.getByName(data.missSteps.first()), animation.getByName(data.missSteps.last()));
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
        offset.set(footOffset.x - data.position[0] ?? 0.0, footOffset.y - data.position[1] ?? 0.0);
        
        #if SCRIPTING_ALLOWED
        if(_initializedScript && (game == null || (game != null && game.scriptsAllowed)))
            script.call("onPlayAnim", [name, context, force, reversed, frame]);
        #end
    }

    public inline function playSingAnim(direction:Int, ?suffix:String, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0):Void {
        var anim:String = data.singSteps[direction % data.singSteps.length];
        if(suffix != null && suffix.length != 0)
            anim += suffix;
        
        playAnim(anim, SING, force, reversed, frame);
    }

    public inline function playMissAnim(direction:Int, ?suffix:String, ?force:Bool = false, ?reversed:Bool = false, ?frame:Int = 0):Void {
        var anim:String = data.missSteps[direction % data.missSteps.length];
        if(suffix != null && suffix.length != 0)
            anim += suffix;

        playAnim(anim, SING, force, reversed, frame);
    }

    public function dance():Void {
        #if SCRIPTING_ALLOWED
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        if(_initializedScript && (game == null || (game != null && game.scriptsAllowed)))
            script.call("onDance", [event]);
        
        if(event.cancelled)
            return;
        #end
        if(data.danceSteps.length != 0) {
            curDanceStep = (curDanceStep + 1) % data.danceSteps.length;
            playAnim(data.danceSteps[curDanceStep], DANCE);
        } else {
            curDanceStep = 0;
            playAnim(data.danceSteps[curDanceStep], DANCE);
        }
        #if SCRIPTING_ALLOWED
        if(_initializedScript && (game == null || (game != null && game.scriptsAllowed)))
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
            (midpoint.x + (isPlayer ? -100 : 150) + (data.position[0] ?? 0.0) + (data.camera[0] ?? 0.0)) - footOffset.x,
			midpoint.y - (100 + footOffset.y) + (data.position[1] ?? 0.0) + (data.camera[1] ?? 0.0)
        );
		midpoint.put();
		return camPos;
	}

    public function stepHit(step:Int):Void {
        #if SCRIPTING_ALLOWED
        if(_initializedScript && game == null)
            script.call("onStepHit", [step]);
        #end
    }

    public function beatHit(beat:Int):Void {
        if(!debugMode) {
            @:privateAccess
            final danceAllowed:Bool = canDance && danceInterval > 0 && (Math.floor(Conductor.instance.curDecBeat - Conductor.instance._latestTimingPoint.beat) % danceInterval == 0);
            switch(curAnimContext) {
                case SING:
                    if(holdTimer <= 0 && danceAllowed && !holdingPose)
                        dance();
    
                default:
                    if(danceAllowed)
                        dance();
            }
        }
        #if SCRIPTING_ALLOWED
        if(_initializedScript && game == null)
            script.call("onBeatHit", [beat]);
        #end
    }

    public function measureHit(measure:Int):Void {
        #if SCRIPTING_ALLOWED
        if(_initializedScript && game == null)
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
        if(_initializedScript && game == null) {
            script.call("onDestroy");
            script.close();
        }
        script = null;
        #end
        footOffset = FlxDestroyUtil.put(footOffset);
        super.destroy();
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private var _baseFlipped:Bool = false;

    @:noCompletion
    private var _initializedScript:Bool = false;

    @:noCompletion
    private function set_isPlayer(value:Bool):Bool {
        isPlayer = value;
        correctAnimations();
        return value;
    }
}