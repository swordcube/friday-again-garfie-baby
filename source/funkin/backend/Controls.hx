package funkin.backend;

import flixel.util.FlxSave;
import flixel.util.FlxTimer;
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
    RESET;
    PAUSE;

    NOTE_LEFT;
    NOTE_DOWN;
    NOTE_UP;
    NOTE_RIGHT;

    SCREENSHOT;
    FULLSCREEN;

    VOLUME_UP;
    VOLUME_DOWN;
    VOLUME_MUTE;

    DEBUG;
    DEBUG_RELOAD;
    EMERGENCY;
    MANAGE_CONTENT;
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
        
        FlxTimer.wait(0.001, () -> {
            if(Controls.instance == this)
                apply();
        });
    }

    public static function getKeyFromInputType(shit:FlxControlInputType):FlxKey {
        var key:FlxKey = NONE;
        if(shit != null) {
            switch(shit.simplify()) {
                case Keyboard(Lone(k)):
                    key = k;
    
                default:
            }
        }
        return key;
    }

    public function apply():Void {
        final mappings:ActionMap<Control> = getCurrentMappings();
        FlxG.sound.volumeUpKeys = [for(input in mappings.get(VOLUME_UP)) {
            final key:FlxKey = getKeyFromInputType(input);
            if(key != NONE)
                key;
        }];
        FlxG.sound.volumeDownKeys = [for(input in mappings.get(VOLUME_DOWN)) {
            final key:FlxKey = getKeyFromInputType(input);
            if(key != NONE)
                key;
        }];
        FlxG.sound.muteKeys = [for(input in mappings.get(VOLUME_MUTE)) {
            final key:FlxKey = getKeyFromInputType(input);
            if(key != NONE)
                key;
        }];
    }

    public function getDefaultMappings():ActionMap<Control> {
        return [
            UI_LEFT => [FlxKey.A, FlxKey.LEFT],
            UI_DOWN => [FlxKey.S, FlxKey.DOWN],
            UI_UP => [FlxKey.W, FlxKey.UP],
            UI_RIGHT => [FlxKey.D, FlxKey.RIGHT],

            ACCEPT => [FlxKey.ENTER, FlxKey.SPACE],
            BACK => [FlxKey.ESCAPE, FlxKey.BACKSPACE],
            RESET => [FlxKey.R, FlxKey.NONE],
            PAUSE => [FlxKey.ENTER, FlxKey.ESCAPE],

            NOTE_LEFT => [FlxKey.A, FlxKey.LEFT],
            NOTE_DOWN => [FlxKey.S, FlxKey.DOWN],
            NOTE_UP => [FlxKey.W, FlxKey.UP],
            NOTE_RIGHT => [FlxKey.D, FlxKey.RIGHT],

            SCREENSHOT => [FlxKey.F3, FlxKey.NONE],
            FULLSCREEN => [FlxKey.F11, FlxKey.NONE],

            VOLUME_UP => [FlxKey.PLUS, FlxKey.NUMPADPLUS],
            VOLUME_DOWN => [FlxKey.MINUS, FlxKey.NUMPADMINUS],
            VOLUME_MUTE => [FlxKey.ZERO, FlxKey.NUMPADZERO],

            DEBUG => [FlxKey.SEVEN, FlxKey.NONE],
            DEBUG_RELOAD => [FlxKey.F5, FlxKey.NONE],
            EMERGENCY => [FlxKey.F7, FlxKey.NONE],
            MANAGE_CONTENT => [FlxKey.TAB, FlxKey.NONE],
        ];
    }

    public function getCurrentMappings():ActionMap<Control> {
        final map:ActionMap<Control> = [];

        for(i in 0...controlTypes.length)
            map.set(controlTypes[i], Reflect.field(save.data, controlTypes[i].getName()));

        return map;
    }

    public function bindKey(control:Control, idx:Int, input:FlxKey):Void {
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