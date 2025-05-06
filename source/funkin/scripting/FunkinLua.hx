package funkin.scripting;

#if LUA_ALLOWED
import haxe.io.Path;
import llua.Lua;
import lscript.CustomConvert;
import lscript.LScript;

class FunkinLua extends FunkinScript {
    public function new(code:String, unsafe:Bool = false) {
        var filePath:String = null;
		var fileName:String = null;
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
            "FlxColor.fromRGB(" => "FlxColor:new():setRGB(",
            
            "FlxColor:fromRGBFloat(" => "FlxColor:new():setRGBFloat(",
            "FlxColor.fromRGBFloat(" => "FlxColor:new():setRGBFloat(",
            
            "FlxColor:fromHSV(" => "FlxColor:new():setHSV(",
            "FlxColor.fromHSV(" => "FlxColor:new():setHSV(",
            
            "FlxColor:fromHSB(" => "FlxColor:new():setHSB(",
            "FlxColor.fromHSB(" => "FlxColor:new():setHSB(",
            
            "FlxColor:fromCMYK(" => "FlxColor:new():setCMYK(",
            "FlxColor.fromCMYK(" => "FlxColor:new():setCMYK("
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
        _lua.print = (line:Int, s:String) -> {
            Logs.trace('${_lua.tracePrefix}:${line}: ${s}');
        };
        if(filePath != null) {
            set("parentContentPack", Paths.getContentPackFromPath(filePath));
            set("parentContentFolder", Paths.getContentFolderFromPath(filePath));
            set("parentContentFolderFull", Paths.getContentFolderFromPath(filePath, true));
        }
        super(code, unsafe);
        this.filePath = filePath;
        this.fileName = fileName;
    }

    override function execute():Void {
        if(closed) return;
        _lua.execute();
    }

    override function get(name:String):Dynamic {
        if(closed) return null;
        return _lua.getVar(name);
    }

    override function set(name:String, value:Dynamic):Void {
        if(closed) return;
        return _lua.setVar(name, value);
    }

    override function setClass(value:Class<Dynamic>):Void {
        if(closed) return;
        final cl:Array<String> = Type.getClassName(value).split('.');
        _lua.setVar(cl[cl.length - 1], value);
    }

    override function call(method:String, ?args:Array<Dynamic>):Dynamic {
        if(closed) return null; // if script is closed BEFORE calling the func, do nothing
        var ret:Dynamic = _lua.callFunc(method, args);

        if(closed) // if the script was closed DURING a func call, wait till after the call to close it
            Lua.close(_lua.luaState); // the one thing lscript doesn't have...
        
        return ret;
    }

    override function setParent(parent:Dynamic):Void {
        if(closed) return;
        _lua.parent = parent;
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private var _lua:LScript;
}
#elseif SCRIPTING_ALLOWED
class FunkinLua extends FunkinScript {} // dummy class
#end