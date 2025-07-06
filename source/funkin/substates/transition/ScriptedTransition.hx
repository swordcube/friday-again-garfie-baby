package funkin.substates.transition;

#if SCRIPTING_ALLOWED
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

import funkin.backend.ContentMetadata;
import funkin.backend.assets.loaders.AssetLoader;

import funkin.scripting.FunkinScript;
import funkin.scripting.FunkinScriptGroup;

import funkin.graphics.GraphicCacheSprite;

import funkin.states.TransitionableState;
import funkin.states.TransitionableState.TransitionStatusString;

class ScriptedTransition extends TransitionSubState {
	public static var scriptName:String;

	public var graphicCache(default, null):GraphicCacheSprite;
    
	public var curStatus:TransitionStatusString;

    public var initArgs:Array<Dynamic>;
    public var subStateScripts(default, null):FunkinScriptGroup;

	public function new() {
		super();

		graphicCache = new GraphicCacheSprite();
        add(graphicCache);

        subStateScripts = new FunkinScriptGroup();
        subStateScripts.setParent(this);

        @:privateAccess
        final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;
        for(i in 0...loaders.length) {
            final loader:AssetLoader = loaders[i];
            final contentMetadata:ContentMetadata = Paths.contentMetadata.get(loader.id);

            final scriptPath:String = Paths.script('transitions/${scriptName}', loader.id, false);
            if(FlxG.assets.exists(scriptPath)) {
                final script:FunkinScript = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
                script.set("isCurrentPack", () -> return Paths.forceContentPack == loader.id);
                subStateScripts.add(script);
            }
        }
        subStateScripts.execute();
        subStateScripts.call("new", initArgs ?? []);
	}

	override function create():Void {
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

		if(FlxG.keys.pressed.SHIFT)
			finish();
    }

	override function draw():Void {
        call("onDraw", []);
        call("onDrawPre", []);
        super.draw();
        call("onDrawPost", []);
    }

    public function call(method:String, ?args:Array<Dynamic>):Void {
		if(subStateScripts == null) return;
        subStateScripts.call(method, args);
    }

    private function _callCreate():Void {
        call("onCreate");
    }

    private function _callCreatePost():Void {
        call("onCreatePost");
    }

	override function start(status:TransitionStatus):Void {
		var cam = (TransitionSubState.nextCamera != null) ? TransitionSubState.nextCamera : ((TransitionSubState.defaultCamera != null) ? TransitionSubState.defaultCamera : FlxG.cameras.list[FlxG.cameras.list.length - 1]);
		cameras = [cam];

		TransitionSubState.nextCamera = null;
		curStatus = status;

		switch(status) {
			case IN:
				// signal the game to use default transition (which is FadeTransition)
				// after this transition is finished

				// if you want to keep using the current transition
				// then you just call TransitionableState.setDefaultTransitions(ScriptedTransition);
				TransitionableState.resetDefaultTransitions();

				call("onStartIn");
				call("onInStart");

			case OUT:
				call("onStartOut");
				call("onOutStart");

			default:
		}
		call("onStart", [curStatus]);
		call("onStartTransition", [curStatus]);
		call("onTransitionStart", [curStatus]);
	}

    //----------- [ Private API ] -----------//

    private var _finalDelayTime:Float = 0.0;

	private function finish():Void {
		new FlxTimer().start(_finalDelayTime, onFinish); // force one last render call before exiting
	}

	private function onFinish(f:FlxTimer):Void {
		if(finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
		call("onFinish", [curStatus]);
	}

	override function destroy():Void {
        call("onDestroy");
        subStateScripts.close();
        subStateScripts = null;
        super.destroy();
    }
}
#end