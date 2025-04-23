package funkin.ui.options;

class Option extends FlxSpriteContainer {
    public var id:String;
    public var description:String;
    public var callback:Dynamic->Void;

    public var text:AtlasText;
    public var controls(default, never):Controls = Controls.instance;

    public function new(id:String, name:String, description:String, callback:Dynamic->Void) {
        super();
        this.id = id;
        this.description = description;
        this.callback = callback;

        text = new AtlasText(100, 0, "bold", LEFT, name);
        add(text);
    }

    public function getValue():Dynamic {
        return Reflect.getProperty(Options, id);
    }

    public function setValue(value:Dynamic):Void {
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