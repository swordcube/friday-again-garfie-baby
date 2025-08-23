package funkin.ui.menubar;

import flixel.util.FlxSort;
import funkin.ui.dropdown.*;
import funkin.ui.dropdown.DropDown;

import flixel.util.FlxDestroyUtil;
import flixel.input.keyboard.FlxKey;

class MenuBar extends UIComponent {
    public var bg:FlxSprite;
    public var dropdown:DropDown;

    public var leftItems(default, set):Array<MenuBarItemType> = [];
    public var rightItems(default, set):Array<MenuBarItemType> = [];

    public var leftShortcuts(default, null):Array<MenuBarShortcut> = [];
    public var rightShortcuts(default, null):Array<MenuBarShortcut> = [];
    public var allShortcuts(default, null):Array<MenuBarShortcut> = [];

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

    public static function getItemName(item:MenuBarItemType):String {
        // is there a better way to do this
        //                            please i beg
        return switch(item) {
            case Button(name, _): name;
            case DropDown(name, _): name;
            default: null;
        }
    }

    override function update(elapsed:Float) {
        _handleShortcuts(allShortcuts);

        var seX:Float = x;
        for(i in 0..._leftItemContainer.length) {
            var item:FlxSprite = _leftItemContainer.members.unsafeGet(i);
            item.x = seX;
            seX += item.width;
        }
        var seX:Float = FlxG.width;
        for(i in 0..._rightItemContainer.length) {
            var item:FlxSprite = _rightItemContainer.members.unsafeGet(_rightItemContainer.length - i - 1);
            seX -= item.width;
            item.x = seX;
        }
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private var _leftItemContainer:FlxSpriteContainer;
    private var _rightItemContainer:FlxSpriteContainer;

    private function _handleShortcuts(shortcuts:Array<MenuBarShortcut>):Void {
        var pick:Array<MenuBarShortcut> = [];
        for(shortcut in shortcuts) {
            if(shortcut.keybinds == null || shortcut.keybinds.length == 0)
                continue;

            for(i => keybind in shortcut.keybinds) {
                if(keybind == null || keybind.length == 0)
                    continue;

                var curPressed:Int = 0;
                for(key in keybind) {
                    if(FlxG.keys.checkStatus(key, PRESSED))
                        curPressed++;
                }
                if(curPressed >= keybind.length && FlxG.keys.anyJustPressed(keybind)) {
                    shortcut.keybindSetPressed = i;
                    pick.push(shortcut);
                }
            }
        }
        if(pick.length == 0)
            return;

        pick.sort((s1, s2) -> FlxSort.byValues(FlxSort.ASCENDING, s1.keybinds[s1.keybindSetPressed].length, s2.keybinds[s2.keybindSetPressed].length));

        final lastPick:MenuBarShortcut = pick.last();
        if(lastPick.callback != null)
            lastPick.callback();
    }

    @:noCompletion
    private function set_leftItems(newItems:Array<MenuBarItemType>):Array<MenuBarItemType> {
        for(item in _leftItemContainer) {
            if(item != null)
                item.destroy();
        }
        _leftItemContainer.clear();

        var totalWidth:Float = 0;
        leftShortcuts.clear();

        for(i in 0...newItems.length) {
            final rawItem:MenuBarItemType = newItems[i];
            switch(rawItem) {
                case Button(name, callback):
                    final item:MenuBarButton = new MenuBarButton(totalWidth, 0, name, callback);
                    totalWidth += item.width;
                    _leftItemContainer.add(item);

                case DropDown(name, items):
                    final item:MenuBarDropDownButton = new MenuBarDropDownButton(totalWidth, 0, name, null);
                    item.menuBar = this;
                    item.callback = () -> {
                        if(dropdown != null) {
                            remove(dropdown, true);
                            dropdown = FlxDestroyUtil.destroy(dropdown);
                        }
                        dropdown = new DropDown(item.x, item.y + bg.height, 0, 0, items);
                        dropdown.menuBar = this;
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
                                if(shortcut != null) {
                                    leftShortcuts.push({
                                        keybinds: shortcut,
                                        callback: callback
                                    });
                                }

                            default:
                        }
                    }

                case Slider(min, max, step, value, width, callback, valueFactory):
                    final item:MenuBarSlider = new MenuBarSlider(totalWidth, 0, min, max, step, value, width, callback, valueFactory);
                    totalWidth += item.width;
                    _leftItemContainer.add(item);

                case Text(contents):
                    final item:MenuBarText = new MenuBarText(totalWidth, 0, contents);
                    totalWidth += item.width;
                    _leftItemContainer.add(item);

                case Textbox(contents, callback, maxCharacters, autoSize, width, valueFactory):
                    autoSize ??= false;
                    width ??= 100;
                    maxCharacters ??= 0;

                    final item:MenuBarTextbox = new MenuBarTextbox(totalWidth, 0, contents, maxCharacters, autoSize, width, callback, valueFactory);
                    totalWidth += item.width;
                    _leftItemContainer.add(item);
            }
        }
        allShortcuts = leftShortcuts.concat(rightShortcuts);
        return leftItems = newItems;
    }

    @:noCompletion
    private function set_rightItems(newItems:Array<MenuBarItemType>):Array<MenuBarItemType> {
        for(item in _rightItemContainer) {
            if(item != null)
                item.destroy();
        }
        _rightItemContainer.clear();
        rightShortcuts.clear();

        for(i in 0...newItems.length) {
            final rawItem:MenuBarItemType = newItems[i];
            switch(rawItem) {
                case Button(name, callback):
                    final item:MenuBarButton = new MenuBarButton(0, 0, name, callback);

                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);

                case DropDown(name, items):
                    final item:MenuBarDropDownButton = new MenuBarDropDownButton(0, 0, name, null);
                    item.menuBar = this;
                    item.callback = () -> {
                        if(dropdown != null) {
                            remove(dropdown, true);
                            dropdown = FlxDestroyUtil.destroy(dropdown);
                        }
                        dropdown = new DropDown(item.x, item.y + bg.height, 0, 0, items);
                        dropdown.menuBar = this;
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
                                if(shortcut != null) {
                                    rightShortcuts.push({
                                        keybinds: shortcut,
                                        callback: callback
                                    });
                                }

                            default:
                        }
                    }

                case Slider(min, max, step, value, width, callback, valueFactory):
                    final item:MenuBarSlider = new MenuBarSlider(0, 0, min, max, step, value, width, callback, valueFactory);

                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);

                case Text(contents):
                    final item:MenuBarText = new MenuBarText(0, 0, contents);
                    
                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);

                case Textbox(contents, callback, maxCharacters, autoSize, width, valueFactory):
                    autoSize ??= false;
                    width ??= 100;
                    maxCharacters ??= 0;

                    final item:MenuBarTextbox = new MenuBarTextbox(0, 0, contents, maxCharacters, autoSize, width, callback, valueFactory);
                    
                    for(leItem in _rightItemContainer)
                        leItem.x -= item.width;
                    
                    item.x = FlxG.width - item.width;
                    _rightItemContainer.add(item);
            }
        }
        allShortcuts = leftShortcuts.concat(rightShortcuts);
        return rightItems = newItems;
    }
}

@:structInit
class MenuBarShortcut {
    public var keybinds:Array<Array<FlxKey>>;
    public var callback:Void->Void;

    @:optional
    public var keybindSetPressed:Int = -1;
}