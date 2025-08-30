package funkin.scripting;

#if HSCRIPT_ALLOWED
import haxe.io.Path;
import haxe.PosInfos;

import hscript.Interp;
import hscript.Expr;

import rulescript.Tools.getScriptProp;

import rulescript.RuleScript;
import rulescript.interps.RuleScriptInterp;
import rulescript.types.Property as RuleScriptProperty;

import rulescript.parsers.HxParser;
import rulescript.parsers.HxParser.HScriptParser;

import funkin.backend.macros.DefinesMacro;

// TODO: look into extending NeoInterp instead of normal RuleScriptInterp?

class FunkinHScript extends FunkinScript {
    public static function createInterp():RuleScriptInterp {
        return new FunkinInterp();
    }

    public function new(code:String, unsafe:Bool = false) {
        var filePath:String = null;
		var fileName:String = null;
		if(FlxG.assets.exists(code)) {
            filePath = code;
            fileName = Path.withoutDirectory(filePath);
            code = FlxG.assets.getText(filePath);
        }
        this.code = code;
        RuleScript.createInterp = createInterp;
		
        final parser:FunkinRuleScriptHxParser = new FunkinRuleScriptHxParser();
        parser.setParameters({
			allowJSON: true,
			allowMetadata: true,
			allowTypes: true,
			allowPackage: true,
			allowImport: unsafe,
			allowUsing: unsafe,
			allowStringInterpolation: true,
			allowTypePath: unsafe
		});
        _rscript = new RuleScript(null, parser);
        _rscript.variables.set("trace", Reflect.makeVarArgs((args:Array<Dynamic>) -> {
            final interp:RuleScriptInterp = cast _rscript.interp;
            final pos:PosInfos = interp.posInfos();
            if(pos != null)
                Logs.trace('${fileName}:${pos.lineNumber}: ${args.join(', ')}');
            else
                Logs.trace('${args.join(', ')}');
        }));
        _rscript.hasErrorHandler = true;
        
        final interp:FunkinInterp = cast _rscript.interp;
        interp.errorHandlerEx = (e:Error) -> {
            final fn:String = '${e.origin}:${e.line}: ';

            var err:String = e.toString();
            if(err.startsWith(fn))
                err = err.substr(fn.length);

            Logs.error('${fn}${err}');
        };
        interp.allowPublicVariables = interp.allowStaticVariables = true;
        interp.staticVariables = FunkinScript.staticVariables;
		set("staticVariables", FunkinScript.staticVariables);
        
        if(filePath != null) {
            set("parentContentPack", Paths.getContentPackFromPath(filePath));
            set("parentContentFolder", Paths.getContentFolderFromPath(filePath));
            set("parentContentFolderFull", Paths.getContentFolderFromPath(filePath, true));
        }
        super(code, unsafe);
		this.filePath = filePath;
		this.fileName = fileName;
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
		try {
			final parser = _rscript.getParser(FunkinRuleScriptHxParser).parser;
			parser.line = 1;

			final expr = parser.parseString(code, fileName ?? "hscript", 0);
			_rscript.execute(expr);
		} catch(e) {
			Logs.error('Error executing ${filePath}: ${e}');
		}
    }

    override function get(name:String):Dynamic {
        if(closed) return null;
        return _rscript.variables.get(name);
    }

    override function set(name:String, value:Dynamic):Void {
        if(closed) return;
        _rscript.variables.set(name, value);
    }

    override function setClass(value:Class<Dynamic>, ?as:String):Void {
        if(closed) return;
		if(as != null && as.length != 0)
			_rscript.variables.set(as, value);
		else {
			final cl:Array<String> = Type.getClassName(value).split('.');
			_rscript.variables.set(cl[cl.length - 1], value);
		}
    }

    override function call(method:String, ?args:Array<Dynamic>):Dynamic {
        if(closed) return null; // if script is closed BEFORE calling the func, do nothing

        var func:Dynamic = _rscript.variables.get(method);
        if(!Reflect.isFunction(func))
            return null;

        if(args == null || args.length == 0)
            args = [];
        
        var ret:Dynamic = Reflect.callMethod(null, func, args);
        if(closed) {// if the script was closed DURING a func call, wait till after the call to close it
            _rscript = null;
        }
        return ret;
    }

    override function setParent(parent:Dynamic):Void {
        if(closed) return;
        _rscript.superInstance = parent;
    }

    override function setPublicMap(map:Map<String, Dynamic>):Void {
        if(closed) return;
        final interp:FunkinInterp = cast _rscript.interp;
        interp.publicVariables = map;
		set("publicVariables", map);
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private var _rscript:RuleScript;
}

class FunkinInterp extends RuleScriptInterp {
    public var publicVariables:Map<String, Dynamic> = [];
    public var staticVariables:Map<String, Dynamic> = [];

