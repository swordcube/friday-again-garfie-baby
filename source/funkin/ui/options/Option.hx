package funkin.ui.options;

class Option extends FlxSpriteContainer {
    public var id:String;
    public var description:String;

    public var callback:Dynamic->Option->Void;
    public var acceptCallback:Void->Void;

    public var isGameplayModifier:Bool = false;

    public var text:AtlasText;
    public var controls(default, never):Controls = Controls.instance;

    public function new(id:String, name:String, description:String, callback:Dynamic->Option->Void, isGameplayModifier:Bool) {
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

        final split:Array<String> = id.split("://");
        if(split.length > 1)
            return Options.customOptions.get(split[0]).get(split[1]);

        return Reflect.getProperty(Options, id);
    }

    public function setValue(value:Dynamic):Void {
        if(isGameplayModifier)
            Options.gameplayModifiers.set(id, value);
        else {
            final split:Array<String> = id.split("://");
            if(split.length > 1)
                Options.customOptions.get(split[0]).set(split[1], value);
            else
                Reflect.setProperty(Options, id, value);
        }
        if(callback != null)
            callback(value, this);

        if(updateValue != null)
            updateValue(value);
    }

    public dynamic function updateValue(value:Dynamic):Void {}

    /**
     * Handle inputs for this option by
     * overriding this function!
     */
    public function handleInputs():Void {
        if(controls.justPressed.ACCEPT && acceptCallback != null)
            acceptCallback();
    }
}