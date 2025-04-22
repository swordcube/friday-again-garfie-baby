package funkin.ui.options;

class CheckboxOption extends Option {
    public var checkbox:Checkbox;

    public function new(id:String, name:String, callback:Dynamic->Void) {
        super(id, name, callback);

        checkbox = new Checkbox(10, 0);
        add(checkbox);

        final checked:Bool = Reflect.getProperty(Options, id);
        if(checked)
            checkbox.select();
        else
            checkbox.unselect();

        checkbox.animation.finish();
    }

    override function handleInputs():Void {
        if(controls.justPressed.ACCEPT) {
            final checked:Bool = !getValue();
            if(checked)
                checkbox.select();
            else
                checkbox.unselect();

            setValue(checked);
        }
    }
}