package funkin.ui.dropdown;

import flixel.input.keyboard.FlxKey;

enum DropDownItemType {
    Button(name:String, ?shortcut:Array<Array<FlxKey>>, callback:Void->Void);
    Checkbox(name:String, callback:Bool->Void, ?valueFactory:Void->Bool);
    Separator;
}