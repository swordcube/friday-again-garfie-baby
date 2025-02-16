package funkin.utilities;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;

import flixel.util.FlxColor;

class OpenFLUtil {
    public static function setupTextField(textField:TextField, font:String, size:Int, color:FlxColor, autoSize:TextFieldAutoSize, text:String):Void {
        textField.defaultTextFormat = new TextFormat(font, size, color);
        textField.autoSize = autoSize;
        textField.text = text;
    }
}