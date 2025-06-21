package funkin.ui.notification;

import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.ui.panel.Panel;

enum NotificationType {
    SUCCESS;
    INFO;
    QUESTION;
    WARNING;
    ERROR;
}

typedef NotificationButton = {
    var text:String;
    var callback:Void->Void;
}

/**
 * A basic notification element.
 * 
 * These should be created within a `NotificationContainer`
 * via their `send()` method, not directly.
 */
class Notification extends UIComponent {
    public var bg:Panel;

    public var idleTimer:Float = 2;
    public var closed:Bool = false;

    public var onClose:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public var onButtonPress:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

    public function new(type:NotificationType, message:String, buttons:Array<NotificationButton>) {
        super();

        bg = new Panel(0, 0, 280, 90);
        add(bg);

        final icon:FlxSprite = new FlxSprite(10, 10).loadGraphic(Paths.image('ui/images/status/${type.getName().toLowerCase()}'));
        add(icon);

        final messageText:Label = new Label(icon.width + 20, 10, message);
        messageText.fieldWidth = bg.width - (icon.width + 30);
        add(messageText);

        final buttonContainer:FlxSpriteContainer = new FlxSpriteContainer(bg.width - 10, bg.height - 10);
        add(buttonContainer);

        var x:Float = 0;
        for(i in 0...buttons.length) {
            final button:Button = new Button(x, 0, buttons[i].text);
            button.callback = buttons[i].callback;
            buttonContainer.add(button);
            x += button.width + 10;
        }
        buttonContainer.x -= buttonContainer.width;
        buttonContainer.y -= buttonContainer.height;

        directAlpha = true;
    }

    override function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final ret:Bool = FlxG.mouse.overlaps(bg, getDefaultCamera()) && UIUtil.allDropDowns.length == 0;
        _checkingMouseOverlap = false;
        return ret;
    }

    override function update(elapsed:Float):Void {
        if(checkMouseOverlap())
            idleTimer = 2;
        else {
            idleTimer -= elapsed;
            if(idleTimer <= 0) {
                if(!closed)
                    close();
                
                idleTimer = 0;
            }
        }
        super.update(elapsed);
    }

    public function close():Void {
        if(closed)
            return;

        closed = true;
        onClose.dispatch();

        FlxTween.tween(this, {alpha: 0}, 0.5, {ease: FlxEase.cubeOut, onComplete: (_) -> {
            container.remove(this, true);
            destroy();
        }});
    }
}