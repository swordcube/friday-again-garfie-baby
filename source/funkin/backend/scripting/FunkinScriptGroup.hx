package funkin.backend.scripting;

#if SCRIPTING_ALLOWED
class FunkinScriptGroup {
    public var parent:Dynamic;
    public var members(default, null):Array<FunkinScript>;
    public var additionalDefaults:Map<String, Dynamic> = [];

    public function new() {
        members = [];
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

    public function call(method:String, ?args:Array<Dynamic>, ?defaultValue:Dynamic):Dynamic {
        var member:FunkinScript = null;
        var value:Dynamic = null;

        for(i in 0...members.length) {
            member = members[i];
            value = member.call(method, args);

            if(value != defaultValue)
                return value;
        }
        return defaultValue;
    }

    public function setParent(parent:Dynamic):Void {
        this.parent = parent;
        for(i in 0...members.length)
            members[i].setParent(parent);
    }

    public function close():Void {
        for(i in 0...members.length)
            members[i].close();

        members.clear();
    }

    public function preAdd(script:FunkinScript):Void {
        script.setParent(parent);
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