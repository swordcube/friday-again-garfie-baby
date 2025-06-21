package funkin.ui.notification;

import flixel.util.FlxHorizontalAlign;
import funkin.ui.notification.Notification.NotificationType;

/**
 * A basic container for notification elements.
 * 
 * Automatically handles positioning and sending notifications.
 */
class NotificationContainer extends FlxTypedSpriteContainer<Notification> {
    static final PADDING:Float = 20;
    static final SPACING:Float = 20;

    public var horizontalAlign:FlxHorizontalAlign;

    public function new(horizontalAlign:FlxHorizontalAlign, ?y:Float) {
        var startingX:Float = 0;
        switch(horizontalAlign) {
            case LEFT:
                startingX = PADDING;
            
            case CENTER:
                Logs.warn("Center aligned notifications aren't supported, defaulting to left alignment");
                startingX = PADDING;

            case RIGHT:
                startingX = FlxG.width - PADDING;
        }
        super(startingX, y ?? (FlxG.height - PADDING));
        this.horizontalAlign = horizontalAlign;
    }

    public function send(type:NotificationType, message:String, ?consoleMessage:String):Notification {
        var notifColor:FlxColor = FlxColor.WHITE;
        switch(type) {
            case SUCCESS:
                notifColor = FlxColor.LIME;
                Logs.success(consoleMessage ?? message);

            case QUESTION:
                notifColor = FlxColor.CYAN;

                var notif:Notification = null; // stupid hack
                notif = new Notification(type, message, [
                    {
                        text: "Yes",
                        callback: () -> notif.onButtonPress.dispatch("Yes")
                    },
                    {
                        text: "No",
                        callback: () -> notif.onButtonPress.dispatch("No")
                    }
                ]);
                notif.bg.color = notifColor;
                notif.onClose.add(_addClosedNotif.bind(notif));
                add(notif);
                _updatePositions();
                return notif;

            case INFO:
                notifColor = FlxColor.CYAN;
                Logs.trace(consoleMessage ?? message);

            case WARNING:
                notifColor = FlxColor.YELLOW;
                Logs.warn(consoleMessage ?? message);

            case ERROR:
                notifColor = FlxColor.RED;
                Logs.error(consoleMessage ?? message);
        }
        var notif:Notification = null; // stupid hack
        notif = new Notification(type, message, [
            {
                text: "OK",
                callback: () -> notif.onButtonPress.dispatch("OK")
            }
        ]);
        notif.bg.color = notifColor;
        notif.onClose.add(_addClosedNotif.bind(notif));
        add(notif);
        _updatePositions();
        return notif;
    }

    override function update(elapsed:Float):Void {
        if(_closedNotifs.length > 0) {
            _updatePositions();
            _closedNotifs.clear();
        }
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private var _closedNotifs:Array<Notification> = [];

    private function _addClosedNotif(notif:Notification):Void {
        _closedNotifs.push(notif);
    }

    private function _updatePositions():Void {
        final activeNotifs:Array<Notification> = members.filter((notif:Notification) -> {
            return !notif.closed;
        });
        for(i in 0...activeNotifs.length) {
            final notif:Notification = activeNotifs.unsafeGet(activeNotifs.length - i - 1);
            notif.y = (y + SPACING) - ((i + 1) * (notif.bg.height + SPACING));

            if(horizontalAlign == RIGHT)
                notif.x = x - notif.bg.width;
            else
                notif.x = x;
        }
    }
}