package funkin.scripting;

#if SCRIPTING_ALLOWED
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.backend.events.ActionEvent;

@:access(funkin.backend.events.ActionEvent)
class FunkinScriptGroup {
    public var parent:Dynamic;
    public var members(default, null):Array<FunkinScript>;

    public var additionalDefaults:Map<String, Dynamic> = [];
    public var publicVariables:Map<String, Dynamic> = [];

    public var onPreAdd:FlxTypedSignal<FunkinScript->Void> = new FlxTypedSignal<FunkinScript->Void>();
    public var onCall:FlxTypedSignal<String->Array<Dynamic>->Void> = new FlxTypedSignal<String->Array<Dynamic>->Void>();

    public function new() {
        additionalDefaults.set("importScript", importScript);
        members = [];
    }

    public function importScript(path:String):FunkinScript {
        final scriptPath:String = Paths.script(path);
        final contentMetadata = Paths.contentMetadata.get(Paths.getContentPackFromPath(scriptPath));
        final script:FunkinScript = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
        add(script);
        script.execute();
        return script;
    }

    public function execute():Void {
        for(i in 0...members.length) {
            if(members[i] != null)
                members[i].execute();
        }
    }

    public function get(name:String, ?defaultValue:Dynamic = null):Dynamic {
        var member:FunkinScript = null;
        var value:Dynamic = defaultValue;

        for(i in 0...members.length) {
            member = members[i];
            if(member == null)
                continue;
            
            final ret:Dynamic = member.get(name);
            if(ret != defaultValue)
                value = ret;
        }
        return value;
    }

    public function set(name:String, value:Dynamic):Void {
        var member:FunkinScript = null;
        for(i in 0...members.length) {  
            member = members[i];
            if(member == null)
                continue;

            member.set(name, value);
        }
    }

    public function setClass(value:Class<Dynamic>):Void {
        var member:FunkinScript = null;
        for(i in 0...members.length) {
            member = members[i];
            if(member == null)
                continue;

            members[i].setClass(value);
        }
    }

    public function call(method:String, ?args:Array<Dynamic>, ?exclude:Array<FunkinScript>, ?defaultValue:Dynamic):Dynamic {
        var member:FunkinScript = null;
        var value:Dynamic = defaultValue;
        
        for(i in 0...members.length) {
            member = members[i];
            if(member == null || (exclude != null && exclude.length != 0 && exclude.contains(member)))
                continue;
            
            final ret:Dynamic = member.call(method, args);
            if(ret != defaultValue)
                value = ret;
        }
        for(i in 0..._scriptsToClose.length)
            remove(_scriptsToClose[i]);

        _scriptsToClose.clear();
        onCall.dispatch(method, args ?? []);

        return value;
    }
    
    public function event<T:ActionEvent>(method:String, event:T, ?exclude:Array<FunkinScript>):T {
        var member:FunkinScript = null;
        for(i in 0...members.length) {
            if(!event._canPropagate)
                break;

            member = members[i];
            if(member == null || (exclude != null && exclude.length != 0 && exclude.contains(member)))
                continue;

            member.call(method, [event]);
        }
        for(i in 0..._scriptsToClose.length)
            remove(_scriptsToClose[i]);
        
        _scriptsToClose.clear();
        onCall.dispatch(method, [event]);

        return event;
    }

    public function setParent(parent:Dynamic):Void {
        this.parent = parent;
        
        for(i in 0...members.length)
            members[i].setParent(parent);
    }

    public function close():Void {
        final members:Array<FunkinScript> = members.copy();
        for(i in 0...members.length) {
            if(members[i] == null)
                continue;

            members[i].close();
        }
        this.members.clear();
    }

    public function preAdd(script:FunkinScript):Void {
        script.setParent(parent);
        script.setPublicMap(publicVariables);
        script.onClose.add(() -> {
            _scriptsToClose.push(script);
        });
        onPreAdd.dispatch(script);

        for(k => v in additionalDefaults)
            script.set(k, v);
    }

    public function add(script:FunkinScript):Void {
        if(script == null)
            return;

        preAdd(script);
        members.push(script);
    }

    public function insert(index:Int, script:FunkinScript):Void {
        if(script == null)
            return;

        preAdd(script);
        members.insert(index, script);
    }

    public function remove(script:FunkinScript):Void {
        if(script == null)
            return;
        
        members.remove(script);
    }

    private var _scriptsToClose:Array<FunkinScript> = [];
}
#end