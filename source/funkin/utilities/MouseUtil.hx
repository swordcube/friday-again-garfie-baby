package funkin.utilities;

#if mobile
import flixel.input.touch.FlxTouch as Pointer;
typedef TouchSpecificData = {
    var lastX:Int;
    var lastY:Int;
};
#else
import flixel.input.mouse.FlxMouse as Pointer;
#end

// idk if this is the best way to do mobile support but oh well :D
class MouseUtil {
    #if mobile
    public static var touchData:Map<Pointer, TouchSpecificData> = [];
    #end

    public static function isJustPressed():Bool {
        #if mobile
        for(touch in FlxG.touches.list) {
            if(touch.justPressed)
                return true;
        }
        return false;
        #else
        return FlxG.mouse.justPressed;
        #end
    }

    public static function isPressed():Bool {
        #if mobile
        for(touch in FlxG.touches.list) {
            if(touch.pressed)
                return true;
        }
        return false;
        #else
        return FlxG.mouse.pressed;
        #end
    }

    public static function isJustReleased():Bool {
        #if mobile
        for(touch in FlxG.touches.list) {
            if(touch.justReleased)
                return true;
        }
        return false;
        #else
        return FlxG.mouse.justReleased;
        #end
    }

    public static function isJustPressedMiddle():Bool {
        #if mobile
        return false;
        #else
        return FlxG.mouse.justPressedMiddle;
        #end
    }

    public static function isPressedMiddle():Bool {
        #if mobile
        return false;
        #else
        return FlxG.mouse.pressedMiddle;
        #end
    }

    public static function isJustReleasedMiddle():Bool {
        #if mobile
        return false;
        #else
        return FlxG.mouse.justReleasedMiddle;
        #end
    }

    public static function isJustPressedRight():Bool {
        #if mobile
        return false;
        #else
        return FlxG.mouse.justPressedRight;
        #end
    }

    public static function isPressedRight():Bool {
        #if mobile
        return false;
        #else
        return FlxG.mouse.pressedRight;
        #end
    }

    public static function isJustReleasedRight():Bool {
        #if mobile
        return false;
        #else
        return FlxG.mouse.justReleasedRight;
        #end
    }

    public static function getWheel():Float {
        #if mobile
        return 0; // TODO: maybe utilize swiping here?
        #else
        return -FlxG.mouse.wheel;
        #end
    }

    public static function getPointer(?id:Int = 0):Pointer {
        #if mobile
        return FlxG.touches.list[id] ?? FlxG.touches.list.last();
        #else
        return FlxG.mouse;
        #end
    }

    public static function getDeltaX(?id:Int = 0):Int {
        #if mobile
        final pointer:Pointer = getPointer(id);
        if(touchData.get(pointer) == null)
            touchData.set(pointer, {lastX: pointer.x, lastY: pointer.y});
        
        final result:Int = pointer.x - touchData.get(pointer).lastX;
        touchData.get(pointer).lastX = pointer.x;
        return result;
        #else
        return FlxG.mouse.deltaX;
        #end
    }

    public static function getDeltaY(?id:Int = 0):Int {
        #if mobile
        final pointer:Pointer = getPointer(id);
        if(touchData.get(pointer) == null)
            touchData.set(pointer, {lastX: pointer.x, lastY: pointer.y});
        
        final result:Int = pointer.y - touchData.get(pointer).lastY;
        touchData.get(pointer).lastY = pointer.y;
        return result;
        #else
        return FlxG.mouse.deltaY;
        #end
    }

    public static function wasJustMoved(?id:Int = 0):Bool {
        #if mobile
        return getDeltaX(id) != 0 || getDeltaY(id) != 0;
        #else
        return FlxG.mouse.justMoved;
        #end
    }
}