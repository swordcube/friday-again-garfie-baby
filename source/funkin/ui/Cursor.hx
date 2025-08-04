package funkin.ui;

class Cursor {
    public static var cursorTypes(default, null):Map<CursorType, CursorData>;
    public static var type(default, set):CursorType;

    public static function init():Void {
        cursorTypes = [
            DEFAULT => {
                path: Paths.image("ui/images/cursors/default"),
            },
            POINTER => {
                path: Paths.image("ui/images/cursors/pointer"),
                offsetX: -8
            },
            GRABBING => {
                path: Paths.image("ui/images/cursors/grabbing"),
                offsetX: -8
            },
            TEXT => {
                path: Paths.image("ui/images/cursors/text"),
            },
            ERASER => {
                path: Paths.image("ui/images/cursors/eraser"),
            },
            CELL => {
                path: Paths.image("ui/images/cursors/cell"),
                offsetX: -16,
                offsetY: -16
            }
        ];
        type = DEFAULT;

        FlxG.signals.preUpdate.add(() -> {
            switch(type) {
                case POINTER, GRABBING:
                    final prev:CursorType = type;    
                    if(TouchUtil.justPressed) {
                        @:bypassAccessor type = null;
                        type = GRABBING;
                        @:bypassAccessor type = prev;
                    }
                    else if(TouchUtil.justReleased) {
                        @:bypassAccessor type = null;
                        type = POINTER; 
                        @:bypassAccessor type = prev;
                    }

                default:
            }
        });
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private static function set_type(newType:CursorType):CursorType {
        if(type != newType) {
            #if (FLX_MOUSE && !mobile)
            final data:CursorData = cursorTypes.get(newType);
            FlxG.mouse.load(data.path, data.scale, data.offsetX, data.offsetY);
            #end
        }
        return type = newType;
    }
}

enum abstract CursorType(String) from String to String {
    final DEFAULT = "default";
    final POINTER = "pointer";
    final GRABBING = "grabbing";
    final TEXT = "text";
    final ERASER = "eraser";
    final CELL = "cell";
}

@:structInit
class CursorData {
    public var path:String;

    public var offsetX:Int = 0;
    public var offsetY:Int = 0;

    public var scale:Float = 1;
}