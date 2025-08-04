package funkin.ui;

import flixel.util.FlxSignal;

/**
 * A scrollable list of several `AtlasText` instances.
 * 
 * Mainly used for things like the freeplay and pause menu.
 */
class AtlasTextList extends FlxTypedGroup<AtlasText> {
    public var curSelected:Int = 0;
    public var acceptTimeout:Float = 0;
    public var callbacks:Map<String, ListCallbacks> = [];

    public function clearList():Void {
        while(length > 0) {
            final text:AtlasText = members[0];
            text.destroy();
            remove(text, true);
        }
        callbacks.clear();
    }

    public function addItem(text:String, callbacks:ListCallbacks):AtlasText {
        final item:AtlasText = new AtlasText(0, 30 + (70 * length), "bold", LEFT, text);
        item.isMenuItem = true;
        item.targetY = length;
        add(item);

        this.callbacks.set(text, callbacks);
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

        acceptTimeout -= elapsed;
        if(acceptTimeout < 0)
            acceptTimeout = 0;

        if(SwipeUtil.swipeAny)
            acceptTimeout = 0.5;

        if(controls.justPressed.UI_UP || SwipeUtil.swipeUp || wheel < 0)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN || SwipeUtil.swipeDown || wheel > 0)
            changeSelection(1);

        final pointer = TouchUtil.touch;
        if(controls.justPressed.ACCEPT || (TouchUtil.justPressed && acceptTimeout <= 0 && (pointer?.overlaps(members.unsafeGet(curSelected)) ?? false) == true)) {
            final callback = callbacks.get(members.unsafeGet(curSelected).text).onAccept;
            if(callback != null)
                callback(curSelected, members.unsafeGet(curSelected));
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
        final callback = callbacks.get(members.unsafeGet(curSelected).text).onSelect;
        if(callback != null)
            callback(curSelected, members.unsafeGet(curSelected));

        if(playScrollSFX)
            FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }
}

typedef ListCallbacks = {
    var ?onSelect:(Int, AtlasText) -> Void; // item index, then the item itself
    var ?onAccept:(Int, AtlasText) -> Void; // item index, then the item itself
}