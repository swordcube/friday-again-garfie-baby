package funkin.states;

#if SCRIPTING_ALLOWED
class ScriptedState extends FunkinState {
    public static var lastName:String = null;

    public function new(scriptName:String, ?args:Array<Dynamic>) {
        if(scriptName == null)
            scriptName = lastName;
        
        this.scriptName = scriptName;
        lastName = scriptName;

        initArgs = args ?? [];
        super();
    }
}
#end