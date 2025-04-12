package funkin.backend.scripting;

#if SCRIPTING_ALLOWED
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.states.PlayState;
import haxe.io.Path;

class FunkinScript {
    public static var staticVariables(default, null):Map<String, Dynamic> = [];

    public var code(default, null):String = null;
    public var filePath(default, null):String = null;
    public var fileName(default, null):String = null;
    public var unsafe(default, null):Bool = false;

    public var closed(default, null):Bool = false;
    public var onClose(default, null):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public function new(code:String, unsafe:Bool = false) {
        this.unsafe = unsafe;
        preset();
    }

    public static function fromFile(filePath:String, unsafe:Bool = false):FunkinScript {
        switch(Path.extension(filePath).toLowerCase()) {
            case "hx", "hxs", "hsc", "hscript":
                return new FunkinHScript(filePath, unsafe);

            case "lua":
                return new FunkinLua(filePath, unsafe);
        }
        return new FunkinScript(filePath, unsafe);
    }

    public function preset():Void {
        set("Json", {
            parse: Json.parse,
            stringify: Json.stringify
        });
        setClass(FlxG);

        setClass(FlxBasic);
        setClass(FlxObject);

        setClass(FlxSprite);
        setClass(FlxCamera);
        setClass(flixel.text.FlxText);

        setClass(FlxState);
        setClass(FlxSubState);

        setClass(FlxTypedGroup);
        set("FlxGroup", FlxTypedGroup);
        setClass(FlxTypedSpriteGroup);
        set("FlxSpriteGroup", FlxTypedSpriteGroup);

        setClass(FlxMath);
        setClass(FlxEase);
        setClass(FlxTween);
        setClass(flixel.util.FlxTimer);

        setClass(flixel.ui.FlxBar);
        setClass(flixel.addons.display.FlxBackdrop);
        setClass(flixel.addons.display.FlxTiledSprite);

        setClass(Paths);
        setClass(Cache);
        setClass(Logs);
        setClass(Options);
        
        setClass(Controls);
        set("Control", funkin.backend.Controls.Control);

        setClass(CoolUtil);
        setClass(Conductor);
        setClass(GlobalScript);
        setClass(Constants);
        setClass(WindowUtil); // this util only lets you change the title

        setClass(FunkinLua);
        setClass(FunkinHScript);

        setClass(funkin.gameplay.HealthIcon);
        setClass(funkin.gameplay.HoldTiledSprite);
        setClass(funkin.gameplay.PlayField);
        setClass(funkin.gameplay.UISkin);

        setClass(funkin.graphics.SkinnableSprite);
        setClass(funkin.graphics.TiledSprite);

        setClass(funkin.gameplay.hud.BaseHUD);

        setClass(funkin.gameplay.notes.Strum);
        setClass(funkin.gameplay.notes.StrumLine);

        setClass(funkin.gameplay.notes.Note);
        setClass(funkin.gameplay.notes.NoteSkin);
        setClass(funkin.gameplay.notes.NoteSpawner);

        setClass(funkin.gameplay.notes.HoldTail);
        setClass(funkin.gameplay.notes.HoldTrail);

        setClass(funkin.gameplay.song.ChartData);
        setClass(funkin.gameplay.song.VocalGroup);

        setClass(funkin.gameplay.character.Character);

        setClass(funkin.gameplay.scoring.Scoring);
        setClass(funkin.gameplay.scoring.ScoringSystem);

        setClass(funkin.gameplay.scoring.system.PBotSystem);
        setClass(funkin.gameplay.scoring.system.Judge4System);

        set("FlxRuntimeShader", funkin.graphics.shader.RuntimeShader);
        setClass(funkin.graphics.shader.RuntimeShader);
        setClass(funkin.graphics.shader.CustomShader);

        set("BlendMode", funkin.backend.scripting.helpers.BlendModeHelper);
        set("FlxAxes", funkin.backend.scripting.helpers.FlxAxesHelper);
        set("FlxCameraFollowStyle", funkin.backend.scripting.helpers.FlxCameraFollowStyleHelper);
        set("FlxColor", funkin.backend.scripting.helpers.FlxColorHelper);
        set("FlxKey", funkin.backend.scripting.helpers.FlxKeyHelper);
        set("FlxTextAlign", funkin.backend.scripting.helpers.FlxTextAlignHelper);
        set("FlxTextBorderStyle", funkin.backend.scripting.helpers.FlxTextBorderStyleHelper);
        set("FlxTweenType", funkin.backend.scripting.helpers.FlxTweenTypeHelper);
        set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection); // using a helper doesn't work, but using the enum directly does

        set("platform", Constants.CURRENT_OS);
        set("osName", Constants.CURRENT_OS);

        set("isDebugBuild", #if debug true #else false #end);
        set("isReleaseBuild", #if !debug true #else false #end);

        set("game", PlayState.instance);
        set("closeScript", close);
    }

    public function execute():Void {}

    public function get(name:String):Dynamic {
        return null;
    }

    public function set(name:String, value:Dynamic):Void {}

    public function setClass(value:Class<Dynamic>):Void {}

    public function call(method:String, ?args:Array<Dynamic>):Dynamic {
        return null;
    }

    public function setParent(parent:Dynamic):Void {}

    public function setPublicMap(map:Map<String, Dynamic>):Void {}

    public function close():Void {
        if(closed) return;
        onClose.dispatch();
        call("onClose");
        closed = true;
    }
}
#end