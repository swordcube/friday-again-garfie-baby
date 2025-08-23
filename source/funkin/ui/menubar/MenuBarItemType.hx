package funkin.ui.menubar;

import funkin.ui.dropdown.*;

enum MenuBarItemType {
    Button(name:String, callback:Void->Void);
    DropDown(name:String, items:Array<DropDownItemType>);
    Slider(min:Float, max:Float, step:Float, value:Float, width:Float, ?callback:Float->Void, ?valueFactory:Void->Float);
    Text(contents:String);
    Textbox(contents:String, callback:String->Void, ?maxCharacters:Int, ?autoSize:Bool, ?width:Float, ?valueFactory:Void->String);
}