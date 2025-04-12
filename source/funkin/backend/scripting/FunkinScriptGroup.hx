package funkin.backend.scripting;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.events.ScriptEvent;

@:access(funkin.backend.scripting.events.ScriptEvent)
class FunkinScriptGroup {
    public var parent:Dynamic;
    public var members(default, null):Array<FunkinScript>;

    public var additionalDefaults:Map<String, Dynamic> = [];
    public var publicVariables:Map<String, Dynamic> = [];

    public function new() {
        additionalDefaults.set("importScript", importScript);
        members = [];
    }

    public function importScript(path:String):Void {
        final script:FunkinScript = FunkinScript.fromFile(path);
        add(script);
        script.execute();
    }

    public function execute():Void {
        for(i in 0...members.length)
            members[i].execute();
    }

    public function get(name:String, ?defaultValue:Dynamic = null):Dynamic {
        var member:FunkinScript = null;
        var value:Dynamic = null;

        for(i in 0...members.length) {
            member = members[i];
            value = member.get(name);

            if(value != defaultValue)
                return value;
        }
        return defaultValue;
    }

    public function set(name:String, value:Dynamic):Void {
        for(i in 0...members.length)
            members[i].set(name, value);
    }

    public function setClass(value:Class<Dynamic>):Void {
        for(i in 0...members.length)
            members[i].setClass(value);
    }

    public function call(method:String, ?args:Array<Dynamic>, ?exclude:Array<FunkinScript>, ?defaultValue:Dynamic):Dynamic {
        var member:FunkinScript = null;
        var value:Dynamic = defaultValue;
        
        for(i in 0...members.length) {
            member = members[i];
            if(exclude != null && exclude.length != 0 && exclude.contains(member))
                continue;
            
            final ret:Dynamic = member.call(method, args);
            if(ret != null)
                value = ret;
        }
        if(value != defaultValue)
            return value;

        return defaultValue;
    }
    
    public function event<T:ScriptEvent>(method:String, event:T, ?exclude:Array<FunkinScript>):T {
        var member:FunkinScript = null;
        for(i in 0...members.length) {
            if(!event._canPropagate)
                break;

            member = members[i];
            if(exclude != null && exclude.length != 0 && exclude.contains(member))
                continue;

            member.call(method, [event]);
        }
        return event;
    }

    public function setParent(parent:Dynamic):Void {
        this.parent = parent;
        for(i in 0...members.length)
            members[i].setParent(parent);
    }

    public function close():Void {
        final members:Array<FunkinScript> = members.copy();
        for(i in 0...members.length)
            members[i].close();

        this.members.clear();
    }

    public function preAdd(script:FunkinScript):Void {
        script.setParent(parent);
        script.setPublicMap(publicVariables);
        script.onClose.add(() -> remove(script));

        for(k => v in additionalDefaults)
            script.set(k, v);
    }

    public function add(script:FunkinScript):Void {
        preAdd(script);
        members.push(script);
    }

    public function insert(index:Int, script:FunkinScript):Void {
        preAdd(script);
        members.insert(index, script);
    }

    public function remove(script:FunkinScript):Void {
        members.remove(script);
    }
}
#end