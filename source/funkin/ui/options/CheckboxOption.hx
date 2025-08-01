package funkin.ui.options;

import flixel.effects.FlxFlicker;

class CheckboxOption extends Option {
    public var checkbox:Checkbox;

    public function new(id:String, name:String, description:String, callback:Dynamic->Option->Void, isGameplayModifier:Bool) {
        super(id, name, description, callback, isGameplayModifier);

        checkbox = new Checkbox(10, 0);
        add(checkbox);

        updateValue = (value:Dynamic) -> {
            final checked:Bool = cast value;
            if(checked)
                checkbox.select();
            else
                checkbox.unselect();
        };
        updateValue(getValue());
        checkbox.animation.finish();
    }

    override function handleInputs():Void {
        if(controls.justPressed.ACCEPT) {
            final checked:Bool = cast getValue();
            setValue(!checked);
            FlxG.sound.play(Paths.sound("menus/sfx/select"));
        }
        super.handleInputs();
    }
}