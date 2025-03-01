package funkin.ui.topbar;

import funkin.ui.dropdown.*;
import funkin.ui.dropdown.DropDown;

import flixel.input.keyboard.FlxKey;

class TopBar extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var dropdown:DropDown;

    public var leftItems(default, set):Array<TopBarItemType> = [];
    public var rightItems(default, set):Array<TopBarItemType> = [];

    public var leftShortcutMap(default, null):Map<Array<FlxKey>, Void->Void> = [];
    public var rightShortcutMap(default, null):Map<Array<FlxKey>, Void->Void> = [];

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        bg = new FlxSprite().loadGraphic(Paths.image("ui/images/top_bar"));
        bg.setGraphicSize(FlxG.width, bg.frameHeight);
        bg.updateHitbox();
        add(bg);

        _leftItemContainer = new FlxSpriteContainer();
        add(_leftItemContainer);

        _rightItemContainer = new FlxSpriteContainer();
        add(_rightItemContainer);
    }

    public static function getItemName(item:TopBarItemType):String {
        // is there a better way to do this
        //                            please i beg
        return switch(item) {
            case Button(name, _): name;
            case DropDown(name, _): name;
            case Slider(name, _, _, _): name;
            default: null;
        }
    }

    override function update(elapsed:Float) {
        for(keys => callback in leftShortcutMap)
            _handleShortcut(keys, callback);

        for(keys => callback in rightShortcutMap)
            _handleShortcut(keys, callback);
        
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private var _leftItemContainer:FlxSpriteContainer;
    private var _rightItemContainer:FlxSpriteContainer;

    private function _handleShortcut(keys:Array<FlxKey>, callback:Void->Void):Void {
        if(keys.length > 1) {
            final needsShift:Bool = keys.contains(SHIFT);
            if(!needsShift && FlxG.keys.pressed.SHIFT)
                return;

            var pressed:Int = 0;
            for(i in 0...keys.length - 1) {
                if(FlxG.keys.anyPressed([keys[i]]))
                    pressed++;
            }
            final lastKeyPressed:Bool = FlxG.keys.anyJustPressed([keys.unsafeLast()]);
            if(lastKeyPressed)
                pressed++;

            if(lastKeyPressed && pressed == keys.length && callback != null)
                callback();
        } else {
            if(FlxG.keys.anyJustPressed(keys) && callback != null)
                callback();
        }
    }

    @:noCompletion
    private function set_leftItems(newItems:Array<TopBarItemType>):Array<TopBarItemType> {
        for(item in _leftItemContainer) {
            if(item != null)
                item.destroy();
        }
        _leftItemContainer.clear();

        var totalWidth:Float = 0;
        leftShortcutMap.clear();

        for(i in 0...newItems.length) {
            final rawItem:TopBarItemType = newItems[i];
            switch(rawItem) {
                case Button(name, callback):
                    final item:TopBarButton = new TopBarButton(totalWidth, 0, name, callback);
                    totalWidth += item.width;
                    _leftItemContainer.add(item);

                case DropDown(name, items):
                    final item:TopBarDropDownButton = new TopBarDropDownButton(totalWidth, 0, name, null);
                    item.topBar = this;
                    item.callback = () -> {
                        dropdown = new DropDown(item.x, item.y + bg.height, items);
                        dropdown.topBar = this;
                        dropdown.setPosition(
                            FlxMath.bound(dropdown.x, 0, FlxG.width - dropdown.bg.width),
                            FlxMath.bound(dropdown.y, 0, FlxG.height - dropdown.bg.height),
                        );
                        add(dropdown);
                    };
                    totalWidth += item.width;
                    _leftItemContainer.add(item);

                    for(item in items) {
                        switch(item) {
                            case Button(_, shortcut, callback):
                                if(shortcut != null)
                                    leftShortcutMap.set(shortcut, callback);

                            default:
                        }
                    }

                case Slider(name, min, max, step):
                    // TODO

                case Text(contents):
                    final item:TopBarText = new TopBarText(totalWidth, 0, contents);
                    totalWidth += item.width;
                    _leftItemContainer.add(item);
            }
        }
        return leftItems = newItems;
    }

    @:noCompletion
    private function set_rightItems(newItems:Array<TopBarItemType>):Array<TopBarItemType> {
        for(item in _rightItemContainer) {
            if(item != null)
                item.destroy();
        }
        _rightItemContainer.clear();
        rightShortcutMap.clear();

        for(i in 0...newItems.length) {
            final rawItem:TopBarItemType = newItems[i];
            switch(rawItem) {
                case Button(name, callback):
                    final item:TopBarButton = new TopBarButton(0, 0, name, callback);

                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);

                case DropDown(name, items):
                    final item:TopBarDropDownButton = new TopBarDropDownButton(0, 0, name, null);
                    item.topBar = this;
                    item.callback = () -> {
                        dropdown = new DropDown(item.x, item.y + bg.height, items);
                        dropdown.topBar = this;
                        dropdown.setPosition(
                            FlxMath.bound(dropdown.x, 0, FlxG.width - dropdown.bg.width),
                            FlxMath.bound(dropdown.y, 0, FlxG.height - dropdown.bg.height),
                        );
                        add(dropdown);
                    };
                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);

                    for(item in items) {
                        switch(item) {
                            case Button(_, shortcut, callback):
                                if(shortcut != null)
                                    rightShortcutMap.set(shortcut, callback);

                            default:
                        }
                    }

                case Slider(name, min, max, step):
                    // TODO

                case Text(contents):
                    final item:TopBarText = new TopBarText(0, 0, contents);
                    
                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);
            }
        }
        return rightItems = newItems;
    }
}