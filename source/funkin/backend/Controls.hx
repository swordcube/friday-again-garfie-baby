package funkin.backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

import flixel.addons.input.FlxControls;
import flixel.addons.input.FlxControlInputType;

enum Control {
    UI_LEFT;
    UI_DOWN;
    UI_UP;
    UI_RIGHT;

    ACCEPT;
    BACK;
    PAUSE;

    NOTE_LEFT;
    NOTE_DOWN;
    NOTE_UP;
    NOTE_RIGHT;

    FULLSCREEN;
    DEBUG;
    DEBUG_RELOAD;
}

class Controls extends FlxControls<Control> {
    public static var instance(default, null):Controls;
    public static final controlTypes:Array<Control> = Control.createAll();

    public var save:FlxSave;

    public static function init():Void {
        if(instance == null) {
            instance = new Controls();
            FlxG.inputs.addInput(instance);
        }
    }

    public function new() {
        super();

        save = new FlxSave();
        save.bind("controls", Constants.SAVE_DIR);

        var autoFlush:Bool = false;
        for(control => inputs in getDefaultMappings()) {
            final id:String = control.getName();
            if(Reflect.field(save.data, id) == null) {
                Reflect.setField(save.data, id, inputs);
                autoFlush = true;
            }
        }
        if(autoFlush)
            flush();

        resetMappings(getCurrentMappings());
        FlxG.stage.window.onClose.add(flush);
    }

    public function getDefaultMappings():ActionMap<Control> {
        return [
            UI_LEFT => [FlxKey.A, FlxKey.LEFT],
            UI_DOWN => [FlxKey.S, FlxKey.DOWN],
            UI_UP => [FlxKey.W, FlxKey.UP],
            UI_RIGHT => [FlxKey.D, FlxKey.RIGHT],

            ACCEPT => [FlxKey.ENTER, FlxKey.SPACE],
            BACK => [FlxKey.ESCAPE, FlxKey.BACKSPACE],
            PAUSE => [FlxKey.ENTER, FlxKey.ESCAPE],

            NOTE_LEFT => [FlxKey.A, FlxKey.LEFT],
            NOTE_DOWN => [FlxKey.S, FlxKey.DOWN],
            NOTE_UP => [FlxKey.W, FlxKey.UP],
            NOTE_RIGHT => [FlxKey.D, FlxKey.RIGHT],

            FULLSCREEN => [FlxKey.F11],
            DEBUG => [FlxKey.SEVEN],
            DEBUG_RELOAD => [FlxKey.F5]
        ];
    }

    public function getCurrentMappings():ActionMap<Control> {
        final map:ActionMap<Control> = [];

        for(i in 0...controlTypes.length)
            map.set(controlTypes[i], Reflect.field(save.data, controlTypes[i].getName()));

        return map;
    }

    public function bind(control:Control, idx:Int, input:FlxControlInputType):Void {
        var inputs:Array<FlxControlInputType> = Reflect.field(save.data, control.getName());
        inputs[idx] = input;
        Reflect.setField(save.data, control.getName(), inputs);
        resetMappings(getCurrentMappings());
    }

    public function flush():Void {
        save.flush();
    }

    override function destroy():Void {
        save.close();
        super.destroy();
    }
}