    public var allowPublicVariables:Bool = false;
    public var allowStaticVariables:Bool = false;

    public dynamic function errorHandlerEx(e:Error):Void {}

    override function resetVariables():Void {
        publicVariables = [];
        staticVariables = [];
        super.resetVariables();
    }

    override function setVar(name:String, v:Dynamic):Void {
		if (allowStaticVariables && staticVariables.exists(name))
			staticVariables.set(name, v);
		else if (allowPublicVariables && publicVariables.exists(name))
			publicVariables.set(name, v);
		else
			super.setVar(name, v);
	}

	override function assign(e1:Expr, e2:Expr):Dynamic {
		var v = expr(e2);
		switch (hscript.Tools.expr(e1)) {
			case EIdent(id):
				var l = locals.get(id);
				if (l == null)
					setVar(id, v);
				else {
					if (l.r is RuleScriptProperty)
						cast(l.r, RuleScriptProperty).value = v;
					else {
						l.r = v;
						setVar(id, v);
					}
				}
			
			case EField(e, f):
				v = set(expr(e), f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
					setMapValue(arr, index, v);
				else
					arr[index] = v;

			default:
				error(EInvalidOp("="));
		}
		return v;
	}

	override function evalAssignOp(op,fop,e1,e2) : Dynamic {
		var v;
		switch( hscript.Tools.expr(e1) ) {
			case EIdent(id):
				var l = locals.get(id);
				v = fop(expr(e1),expr(e2));
				if( l == null )
					setVar(id,v)
				else {
					l.r = v;
					setVar(id,v);
				}
			case EField(e,f):
				var obj = expr(e);
				v = fop(get(obj,f),expr(e2));
				v = set(obj,f,v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				}
				else {
					v = fop(arr[index],expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}

	override function increment( e : Expr, prefix : Bool, delta : Int ) : Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch(e) {
			case EIdent(id):
				var l = locals.get(id);
				var v : Dynamic = (l == null) ? resolve(id) : l.r;
				if( prefix ) {
					v += delta;
					if( l == null ) setVar(id,v) else {
						l.r = v;
						setVar(id,v);
					}
				} else
					if( l == null ) setVar(id,v + delta) else {
						l.r = v + delta;
						setVar(id,v + delta);
					}
				return v;
			case EField(e,f):
				var obj = expr(e);
				var v : Dynamic = get(obj,f);
				if( prefix ) {
					v += delta;
					set(obj,f,v);
				} else
					set(obj,f,v + delta);
				return v;
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) {
					var v = getMapValue(arr, index);
					if (prefix) {
						v += delta;
						setMapValue(arr, index, v);
					}
					else {
						setMapValue(arr, index, v + delta);
					}
					return v;
				}
				else {
					var v = arr[index];
					if( prefix ) {
						v += delta;
						arr[index] = v;
					} else
						arr[index] = v + delta;
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0)?"++":"--"));
		}
	}

    override function expr(expr:Expr):Dynamic {
        #if hscriptPos
		curExpr = expr;
		var e:ExprDef = expr.e;
		#else
		var e:Expr = expr;
		#end
        switch(e) {
			case ETypeVarPath(path):
				var id:String = path[0];

				if (!locals.exists(id) && !variables.exists(id) && !staticVariables.exists(id) && !publicVariables.exists(id))
				{
					final typePath:String = path.join('.');

					if (typePaths.exists(typePath))
						return typePaths[typePath];
					else
					{
						final type:Dynamic = resolveType(typePath);
						if (type != null)
							return typePaths[typePath] = type;
						else
						{
							final field = typePath.substring(typePath.lastIndexOf('.') + 1);

							return typePaths[typePath] = get(resolveType(typePath.substring(0, typePath.lastIndexOf('.'))), field);
						}
					}
				}

				var obj:Dynamic = null;
				var l = locals.get(id);
				if (l != null)
					obj = getScriptProp(l.r);

				obj ??= resolve(id);

				var currentField:Int = 0;
				while (path[++currentField] != null)
					obj = get(obj, path[currentField]);

				return obj;
			
            case EVar(n, _, e, global, _, isPublic, isStatic):
				if (global) {
                    var shit = (e == null) ? null : this.expr(e);
                    if(isStatic == true) {
						if(!staticVariables.exists(n))
							staticVariables.set(n, shit);
						
						return null;
					}
					(isPublic ? publicVariables : variables).set(n, shit);
                }
				else {
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: (e == null) ? null : this.expr(e)});

					var shit = locals[n].r;
                    if(isStatic == true) {
						if(!staticVariables.exists(n))
							staticVariables.set(n, shit);
						
						return null;
					}
					if(isPublic == true)
						publicVariables.set(n, shit);
				}
				return null;

