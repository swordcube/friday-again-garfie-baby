package funkin.backend.macros;

import haxe.macro.*;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

using StringTools;

/**
 * A macro that makes every field in Options
 * correspond to your save data.
 * 
 * @author swordcube
 */
class OptionsMacro {
    public static function build() {
        #if macro
        var fields = Context.getBuildFields();
        var defaultValues:Map<String, Dynamic> = [];

        for (field in fields.copy()) {
            switch (field.kind) {
                case FVar(t, e):
                    // shortcut var to field.name
                    var cID:String = field.name;

                    // ignores any field with @:ignore
                    var canContinue:Bool = true;
					for (meta in field.meta.copy()) {
                        switch (meta.name) {
                            case ":ignore":
                                canContinue = false;
                                field.meta.push({name: ":dox", params: [macro hide], pos: Context.currentPos()});
                                field.meta.push({name: ":noCompletion", pos: Context.currentPos()});
                        }
					}

                    if(canContinue) {
                        // exprs
                        final defaultValue:Dynamic = (e != null) ? ExprTools.getValue(e) : null;
                        defaultValues.set(field.name, defaultValue);

                        final getterExpr = macro {
                            @:privateAccess {
                                if(Reflect.field(Options._save.data, $v{cID}) == null)
                                    Reflect.setField(Options._save.data, $v{cID}, $v{defaultValue});
                                    
                                return Reflect.field(Options._save.data, $v{cID});
                            }
                        }
                        final setterExpr = macro {
                            @:privateAccess
                            Reflect.setField(Options._save.data, $v{cID}, value);
                            return value;
                        }
                        
                        // funcs
                        final getterFunc:Function = {
                            ret: TPath({name: "Dynamic", params: [], pack: []}),
                            params: [],
                            expr: getterExpr,
                            args: []
                        };
                        final setterFunc:Function = {
                            ret: TPath({name: "Dynamic", params: [], pack: []}),
                            params: [],
                            expr: setterExpr,
                            args: [{name: "value", value: null}]
                        };
                        
                        // fields
                        final getterField:Field = {
                            name: "get_" + field.name,
                            access: [AStatic],
                            kind: FFun(getterFunc),
                            pos: Context.currentPos(),
                            doc: field.doc,
                            meta: field.meta.copy()
                        };
                        getterField.meta.push({name: ":dox", params: [macro hide], pos: Context.currentPos()});
                        getterField.meta.push({name: ":noCompletion", params: [], pos: Context.currentPos()});
    
                        final setterField:Field = {
                            name: "set_" + field.name,
                            access: [AStatic],
                            kind: FFun(setterFunc),
                            pos: Context.currentPos(),
                            doc: field.doc,
                            meta: field.meta.copy()
                        };
                        setterField.meta.push({name: ":dox", params: [macro hide], pos: Context.currentPos()});
                        setterField.meta.push({name: ":noCompletion", params: [], pos: Context.currentPos()});
    
                        final propertyField:Field = {
                            name: field.name,
                            meta: [{
                                name: ":isVar",
                                pos: Context.currentPos()
                            }],
                            access: [APublic, AStatic],
                            kind: FieldType.FProp("get", "set", getterFunc.ret),
                            pos: Context.currentPos(),
                            doc: field.doc
                        };
    
                        // fuck you old field!!!!
                        // we in the new generation of this shit!
                        fields.remove(field);
                        fields.push(propertyField);
    
                        // push getter/setter fields
                        fields.push(getterField);
                        fields.push(setterField);
                    }

                default:
            }
        }
        fields.push({
            name: "_defaultValues",
            access: [APrivate, AStatic],
            kind: FVar(macro:Map<String, Dynamic>, macro $v{defaultValues}),
            pos: Context.currentPos(),
            doc: null,
            meta: [
                {
                    name: ":ignore",
                    pos: Context.currentPos()
                },
                {
                    name: ":noDoc",
                    pos: Context.currentPos()
                }
            ]
        });
        return fields;
        #else
        return [];
        #end
    }
}
