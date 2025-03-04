package funkin.ui.topbar;

import funkin.ui.dropdown.*;

enum TopBarItemType {
    Button(name:String, callback:Void->Void);
    DropDown(name:String, items:Array<DropDownItemType>);
    Slider(min:Float, max:Float, step:Float, value:Float, width:Float, ?callback:Float->Void);
    Text(contents:String);
}