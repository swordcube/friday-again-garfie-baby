package funkin.ui.topbar;

import funkin.ui.dropdown.*;

enum TopBarItemType {
    Button(name:String, callback:Void->Void);
    DropDown(name:String, items:Array<DropDownItemType>);
    Slider(name:String, min:Float, max:Float, step:Float);
    Text(contents:String);
}