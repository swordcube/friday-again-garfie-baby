package funkin.backend.scripting;

#if SCRIPTING_ALLOWED
import haxe.io.Path;
import haxe.PosInfos;

import hscript.Interp;
import hscript.Parser;

import hscript.Expr;
import hscript.Expr.Error;

class FunkinHScript extends FunkinScript {
    public function new(code:String, unsafe:Bool = false) {
        if(FlxG.assets.exists(code)) {
            filePath = code;
            fileName = Path.withoutDirectory(filePath);
            code = FlxG.assets.getText(filePath);
        }
        this.code = code;

        _parser = new Parser();
        _parser.allowJSON = _parser.allowMetadata = _parser.allowTypes = true;
        try {
            _expr = _parser.parseString(code, fileName);
        }
        catch(error:Error) {
            var fileName = error.origin;
            var fn:String = '$fileName:${error.line}: ';

            var err:String = error.toString();
            if(err.startsWith(fn))
                err = err.substr(fn.length);

            Logs.error('${fn}${err}');
            _expr = _parser.parseString("var a = 0;", fileName);
        }
        catch(e) {
            Logs.error('Failed to parse ${fileName}: ${e}');
            _expr = _parser.parseString("var a = 0;", fileName);
        }
        _interp = new Interp();
        _interp.variables.set("trace", Reflect.makeVarArgs((args:Array<Dynamic>) -> {
            final pos:PosInfos = _interp.posInfos();
            if(pos != null)
                Logs.trace('${pos.fileName}:${pos.lineNumber}: ${args.join(', ')}');
            else
                Logs.trace('${args.join(', ')}');
        }));
        _interp.importEnabled = unsafe;
        _interp.errorHandler = (error:Error, ?pos:Null<PosInfos>) -> {
            var fileName = error.origin;
            var fn:String = '$fileName:${error.line}: ';

            var err:String = error.toString();
            if(err.startsWith(fn))
                err = err.substr(fn.length);

            Logs.error('${fn}${err}');
        };
        super(code, unsafe);
    }

    override function preset():Void {
        setClass(Std);
        setClass(Math);
        setClass(Array);
        
        setClass(String);
        setClass(StringTools);
        
        set("Int", Int);
        set("Float", Float);
        set("Bool", Bool);

        super.preset();
    }

    override function execute():Void {
        if(closed) return;
        _interp.execute(_expr);
    }

    override function get(name:String):Dynamic {
        if(closed) return null;
        return _interp.variables.get(name);
    }

    override function set(name:String, value:Dynamic):Void {
        if(closed) return;
        _interp.variables.set(name, value);
    }

    override function setClass(value:Class<Dynamic>):Void {
        if(closed) return;
        final cl:Array<String> = Type.getClassName(value).split('.');
        _interp.variables.set(cl[cl.length - 1], value);
    }

    override function call(method:String, ?args:Array<Dynamic>):Dynamic {
        if(closed) return null; // if script is closed BEFORE calling the func, do nothing

        var func:Dynamic = _interp.variables.get(method);
        if(!Reflect.isFunction(func))
            return null;

        var ret:Dynamic = Reflect.callMethod(null, func, args);
        if(closed) {// if the script was closed DURING a func call, wait till after the call to close it
            _interp = null;
            _parser = null;
            _expr = null;
        }
        return ret;
    }

    override function setParent(parent:Dynamic):Void {
        if(closed) return;
        _interp.scriptObject = parent;
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private var _interp:Interp;

    @:unreflective
    private var _parser:Parser;

    @:unreflective
    private var _expr:Expr;
}
#end