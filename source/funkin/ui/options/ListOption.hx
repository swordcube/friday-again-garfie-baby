package funkin.ui.options;

class ListOption extends Option {
    public var value:String;
    public var possibleValues:Array<String>;

    public var valueText:AtlasText;

    public function new(id:String, name:String, description:String, callback:Dynamic->Option->Void, isGameplayModifier:Bool, possibleValues:Array<String>) {
        super(id, '${name}:', description, callback, isGameplayModifier);
        
        this.possibleValues = possibleValues;
        value = getValue();

        valueText = new AtlasText(100 + text.width + 34, -40, "default", LEFT, "");
        valueText.color = FlxColor.BLACK;
        add(valueText);

        updateValue = (value:Dynamic) -> {
            valueText.text = Std.string(value);
        };
        updateValue(value);
    } 

    override function handleInputs():Void {
        if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT) {
            final mult:Int = (controls.pressed.UI_LEFT) ? -1 : 1;
            final index:Int = FlxMath.boundInt(possibleValues.indexOf(value) + mult, 0, possibleValues.length - 1);

            value = possibleValues[index];
            setValue(value);
        }
    }
}