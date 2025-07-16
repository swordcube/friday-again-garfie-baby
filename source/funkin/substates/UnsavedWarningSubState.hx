package funkin.substates;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxTimer;
import funkin.scripting.*;
import funkin.states.editors.ChartEditor;
import funkin.ui.*;
import funkin.ui.dropdown.*;
import funkin.ui.panel.*;
import funkin.ui.slider.*;

class UnsavedWarningSubState extends UISubState {
    public var window:UnsavedWarningWindow;

    public var onAccept:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>(); // accept the loss, you lose your shit!
    public var onCancel:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>(); // don't accept the loss, you probably saved your shit!

    public var lastMouseVisible:Bool = false;

    override function create():Void {
        super.create();
        
        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;

        camera = new FlxCamera();
        camera.bgColor = 0x80000000;
        FlxG.cameras.add(camera, false);
        
        window = new UnsavedWarningWindow(0, 0, this);
        window.onClose.add(() -> {
            WindowUtil.resetClosing();
            close();
        });
        window.screenCenter();
        add(window);
    }

    override function update(elapsed:Float):Void {
        if(FlxG.mouse.justReleased && !window.checkMouseOverlap())
            FlxTimer.wait(0.001, window.close);
        
        super.update(elapsed);
    }

    override function destroy():Void {
        FlxG.mouse.visible = lastMouseVisible;
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}

class UnsavedWarningWindow extends Window {
    public var menu(default, null):UnsavedWarningSubState;
    public var charter(default, null):ChartEditor;
    public var easterEggActivated(default, null):Bool = false;

    public function new(x:Float = 0, y:Float = 0, menu:UnsavedWarningSubState) {
        charter = cast FlxG.state;
        this.menu = menu;
        super(x, y, "Hey! Listen!", false, 320, 130);
    }

    override function initContents():Void {
        easterEggActivated = FlxG.random.bool((1 / 4096) * 100);
        if(easterEggActivated)
            titleLabel.text = "are you sure";

        final icon:FlxSprite = new FlxSprite(10, 10).loadGraphic(Paths.image("ui/images/status/warning"));
        addToContents(icon);

        final text:Label = new Label(icon.x + icon.width + 10, icon.y, (easterEggActivated) ? "are you sure" : "Are you sure you want to exit?\nYou may lose unsaved progress!");
        addToContents(text);

        final acceptBtn:Button = new Button(text.x, text.y + text.height + 10, "Yes", 0, 0, () -> menu.onAccept.dispatch());
        addToContents(acceptBtn);

        final cancelBtn:Button = new Button(acceptBtn.x + acceptBtn.width + 10, acceptBtn.y, "No", acceptBtn.width, 0, () -> menu.onCancel.dispatch());
        addToContents(cancelBtn);

        FlxG.sound.play(Paths.sound("menus/sfx/warning"));
    }
}