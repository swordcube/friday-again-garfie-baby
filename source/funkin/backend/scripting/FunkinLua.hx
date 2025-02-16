package funkin.backend.scripting;

#if SCRIPTING_ALLOWED
import llua.Lua;
import haxe.io.Path;
import lscript.LScript;

class FunkinLua {
    public var code(default, null):String = null;
    public var filePath(default, null):String = null;
    public var fileName(default, null):String = null;
    public var unsafe(default, null):Bool = false;

    public function new(code:String, unsafe:Bool = false) {
        if(FlxG.assets.exists(code)) {
            filePath = code;
            fileName = Path.withoutDirectory(filePath);
            code = FlxG.assets.getText(filePath);
        }
        var workaroundMap:Map<String, String> = [
            // Really strange workaround for FlxColor from functions
            // returning the wrong colors
            // Everything else i tried didn't work :(
            "FlxColor:fromRGB(" => "FlxColor:new():setRGB(",
            "FlxColor:fromRGBFloat(" => "FlxColor:new():setRGBFloat(",
            "FlxColor:fromHSV(" => "FlxColor:new():setHSV(",
            "FlxColor:fromHSB(" => "FlxColor:new():setHSB(",
            "FlxColor:fromCMYK(" => "FlxColor:new():setCMYK("
        ];
        for(from => to in workaroundMap)
            code = code.replace(from, to);

        this.code = code;

        _lua = new LScript(code, unsafe);
        _lua.parseError = (err:String) -> {
            if(filePath != null)
                Logs.error('Failed to parse script at ${filePath}: ${err}');
            else
                Logs.error('Failed to parse script: ${err}');
        };
        _lua.functionError = (func:String, err:String) -> {
            if(filePath != null)
                Logs.error('Failed to call function "$func" at ${filePath}: ${err}');
            else
                Logs.error('Failed to call function "$func": ${err}');
        };
        _lua.tracePrefix = (filePath != null) ? fileName : 'FunkinLua';
        _lua.scriptTrace = (s:Dynamic) -> {
            Logs.trace('${_lua.tracePrefix}: ${s}');
        };
        preset();
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

        setClass(FlxState);
        setClass(FlxSubState);

        setClass(FlxTypedGroup);
        set("FlxGroup", FlxTypedGroup);
        setClass(FlxTypedSpriteGroup);
        set("FlxSpriteGroup", FlxTypedSpriteGroup);

        setClass(FlxMath);
        setClass(FlxEase);
        setClass(FlxTween);

        setClass(Paths);
        setClass(Cache);
        setClass(Logs);
        setClass(Options);
        setClass(Controls);
        setClass(Conductor);
        setClass(ModManager);
        setClass(Constants);

        set("BlendMode", funkin.backend.scripting.helpers.BlendModeHelper);
        set("FlxAxes", funkin.backend.scripting.helpers.FlxAxesHelper);
        set("FlxCameraFollowStyle", funkin.backend.scripting.helpers.FlxCameraFollowStyleHelper);
        set("FlxColor", funkin.backend.scripting.helpers.FlxColorHelper);
        set("FlxKey", funkin.backend.scripting.helpers.FlxKeyHelper);
        set("FlxTextAlign", funkin.backend.scripting.helpers.FlxTextAlignHelper);
        set("FlxTextBorderStyle", funkin.backend.scripting.helpers.FlxTextBorderStyleHelper);
        set("FlxTweenType", funkin.backend.scripting.helpers.FlxTweenTypeHelper);
    }

    public function execute():Void {
        _lua.execute();
    }

    public function get(name:String):Dynamic {
        return _lua.getVar(name);
    }

    public function set(name:String, value:Dynamic):Void {
        return _lua.setVar(name, value);
    }

    public function setClass(value:Class<Dynamic>):Void {
        final cl:Array<String> = Type.getClassName(value).split('.');
        _lua.setVar(cl[cl.length - 1], value);
    }

    public function call(method:String, ?args:Array<Dynamic>):Dynamic {
        return _lua.callFunc(method, args);
    }

    public function setParent(parent:Dynamic):Void {
        _lua.parent = parent;
    }

    public function close():Void {
        Lua.close(_lua.luaState); // the one thing lscript doesn't have...
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private var _lua:LScript;
}
#end