			case EProp(n, g, s, type, e, global, isPublic, isStatic):
				var prop = createScriptProperty(n, g, s, type);
				if (global) {
					if(isStatic == true) {
						if(!staticVariables.exists(n))
							staticVariables.set(n, prop);
						
						return null;
					}
					(isPublic ? publicVariables : variables).set(n, prop);
				}
				else {
					declared.push({n: n, old: locals.get(n)});
					locals.set(n, {r: prop});

					if(isStatic == true) {
						if(!staticVariables.exists(n))
							staticVariables.set(n, prop);
						
						return null;
					}
					if(isPublic == true)
						publicVariables.set(n, prop);
				}
				if (e != null)
					prop._lazyValue = () -> this.expr(e);

				return null;

			case EIdent(id):
				return resolve(id);

            case EFunction(params, fexpr, name, _, isPublic, isStatic):
				if (name == 'new')
					__constructor = expr;

				var capturedLocals = duplicate(locals);
				var me = this;
				var hasOpt:Bool = false, hasRest:Bool = false, minParams = 0;
				for (p in params)
				{
					if (p.t.match(CTPath(["haxe", "Rest"], _)))
					{
						if (params.indexOf(p) == params.length - 1)
							hasRest = true;
						else
							error(ECustom("Rest should only be used for the last function argument"));
					}

					if (p.opt)
						hasOpt = true;
					else
						minParams++;
				}

				var f = function(args:Array<Dynamic>)
				{
					if (((args == null) ? 0 : args.length) != params.length)
					{
						if (args.length < minParams && (!hasRest && args.length + 1 < minParams))
						{
							var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
							if (name != null)
								str += " for function '" + name + "'";
							error(ECustom(str));
						}
						// make sure mandatory args are forced
						var args2 = [];
						var extraParams = args.length - minParams;
						var pos = 0;
						for (p in params)
						{
							if (hasRest && p.t.match(CTPath(["haxe", "Rest"], _)))
								args2.push([for (i in pos...args.length) args[i]]);
							else
							{
								if (p.opt)
								{
									if (extraParams > 0)
									{
										args2.push(args[pos++]);
										extraParams--;
									}
									else
										args2.push(null);
								}
								else
									args2.push(args[pos++]);
							}
						}
						args = args2;
					}
					else if (hasRest)
						args.push([args.pop()]);

					var old = me.locals, depth = me.depth;
					me.depth++;
					me.locals = me.duplicate(capturedLocals);
					for (i in 0...params.length)
						me.locals.set(params[i].name, {r: args[i]});
					var r = null;
					var oldDecl = declared.length;
					if (inTry)
						try
						{
							r = me.exprReturn(fexpr);
						}
						catch (e:Dynamic)
						{
							restore(oldDecl);
							me.locals = old;
							me.depth = depth;
							#if neko
							neko.Lib.rethrow(e);
							#else
							throw e;
							#end
						}
					else
						r = me.exprReturn(fexpr);
					restore(oldDecl);
					me.locals = old;
					me.depth = depth;
					return r;
				};
				#if hl
				var f:Dynamic = switch (params.length)
				{
					case 0:
						() -> f([]);
					case 1:
						Tools.callMethod1.bind(f, _);
					case 2:
						Tools.callMethod2.bind(f, _, _);
					case 3:
						Tools.callMethod3.bind(f, _, _, _);
					case 4:
						Tools.callMethod4.bind(f, _, _, _, _);
					case 5, 6:
						Tools.callMethod6.bind(f, _, _, _, _, _, _);
					case 7, 8:
						Tools.callMethod8.bind(f, _, _, _, _, _, _, _, _);
					case 9, 10, 11, 12:
						Tools.callMethod12.bind(f, _, _, _, _, _, _, _, _, _, _, _, _);
					default:
						Reflect.makeVarArgs(f);
				}
				#else
				var f = Reflect.makeVarArgs(f);
				#end

				if (name != null)
				{
					if (depth == 0)
					{
						// global function
						if(isStatic && allowStaticVariables)
							staticVariables.set(name, f);
						else if(isPublic && allowPublicVariables)
							publicVariables.set(name, f);
						else
							variables.set(name, f);
					}
					else
					{
						// function-in-function is a local function
						declared.push({n: name, old: locals.get(name)});
						var ref = {r: f};
						locals.set(name, ref);
						capturedLocals.set(name, ref); // allow self-recursion
					}
				}
				return f;

