package funkin.backend;

import flixel.util.FlxSave;
import flixel.util.FlxTimer;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

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
    DEBUG_OVERLAY;
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

        resetMappings(removeInvalidInputs(getCurrentMappings()));
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

    public static function getGamepadInputFromInputType(shit:FlxControlInputType):FlxGamepadInputID {
        var input:FlxGamepadInputID = NONE;
        if(shit != null) {
            switch(shit.simplify()) {
                case Gamepad(Lone(i)):
                    input = i;
    
                default:
            }
        }
        return input;
    }

    public function apply():Void {
        final mappings:ActionMap<Control> = removeInvalidInputs(getCurrentMappings());
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

    // 0-1 is keyboard input
    // 2-3 is gamepad input
    public function getDefaultMappings():ActionMap<Control> {
        return [
            UI_LEFT => [FlxKey.A, FlxKey.LEFT, FlxGamepadInputID.DPAD_LEFT, FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT],
            UI_DOWN => [FlxKey.S, FlxKey.DOWN, FlxGamepadInputID.DPAD_DOWN, FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN],
            UI_UP => [FlxKey.W, FlxKey.UP, FlxGamepadInputID.DPAD_UP, FlxGamepadInputID.LEFT_STICK_DIGITAL_UP],
            UI_RIGHT => [FlxKey.D, FlxKey.RIGHT, FlxGamepadInputID.DPAD_RIGHT, FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT],

            ACCEPT => [FlxKey.ENTER, FlxKey.SPACE, FlxGamepadInputID.A, FlxGamepadInputID.START],
            BACK => [FlxKey.ESCAPE, FlxKey.BACKSPACE, FlxGamepadInputID.B, FlxGamepadInputID.NONE],
            RESET => [FlxKey.R, FlxKey.NONE, FlxGamepadInputID.BACK, FlxGamepadInputID.NONE],
            PAUSE => [FlxKey.ENTER, FlxKey.ESCAPE, FlxGamepadInputID.START, FlxGamepadInputID.NONE],

            NOTE_LEFT => [FlxKey.A, FlxKey.LEFT, FlxGamepadInputID.DPAD_LEFT, FlxGamepadInputID.X],
            NOTE_DOWN => [FlxKey.S, FlxKey.DOWN, FlxGamepadInputID.DPAD_DOWN, FlxGamepadInputID.A],
            NOTE_UP => [FlxKey.W, FlxKey.UP, FlxGamepadInputID.DPAD_UP, FlxGamepadInputID.Y],
            NOTE_RIGHT => [FlxKey.D, FlxKey.RIGHT, FlxGamepadInputID.DPAD_RIGHT, FlxGamepadInputID.B],

            SCREENSHOT => [FlxKey.F3, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            FULLSCREEN => [FlxKey.F11, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],

            VOLUME_UP => [FlxKey.PLUS, FlxKey.NUMPADPLUS, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            VOLUME_DOWN => [FlxKey.MINUS, FlxKey.NUMPADMINUS, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            VOLUME_MUTE => [FlxKey.ZERO, FlxKey.NUMPADZERO, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],

            DEBUG => [FlxKey.SEVEN, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            DEBUG_RELOAD => [FlxKey.F5, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            DEBUG_OVERLAY => [FlxKey.F12, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            EMERGENCY => [FlxKey.F7, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
            MANAGE_CONTENT => [FlxKey.TAB, FlxKey.NONE, FlxGamepadInputID.NONE, FlxGamepadInputID.NONE],
        ];
    }

    public function getCurrentMappings():ActionMap<Control> {
        final map:ActionMap<Control> = [];
        final defaultMappings:ActionMap<Control> = getDefaultMappings();

        for(i in 0...controlTypes.length) {
            final inputs:Array<FlxControlInputType> = Reflect.field(save.data, controlTypes[i].getName());
            final defaultInputs:Array<FlxControlInputType> = defaultMappings[controlTypes[i]];
            for(j in 0...defaultInputs.length) {
                if(inputs[j] == null)
                    inputs[j] = defaultInputs[j]; // if any input is missing, use the default
            }
            map.set(controlTypes[i], inputs);
        }
        return map;
    }

    public function removeInvalidInputs(map:ActionMap<Control>):ActionMap<Control> {
        for(control => inputs in map) {
            for(bind in inputs.copy()) {
                if(bind == null || bind.compare(Keyboard(Lone(NONE))) || bind.compare(Gamepad(Lone(NONE))))
                    inputs.remove(bind);
            }
            map.set(control, inputs); // just in case  ...
        }
        return map;
    }
    
    // index is 0-1 here
    public function bindKey(control:Control, idx:Int, input:FlxKey):Void {
        var inputs:Array<FlxControlInputType> = Reflect.field(save.data, control.getName());
        inputs[idx] = (input != NONE) ? FlxControlInputType.fromKey(input) : null;
        Reflect.setField(save.data, control.getName(), inputs);

        var currentMappings:ActionMap<Control> = getCurrentMappings();
        currentMappings[control] = inputs;
        resetMappings(removeInvalidInputs(currentMappings));
    }

    // index is still 0-1 here
    public function bindGamepadInput(control:Control, idx:Int, input:FlxGamepadInputID):Void {
        var inputs:Array<FlxControlInputType> = Reflect.field(save.data, control.getName());
        inputs[idx + 2] = (input != NONE) ? FlxControlInputType.fromGamepad(input) : null;
        Reflect.setField(save.data, control.getName(), inputs);

        var currentMappings:ActionMap<Control> = getCurrentMappings();
        currentMappings[control] = inputs;
        resetMappings(removeInvalidInputs(currentMappings));
    }

    public function flush():Void {
        save.flush();
    }

    override function destroy():Void {
        save.close();
        super.destroy();
    }
}