package funkin.ui.options;

class ListOption extends Option {
    public var value:String;
    public var possibleValues:Array<String>;

    public var valueText:AtlasText;

    public function new(id:String, name:String, callback:Dynamic->Void, possibleValues:Array<String>) {
        super(id, '${name}:', callback);
        
        this.possibleValues = possibleValues;
        value = getValue();

        valueText = new AtlasText(100 + text.width + 34, -40, "default", LEFT, value);
        valueText.color = FlxColor.BLACK;
        add(valueText);
    } 

    override function handleInputs():Void {
        if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT) {
            final mult:Int = (controls.pressed.UI_LEFT) ? -1 : 1;
            final index:Int = FlxMath.boundInt(possibleValues.indexOf(value) + mult, 0, possibleValues.length - 1);

            value = possibleValues[index];
            valueText.text = value;
            setValue(value);
        }
    }
}