            default:
        }
        return super.expr(expr);
    }

    override function exprReturn(e):Dynamic {
		if (!inTry && hasErrorHandler)
			try {
				try {
                    return expr(e);
                } catch (e:Stop) {
                    switch (e) {
                        case SBreak:
                            throw "Invalid break";
                        case SContinue:
                            throw "Invalid continue";
                        case SReturn:
                            var v = returnValue;
                            returnValue = null;
                            return v;
                    }
                } catch(e) {
                    error(ECustom('${e.toString()}'));
                    return null;
                }
			}
			catch (exception:hscript.Expr.Error) {
                errorHandlerEx(exception);
			}
            catch (e) {
                errorHandlerEx(new Error(ECustom('${e.toString()}'), 0, 0, "hscript", 0));
			}
		else
			return super.exprReturn(e);

		return null;
	}

    override function resolve(id:String):Dynamic {
		id = StringTools.trim(id);
		if (id == 'this')
			return this;

		if (id == 'super' && superInstance != null)
			return superInstance;

		if(staticVariables.exists(id))
			return staticVariables[id];
		
		if(publicVariables.exists(id))
			return publicVariables[id];

		var l:Dynamic = locals.get(id);
		if (l != null)
			return getScriptProp(l.r);
		
        var v:Dynamic = getScriptProp(variables.get(id));
		if (v == null && !variables.exists(id))
			v = Reflect.getProperty(superInstance, id) ?? error(EUnknownVariable(id));

		return v;
    }
}

class FunkinRuleScriptHxParser extends HxParser {
	public function new() {
		parser = new FunkinHScriptParser();
		super();
	}
}

class FunkinHScriptParser extends HScriptParser {
	var nextIsStatic:Bool = false;
	var nextIsPublic:Bool = false;

	public function new() {
		super();
		for (key => value in DefinesMacro.defines)
			preprocesorValues.set(key, value);
	}

	override function parseStructure(id:String) {
		#if hscriptPos
		var p1 = tokenMin;
		#end
		return switch(id) {
			case "static":
				nextIsStatic = true;
				var nextToken = token();
				switch(nextToken) {
					case TId("public"):
						var str = parseStructure("public"); // static public
						nextIsStatic = false;
						str;
					case TId("function"):
						var str = parseStructure("function"); // static function
						nextIsStatic = false;
						str;
					case TId("override"):
						var str = parseStructure("override"); // static override
						nextIsStatic = false;
						str;
					case TId("var"):
						var str = parseStructure("var"); // static var
						nextIsStatic = false;
						str;
					case TId("final"):
						var str = parseStructure("final"); // static final
						nextIsStatic = false;
						str;
					default:
						unexpected(nextToken);
						nextIsStatic = false;
						null;
				}
			case "public":
				nextIsPublic = true;
				var nextToken = token();
				switch(nextToken) {
					case TId("static"):
						var str = parseStructure("static"); // public static
						nextIsPublic = false;
						str;
					case TId("function"):
						var str = parseStructure("function"); // public function
						nextIsPublic = false;
						str;
					case TId("override"):
						var str = parseStructure("override"); // public override
						nextIsPublic = false;
						str;
					case TId("var"):
						var str = parseStructure("var"); // public var
						nextIsPublic = false;
						str;
					case TId("final"):
						var str = parseStructure("final"); // public final
						nextIsPublic = false;
						str;
					default:
						unexpected(nextToken);
						nextIsPublic = false;
						null;
				}
			case "var", "final":
				var ident = getIdent();

				var props:{get:String, set:String} = null;

				if (id == 'var' && maybe(TPOpen))
				{
					var list:Array<Expr> = parseExprList(TPClose);

					if (list.length != 2)
						list.length > 2 ? unexpected(TComma) : unexpected(TPClose);
					else
					{
						var get:String = switch (expr(list[0]))
						{
							case EIdent(id):
								id;
							case _:
								error(ECustom('Accessor should be ident'), tokenMin, tokenMax);
								null;
						}, set:String = switch (expr(list[1]))
							{
								case EIdent(id):
									id;
								case _:
									error(ECustom('Accessor should be ident'), tokenMin, tokenMax);
									null;
							}

						props = {get: get, set: set}
					}
				}

				var tk = token();
				var t = null;
				if (tk == TDoubleDot && allowTypes)
				{
					t = parseType();
					tk = token();
				}

				var e = null;
				if (Type.enumEq(tk, TOp("=")))
					e = parseExpr();
				else
					push(tk);

				if (props == null)
				{
					mk(EVar(ident, t, e, false, id == 'final', nextIsPublic, nextIsStatic), p1, (e == null) ? tokenMax : pmax(e));
				}
				else
				{
					mk(EProp(ident, props.get, props.set, t, e, null, nextIsPublic, nextIsStatic), p1, (e == null) ? tokenMax : pmax(e));
				}
			case "function":
				var tk = token();
				var name = null;
				switch( tk ) {
					case TId(id): name = id;
					default: push(tk);
				}
				var inf = parseFunctionDecl();
				mk(EFunction(inf.args, inf.body, name, inf.ret, nextIsPublic, nextIsStatic),p1,pmax(inf.body));
			default:
				super.parseStructure(id);
		}
	}
}
#elseif SCRIPTING_ALLOWED
class FunkinHScript extends FunkinScript {} // dummy class
#end