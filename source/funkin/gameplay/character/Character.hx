package funkin.gameplay.character;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import funkin.backend.ContentMetadata;
import funkin.backend.assets.loaders.AssetLoader;

import funkin.graphics.AtlasType;
import funkin.graphics.SkinnableSprite;

import funkin.utilities.SpriteUtil;

#if SCRIPTING_ALLOWED
import funkin.backend.events.Events;
import funkin.backend.events.ActionEvent;

import funkin.scripting.FunkinScript;
import funkin.scripting.FunkinScriptGroup;
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
class Character extends FlxSprite implements IBeatReceiver {
    public var data(default, null):CharacterData;
    public var debugMode:Bool = false;

    public var characterID(default, null):String;
    public var isPlayer(default, set):Bool = false;
    
    public var danceInterval:Int = 1;
    public var curDanceStep:Int = -1;

    public var holdTimer:Float = 0;
    public var curAnimContext:AnimationContext = DANCE;

    public var healthColor:FlxColor = FlxColor.WHITE;
    public var footOffset:FlxPoint = FlxPoint.get(0, 0);

    #if SCRIPTING_ALLOWED
    public var scripts:FunkinScriptGroup;
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
        scripts = new FunkinScriptGroup();
        scripts.setParent(this);

        if(!debugMode) {
            @:privateAccess
            final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;
            for(i in 0...loaders.length) {
                final loader:AssetLoader = loaders[i];
                final contentMetadata:ContentMetadata = Paths.contentMetadata.get(loader.id);

                if(contentMetadata != null && !contentMetadata.runGlobally && Paths.forceContentPack != loader.id)
                    continue;

                final scriptPath:String = Paths.script('gameplay/characters/${characterID}/script', loader.id, false);
                if(FlxG.assets.exists(scriptPath)) {
                    final script:FunkinScript = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
                    script.set("this", this);
                    script.set("isCurrentPack", () -> return Paths.forceContentPack == loader.id);
                    scripts.add(script);
                }
            }
        }
        scripts.execute();
        scripts.call("onLoad", [data]);
        #end
        applyData(data);

        #if SCRIPTING_ALLOWED
        scripts.call("onLoadPost", [data]);
        #end
    }

    override function update(elapsed:Float):Void {
        #if SCRIPTING_ALLOWED
        scripts.call("onUpdate", [elapsed]);
        #end
        if(!debugMode && curAnimContext == SING) {
            holdTimer -= elapsed * 1000;
            if(holdTimer <= 0)
                holdTimer = 0;
        }
        super.update(elapsed);

        #if SCRIPTING_ALLOWED
        scripts.call("onUpdatePost", [elapsed]);
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
        flipX = data.flip[0];
        flipY = data.flip[1];

        scale.set(data.scale, data.scale);
        antialiasing = data.antialiasing ?? FlxSprite.defaultAntialiasing;

        healthColor = FlxColor.fromString(data.healthIcon?.color ?? "#FFFFFF");

        if(!debugMode)
            correctAnimations();
        
        dance();
        updateHitbox();
        
        footOffset.set(0, height);
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
        final event:ActionEvent = Events.get(UNKNOWN).flagAsPre();
        scripts.call("onDance", [event]);
        
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
        scripts.call("onDancePost", [event.flagAsPost()]);
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
        scripts.call("onStepHit", [step]);
        #end
    }

    public function beatHit(beat:Int):Void {
        if(!debugMode) {
            final canDance:Bool = danceInterval > 0 && (beat % danceInterval == 0);
            switch(curAnimContext) {
                case SING:
                    if(holdTimer <= 0 && canDance && !_holdingPose)
                        dance();
    
                default:
                    if(canDance)
                        dance();
            }
        }
        #if SCRIPTING_ALLOWED
        scripts.call("onBeatHit", [beat]);
        #end
    }

    public function measureHit(measure:Int):Void {
        #if SCRIPTING_ALLOWED
        scripts.call("onMeasureHit", [measure]);
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
        scripts.call("onDestroy");
        scripts.close();
        scripts = null;
        #end
        footOffset = FlxDestroyUtil.put(footOffset);
        super.destroy();
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private var _baseFlipped:Bool = false;

    @:noCompletion
    private var _holdingPose:Bool = false;

    @:noCompletion
    private function set_isPlayer(value:Bool):Bool {
        isPlayer = value;
        correctAnimations();
        return value;
    }
}