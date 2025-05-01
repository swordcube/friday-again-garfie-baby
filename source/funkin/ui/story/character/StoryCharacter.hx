package funkin.ui.story.character;

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

class StoryCharacter extends FlxSprite implements IBeatReceiver {
    public var data(default, null):StoryCharacterData;
    public var characterID(default, null):String;
    
    public var danceInterval:Int = 1;
    public var curDanceStep:Int = -1;

    public var holdTimer:Float = 0;
    public var footOffset:FlxPoint = FlxPoint.get(0, 0);

    public var canDance:Bool = true;

    #if SCRIPTING_ALLOWED
    public var scripts:FunkinScriptGroup;
    #end

    public function new(characterID:String) {
        super();
        if(characterID == null || characterID.length == 0)
            characterID = Constants.DEFAULT_CHARACTER;

        data = StoryCharacterData.load(characterID);
        characterID = data.id;
        this.characterID = characterID;

        #if SCRIPTING_ALLOWED
        scripts = new FunkinScriptGroup();
        scripts.setParent(this);

        @:privateAccess
        final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;
        for(i in 0...loaders.length) {
            final loader:AssetLoader = loaders[i];
            final contentMetadata:ContentMetadata = Paths.contentMetadata.get(loader.id);

            if(contentMetadata == null)
                continue;

            final scriptPath:String = Paths.script('gameplay/characters/${characterID}/script', loader.id, false);
            if(FlxG.assets.exists(scriptPath)) {
                final script:FunkinScript = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
                script.set("this", this);
                script.set("isCurrentPack", () -> return Paths.forceContentPack == loader.id);
                scripts.add(script);
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
        super.update(elapsed);
        #if SCRIPTING_ALLOWED
        scripts.call("onUpdatePost", [elapsed]);
        #end
    }

    public function applyData(data:StoryCharacterData):Void {
        switch(data.atlas.type) {
            case SPARROW:
                frames = Paths.getSparrowAtlas('menus/story/characters/${characterID}/${data.atlas.path}');
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
                loadGraphic(Paths.image('menus/story/characters/${characterID}/${data.atlas.path}'), true, gridSize[0] ?? 0, gridSize[1] ?? gridSize[0] ?? 0);

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
        
        dance();
        updateHitbox();
        
        footOffset.set(0, height);
        offset.set(footOffset.x - data.position[0], footOffset.y - data.position[1]);
    }

    public function dance():Void {
        #if SCRIPTING_ALLOWED
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        scripts.call("onDance", [event]);
        
        if(event.cancelled)
            return;
        #end
        if(data.danceSteps.length != 0) {
            curDanceStep = (curDanceStep + 1) % data.danceSteps.length;
            animation.play(data.danceSteps[curDanceStep]);
        } else {
            curDanceStep = 0;
            animation.play(data.danceSteps[curDanceStep]);
        }
        #if SCRIPTING_ALLOWED
        scripts.call("onDancePost", [event.flagAsPost()]);
        #end
    }

    public function stepHit(step:Int):Void {
        #if SCRIPTING_ALLOWED
        scripts.call("onStepHit", [step]);
        #end
    }

    public function beatHit(beat:Int):Void {
        @:privateAccess
        final danceAllowed:Bool = canDance && danceInterval > 0 && (Math.floor(Conductor.instance.curDecBeat - Conductor.instance._latestTimingPoint.beat) % danceInterval == 0);
        if(danceAllowed)
            dance();

        #if SCRIPTING_ALLOWED
        scripts.call("onBeatHit", [beat]);
        #end
    }

    public function measureHit(measure:Int):Void {
        #if SCRIPTING_ALLOWED
        scripts.call("onMeasureHit", [measure]);
        #end
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
}