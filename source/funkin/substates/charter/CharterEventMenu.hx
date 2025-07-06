package funkin.substates.charter;

import flixel.util.FlxTimer;
import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.ui.*;
import funkin.ui.dropdown.*;
import funkin.ui.panel.*;
import funkin.ui.slider.*;

import funkin.scripting.*;
import funkin.states.editors.ChartEditor;

class CharterEventMenu extends UISubState {
    public var onClose:FlxTypedSignal<(event:ChartEditorEvent)->Void> = new FlxTypedSignal<(event:ChartEditorEvent)->Void>();
    
    public var event:ChartEditorEvent;
    public var window:CharterEventWindow;

    public function new(event:ChartEditorEvent) {
        super();
        this.event = event;
    }

    override function create():Void {
        super.create();
        
        camera = new FlxCamera();
        camera.bgColor = 0x80000000;
        FlxG.cameras.add(camera, false);
        
        window = new CharterEventWindow(this);
        window.onClose.add(() -> {
            onClose.dispatch(event);
            close();
        });
        window.setPosition(
            (FlxG.width - window.bg.width) * 0.5,
            (FlxG.height - window.bg.height) * 0.5
        );
        add(window);
    }

    override function update(elapsed:Float):Void {
        final isUIFocused:Bool = UIUtil.isAnyComponentFocused([window.charter.grid, window.charter.selectionBox]);
        FlxG.sound.acceptInputs = !UIUtil.isModifierKeyPressed(ANY) && !isUIFocused;
        
        if(FlxG.mouse.justReleased && !window.checkMouseOverlap())
            FlxTimer.wait(0.001, window.close);
        
        super.update(elapsed);
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }   
}

class CharterEventWindow extends Window {
    public var charter(default, null):ChartEditor;
    public var menu(default, null):CharterEventMenu;

    public function new(menu:CharterEventMenu) {
        charter = cast FlxG.state;
        this.menu = menu;
        super(0, 0, "Edit event pack", false, 600, 428);
    }

    override function initContents():Void {
        final tempScript:FunkinScript = FunkinScript.fromFile(Paths.script("temp"), true);
        tempScript.set("charter", charter);
        tempScript.set("menu", menu);
        tempScript.setParent(this);
        tempScript.execute();
    }
}