package funkin.ui.dropdown;

class DropDownCheckboxItem extends DropDownItem {
    public function new(x:Float = 0, y:Float = 0, text:String, callback:Void->Void, value:Bool) {
        super(x, y, text, null, callback);

        icon.loadGraphic(Paths.image("ui/images/dropdown_checkbox"));
        icon.visible = value;
    }
}