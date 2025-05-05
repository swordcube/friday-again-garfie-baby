package funkin.states;

#if SCRIPTING_ALLOWED
class ScriptedUIState extends UIState {
    public static var lastName:String = null;

    public function new(scriptName:String) {
        super();
        if(scriptName == null)
            scriptName = lastName;

        this.scriptName = scriptName;
        lastName = scriptName;
    }
}
#end