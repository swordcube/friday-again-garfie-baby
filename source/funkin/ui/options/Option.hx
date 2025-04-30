package funkin.ui.options;

class Option extends FlxSpriteContainer {
    public var id:String;
    public var description:String;

    public var callback:Dynamic->Void;
    public var isGameplayModifier:Bool = false;

    public var text:AtlasText;
    public var controls(default, never):Controls = Controls.instance;

    public function new(id:String, name:String, description:String, callback:Dynamic->Void, isGameplayModifier:Bool) {
        super();
        this.id = id;
        this.description = description;
        this.callback = callback;
        this.isGameplayModifier = isGameplayModifier;

        text = new AtlasText(100, 0, "bold", LEFT, name);
        add(text);
    }

    public function getValue():Dynamic {
        if(isGameplayModifier)
            return Options.gameplayModifiers.get(id);

        return Reflect.getProperty(Options, id);
    }

    public function setValue(value:Dynamic):Void {
        if(isGameplayModifier)
            Options.gameplayModifiers.set(id, value);
        else
            Reflect.setProperty(Options, id, value);

        if(callback != null)
            callback(value);
    }

    /**
     * Handle inputs for this option by
     * overriding this function!
     */
    public function handleInputs():Void {}
}