package funkin.substates.charter;

import flixel.math.FlxRect;
import flixel.math.FlxPoint;
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

        if(FlxG.mouse.justPressed)
            FlxG.sound.play(Paths.sound("editors/charter/sfx/click_down"));
        
        else if(FlxG.mouse.justReleased)
            FlxG.sound.play(Paths.sound("editors/charter/sfx/click_up"));
        
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

    public var grpButtons(default, null):FlxSpriteGroup;
    public var eventIconCamera(default, null):FlxCamera;

    public function new(menu:CharterEventMenu) {
        charter = cast FlxG.state;
        this.menu = menu;
        super(0, 0, "Edit event pack", false, 600, 410);
    }

    override function initContents():Void {
        menu.camera.visible = false;

        final infoSeparator = new FlxSprite(46, 4).loadGraphic(Paths.image("ui/images/separator"));
        infoSeparator.setGraphicSize(1, 367);
        infoSeparator.updateHitbox();
        infoSeparator.antialiasing = false;
        addToContents(infoSeparator);

        eventIconCamera = new FlxCamera(((FlxG.width - 600) * 0.5) + 5, ((FlxG.height - 428) * 0.5) + 47, 46, 365);
        eventIconCamera.bgColor = 0;
        FlxG.cameras.add(eventIconCamera, false);

        grpButtons = new FlxSpriteGroup(2, 2);
        grpButtons.cameras = [eventIconCamera];
        addToContents(grpButtons);

        final event:ChartEditorEvent = menu.event; // shortcut!
        for(i => e in event.events) {
            final eventButton = new Button(0, i * 32, "", 40, 30);
            eventButton.icon = Paths.image('editors/charter/images/events/${e.type}');
            grpButtons.add(eventButton);

            FlxTimer.wait(0.001, () -> {
                eventButton.setPosition(0, i * 32);
                eventButton.cameras = [eventIconCamera];
            });
        }
        final addButton = new Button(0, (grpButtons.length - 1) * 32, "", 40, 32);
        addButton.bg.color = FlxColor.LIME;
        addButton.icon = Paths.image("editors/charter/images/event_add_icon");
        grpButtons.add(addButton);

        FlxTimer.wait(0.001, () -> {
            menu.camera.visible = true; // shhhh there's no jank!! totally!!
            addButton.setPosition(0, (grpButtons.length - 1) * 32);
            addButton.cameras = [eventIconCamera];
        });
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        final p:FlxPoint = FlxG.mouse.getViewPosition(menu.camera);
        if(p.x >= eventIconCamera.x && p.y >= eventIconCamera.y && p.x <= eventIconCamera.x + eventIconCamera.width && p.y <= eventIconCamera.y + eventIconCamera.height) {
            final wheel:Float = -FlxG.mouse.wheel;
            if(wheel != 0)
                eventIconCamera.scroll.y = FlxMath.bound(eventIconCamera.scroll.y + (wheel * 50), 0, Math.max(grpButtons.height - eventIconCamera.height, 0));
        }
    }
}