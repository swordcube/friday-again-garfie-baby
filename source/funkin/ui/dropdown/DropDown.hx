package funkin.ui.dropdown;

import flixel.util.FlxTimer;

import funkin.ui.panel.Panel;
import funkin.ui.topbar.TopBar;

import funkin.utilities.InputFormatter;

class DropDown extends UIComponent {
    public var bg:Panel;
    public var topBar:TopBar;

    public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0, items:Array<DropDownItemType>) {
        super(x, y);

        bg = new Panel(0, 0, 32, 32);
        add(bg);

        _itemContainer = new FlxTypedSpriteContainer<DropDownItem>();
        add(_itemContainer);

        _separatorContainer = new FlxSpriteContainer();
        add(_separatorContainer);

        var totalHeight:Float = 0;
        for(rawItem in items) {
            switch(rawItem) {
                case Button(name, shortcut, callback):
                    var shortcutText:String = null;
                    if(shortcut != null && shortcut.length != 0)
                        shortcutText = [for(i in shortcut[0]) InputFormatter.formatFlixel(i)].join("+");
                    
                    final item:DropDownItem = new DropDownItem(2, 2 + totalHeight, name, shortcutText, callback);
                    item.dropdown = this;
                    totalHeight += item.height;
                    _itemContainer.add(item);
                
                case Checkbox(name, callback, valueFactory):
                    if(valueFactory == null)
                        valueFactory = () -> return false;
                    
                    final item:DropDownCheckboxItem = new DropDownCheckboxItem(2, 2 + totalHeight, name, () -> callback(!valueFactory()), valueFactory());
                    item.dropdown = this;
                    totalHeight += item.height;
                    _itemContainer.add(item);

                case Separator:
                    final sep:FlxSprite = new FlxSprite(4, 4 + totalHeight);
                    totalHeight += 6;
                    _separatorContainer.add(sep);
            }
        }
        bg.width = ((width <= 0) ? _itemContainer.width : width) + 8;
        bg.height = ((height <= 0) ? _itemContainer.height : height) + 4;

        for(item in _itemContainer) {
            item.bg.width = bg.width - 4;
            item.shortcut.x = item.bg.x + (item.bg.width - item.shortcut.width - 4);
        }
        for(sep in _separatorContainer)
            sep.makeSolid(bg.width - 12, 1, 0xFF434343);
    }

    override function update(elapsed:Float) {
        if(_isInteractable && FlxG.mouse.justReleased) {
            FlxTimer.wait(0.001, () -> {
                if(topBar != null)
                    topBar.dropdown = null;

                destroy();
            });
        }
        if(FlxG.mouse.justPressed)
            _isInteractable = true;
        
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private var _isInteractable:Bool = false;

    private var _itemContainer:FlxTypedSpriteContainer<DropDownItem>;
    private var _separatorContainer:FlxSpriteContainer;
}