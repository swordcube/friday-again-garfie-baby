package funkin.ui;

import flixel.util.FlxSignal;

enum AtlasTextListDirection {
    HORIZONTAL;
    VERTICAL;
}

/**
 * A scrollable list of several `AtlasText` instances.
 * 
 * Mainly used for things like the freeplay and pause menu.
 */
class AtlasTextList extends FlxTypedContainer<AtlasText> {
    public var direction:AtlasTextListDirection = VERTICAL;

    public var curSelected:Int = 0;
    public var callbacks:Map<String, ListCallbacks> = [];
    public var disableTouchInputs:Bool = false;

    public var onSelect:FlxTypedSignal<Int->AtlasText->Void> = new FlxTypedSignal<Int->AtlasText->Void>();
    public var onAccept:FlxTypedSignal<Int->AtlasText->Void> = new FlxTypedSignal<Int->AtlasText->Void>();

    public var enabled:Bool = true;

    public function new(?direction:AtlasTextListDirection) {
        super();
        this.direction = direction ?? VERTICAL;
    }

    public function clearList():Void {
        while(length > 0) {
            final text:AtlasText = members[0];
            remove(text, true);
            text.destroy();
        }
        callbacks.clear();
    }

    public function addStaticItem(x:Float = 0, y:Float = 0, text:String, callbacks:ListCallbacks):AtlasText {
        final item:AtlasText = new AtlasText(x, y, "bold", LEFT, text);
        item.ID = length;
        this.callbacks.set(text, callbacks);
        return cast add(item);
    }

    public function addItem(text:String, callbacks:ListCallbacks):AtlasText {
        final item:AtlasText = switch(direction) {
            case HORIZONTAL:
                final lastItemX:Float = (members[length - 1]?.x ?? 0.0) + (members[length - 1]?.width ?? 0.0);
                addStaticItem((length != 0) ? lastItemX + 30 : 0, 0, text, callbacks);
            
            default:
                final i:AtlasText = addStaticItem(0, 30 + (70 * length), text, callbacks);
                i.isMenuItem = true;
                i;
        }
        item.targetY = item.ID = length;
        return item;
    }

    public function removeItem(text:String):Void {
        for(item in members.copy()) {
            if(item.text == text) {
                remove(item, true);
                item.destroy();
                return;
            }
        }
        for(i in 0...length)
            members[i].targetY = i;

        callbacks.remove(text);
    }

    override function update(elapsed:Float):Void {
        if(enabled) {
            final wheel:Float = TouchUtil.wheel;
            final controls:Controls = Controls.instance;

            final up:Bool = (direction == HORIZONTAL) ? controls.justPressed.UI_LEFT : controls.justPressed.UI_UP;
            final down:Bool = (direction == HORIZONTAL) ? controls.justPressed.UI_RIGHT : controls.justPressed.UI_DOWN;
    
            if(up || (!disableTouchInputs && SwipeUtil.swipeUp) || wheel < 0)
                changeSelection(-1);
    
            if(down || (!disableTouchInputs && SwipeUtil.swipeDown) || wheel > 0)
                changeSelection(1);
    
            if(controls.justPressed.ACCEPT || (!disableTouchInputs && TouchUtil.justReleased && !SwipeUtil.swipeAny && TouchUtil.overlaps(members.unsafeGet(curSelected), getDefaultCamera())))
                accept();
        }
        super.update(elapsed);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false, ?playScrollSFX:Bool = true):Void {
        if(by == 0 && !force)
            return;

        var song:AtlasText = null;
        curSelected = FlxMath.wrap(curSelected + by, 0, length - 1);
        
        for(i in 0...length) {
            song = members[i];
            song.targetY = i - curSelected;
            song.alpha = (i == curSelected) ? 1.0 : 0.6;
        }
        final item:AtlasText = members.unsafeGet(curSelected);
        onSelect.dispatch(curSelected, item);

        final callback = callbacks.get(item.text).onSelect;
        if(callback != null)
            callback(curSelected, item);

        if(playScrollSFX)
            FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function accept():Void {
        final item:AtlasText = members.unsafeGet(curSelected);
        onAccept.dispatch(curSelected, item);

        final callback = callbacks.get(item.text).onAccept;
        if(callback != null)
            callback(curSelected, item);
    }
}

typedef ListCallbacks = {
    var ?onSelect:(Int, AtlasText) -> Void; // item index, then the item itself
    var ?onAccept:(Int, AtlasText) -> Void; // item index, then the item itself
}