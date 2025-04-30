package funkin.ui.options;

class CheckboxOption extends Option {
    public var checkbox:Checkbox;

    public function new(id:String, name:String, description:String, callback:Dynamic->Void, isGameplayModifier:Bool) {
        super(id, name, description, callback, isGameplayModifier);

        checkbox = new Checkbox(10, 0);
        add(checkbox);

        final checked:Bool = cast getValue();
        if(checked)
            checkbox.select();
        else
            checkbox.unselect();

        checkbox.animation.finish();
    }

    override function handleInputs():Void {
        if(controls.justPressed.ACCEPT) {
            final checked:Bool = cast getValue();
            if(checked)
                checkbox.unselect();
            else
                checkbox.select();

            setValue(!checked);
        }
    }
}