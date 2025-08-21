package funkin.ui;

import flixel.util.FlxSignal;

/**
 * A scrollable list of several `AtlasText` instances.
 * 
 * Mainly used for things like the freeplay and pause menu.
 */
class AtlasTextList extends FlxTypedContainer<AtlasText> {
    public var curSelected:Int = 0;
    public var callbacks:Map<String, ListCallbacks> = [];
    public var disableTouchInputs:Bool = false;

    public var onSelect:FlxTypedSignal<Int->AtlasText->Void> = new FlxTypedSignal<Int->AtlasText->Void>();
    public var onAccept:FlxTypedSignal<Int->AtlasText->Void> = new FlxTypedSignal<Int->AtlasText->Void>();

    public function clearList():Void {
        while(length > 0) {
            final text:AtlasText = members[0];
            text.destroy();
            remove(text, true);
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
        final item:AtlasText = addStaticItem(0, 30 + (70 * length), text, callbacks);
        item.isMenuItem = true;
        item.targetY = item.ID = length;
        return item;
    }

    public function removeItem(text:String):Void {
        for(item in members.copy()) {
            if(item.text == text) {
                item.destroy();
                remove(item, true);
                return;
            }
        }
        for(i in 0...length)
            members[i].targetY = i;

        callbacks.remove(text);
    }

    override function update(elapsed:Float):Void {
        final wheel:Float = TouchUtil.wheel;
        final controls:Controls = Controls.instance;

        if(controls.justPressed.UI_UP || (!disableTouchInputs && SwipeUtil.swipeUp) || wheel < 0)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN || (!disableTouchInputs && SwipeUtil.swipeDown) || wheel > 0)
            changeSelection(1);

        if(controls.justPressed.ACCEPT || (!disableTouchInputs && TouchUtil.justReleased && !SwipeUtil.swipeAny && TouchUtil.overlaps(members.unsafeGet(curSelected), getDefaultCamera())))
            accept();
        
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