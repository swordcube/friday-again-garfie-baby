package funkin.substates;

import funkin.backend.ContentMetadata;
import funkin.backend.assets.loaders.AssetLoader;

import funkin.backend.Controls;
import funkin.backend.Conductor.IBeatReceiver;

#if SCRIPTING_ALLOWED
import funkin.scripting.FunkinScript;
import funkin.scripting.FunkinScriptGroup;
#end

class FunkinSubState extends FlxSubState implements IBeatReceiver {
    public var controls(get, never):Controls;
    public var subStateScripts(default, null):FunkinScriptGroup;

    override function create():Void {
        #if SCRIPTING_ALLOWED
        final fullClName:String = Type.getClassName(Type.getClass(this));
        final shortClName:String = fullClName.substring(fullClName.lastIndexOf(".") + 1);

        subStateScripts = new FunkinScriptGroup();
        subStateScripts.setParent(this);

        @:privateAccess
        final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;
        for(i in 0...loaders.length) {
            final loader:AssetLoader = loaders[i];
            final contentMetadata:ContentMetadata = Paths.contentMetadata.get(loader.id);

            if(contentMetadata != null && !contentMetadata.runGlobally && Paths.forceContentPack != loader.id)
                continue;

            final scriptPath:String = Paths.script('substates/${shortClName}', loader.id, false);
            if(FlxG.assets.exists(scriptPath)) {
                final script:FunkinScript = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
                script.set("this", this);
                script.set("isCurrentPack", () -> return Paths.forceContentPack == loader.id);
                subStateScripts.add(script);
            }
        }
        subStateScripts.execute();
        #end
        super.create();
        _callCreate();
    }

    override function createPost():Void {
        super.createPost();
        _callCreatePost();
    }

    override function tryUpdate(elapsed:Float):Void {
		if(persistentUpdate || subState == null) {
			call("onUpdatePre", [elapsed]);
			update(elapsed);
			call("onUpdatePost", [elapsed]);
		}
		if(_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}
		if(subState != null)
			subState.tryUpdate(elapsed);
	}

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        call("onUpdate", [elapsed]);
    }

    override function destroy():Void {
        call("onDestroy");
        #if SCRIPTING_ALLOWED
        subStateScripts.close();
        subStateScripts = null;
        #end
        super.destroy();
    }

    public function call(method:String, ?args:Array<Dynamic>):Void {
        #if SCRIPTING_ALLOWED
        subStateScripts.call(method, args);
        #end
    }

    public function stepHit(step:Int):Void {
        call("onStepHit", [step]);
    }
    
	public function beatHit(beat:Int):Void {
        call("onBeatHit", [beat]);
    }

	public function measureHit(measure:Int):Void {
        call("onMeasureHit", [measure]);
    }

    private function _callCreate():Void {
        call("onCreate");
    }

    private function _callCreatePost():Void {
        call("onCreatePost");
    }

    @:noCompletion
    private inline function get_controls():Controls {
        return Controls.instance;
    }
}