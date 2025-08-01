package funkin.ui.options;

class NumberOption extends Option {
    public var value:Float = 0;
    public var isInteger:Bool = false;

    public var min:Float;
    public var max:Float;

    public var step:Float;
    public var decimals:Int;

    public var valueText:AtlasText;
    public var holdTimer:Float = 0;

    public function new(id:String, name:String, description:String, callback:Dynamic->Option->Void, isGameplayModifier:Bool, ?isInteger:Bool) {
        super(id, '${name}:', description, callback, isGameplayModifier);
        
        this.isInteger = isInteger;
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
        if(controls.pressed.UI_LEFT || controls.pressed.UI_RIGHT)
            holdTimer += FlxG.elapsed;
        else
            holdTimer = 0;

        if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT)
            FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
        
        if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT || holdTimer >= 0.5) {
            if(decimals == 0 || isInteger) {
                value = FlxMath.bound(Std.int(value + ((controls.pressed.UI_LEFT) ? -step : step)), min, max);
                setValue(Std.int(value));
            } else {
                value = FlxMath.bound(FlxMath.roundDecimal(value + ((controls.pressed.UI_LEFT) ? -step : step), decimals), min, max);
                setValue(value);
            }
            if(holdTimer >= 0.5)
                holdTimer = 0.45;
        }
        super.handleInputs();
    }
}