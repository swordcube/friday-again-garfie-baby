package funkin.backend.macros;

import haxe.macro.*;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/**
 * A macro that adds a `reset()` function to any class, which
 * resets all of it's variables to the values they were assigned
 * during variable initialization.
 * 
 * Example:
 * ```haxe
 * // hello is set to 64 by default
 * var myInstance:MyClass = new MyClass();
 * myInstance.hello = 3;
 * trace("hello: " + myInstance.hello); // Main.hx:4: hello: 3
 * 
 * myInstance.reset(); // reset gets called
 * trace("hello: " + myInstance.hello); // Main.hx:7: hello: 64
 * ```
 */
class ResettableClassMacro {
    public static function build():Array<Field> {
        #if macro
		var fields:Array<Field> = Context.getBuildFields();
        var defaultValues:Map<String, Dynamic> = [];

        var func:Function = {
			args: [],
			expr: {
				pos: Context.currentPos(),
				expr: EBlock([])
			}
		};
        for(field in fields.copy()) {
            // shortcut var to field.name
            var cID:String = field.name;

            // ignores any field with @:ignoreReset
            var canContinue:Bool = true;
            for (meta in field.meta) {
                switch (meta.name) {
                    case ":ignoreReset":
                        canContinue = false;
                }
            }
            if(canContinue) {
                switch(field.kind) {
                    case FVar(t, e):
                        var cValue:Dynamic = ExprTools.getValue(e);
                        switch(func.expr.expr) {
                            case EBlock(exprs):
                                exprs.push(macro {
                                    // trace("Resetting " + $v{cID} + " to " + $v{cValue} + " [FVar]");
                                    this.$cID = $v{cValue};
                                });

                            default:
                        }
                        
                    case FProp(getter, setter, t, e):
                        var cValue:Dynamic = ExprTools.getValue(e);
                        switch(func.expr.expr) {
                            case EBlock(exprs):
                                exprs.push(macro {
                                    // trace("Resetting " + $v{cID} + " to " + $v{cValue} + " [FProp]");
                                    this.$cID = $v{cValue};
                                });

                            default:
                        }

                    default:
                }
            }
        }
        switch(func.expr.expr) {
            case EBlock(exprs):
                exprs.insert(0, macro resetBase());

            default:
        }
        var funcField:Field = {
			pos: Context.currentPos(),
			name: "reset",
			kind: FFun(func),
            doc: "Resets all of the values of this instance.",
			access: [APublic]
		};
        fields.push(funcField);
        return fields;
        #else
        return [];
        #end
    }
}