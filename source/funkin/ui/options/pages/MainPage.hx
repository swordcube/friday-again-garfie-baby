package funkin.ui.options.pages;

import flixel.util.FlxTimer;

import funkin.ui.AtlasText;

import funkin.states.FunkinState;
import funkin.states.menus.MainMenuState;
import funkin.states.menus.OptionsState;

class MainPage extends Page {
    public var pages:Array<PageData>;
    public var curSelected:Int = 0;

    public var menuItems:FlxTypedSpriteContainer<AtlasText>;
    public var menuIcons:FlxSpriteContainer;

    override function create():Void {
        super.create();
        pages = [
            {
                name: "Gameplay",
                callback: () -> menu.loadPage(new GameplayPage())
            },
            {
                name: "Appearance",
                callback: () -> menu.loadPage(new AppearancePage())
            },
            {
                name: "Miscellanous",
                callback: () -> menu.loadPage(new MiscellanousPage())
            },
            {
                name: "Controls",
                callback: () -> menu.loadPage(new ControlsPage())
            },
            #if android
            {
                name: "Open Data Folder",
                callback: () -> trace("TODO: OPEN DATA FOLDER NOT IMPLEMENTED!")
            }
            #end
        ];
        for(pack => customPages in Options.customPages) {
            for(page in customPages) {
                pages.push({
                    name: page,
                    callback: () -> menu.loadPage(new OptionPage('${pack}://${page}'))
                });
            }
        }
        menuItems = new FlxTypedSpriteContainer<AtlasText>();
        add(menuItems);

        menuIcons = new FlxSpriteContainer();
        add(menuIcons);

        final iconSpacing:Float = 10;
        for(i => page in pages) {
            final item:AtlasText = new AtlasText(0, 90 * i, "bold", LEFT, page.name);
            item.alpha = 0.6;
            item.ID = i;
            menuItems.add(item);
        }
        menuItems.screenCenter();
        menuItems.x -= 50 + (iconSpacing * 2);

        for(i => page in pages) {
            final item:AtlasText = menuItems.members[i];
            final icon:FlxSprite = new FlxSprite(item.x + menuItems.width + iconSpacing, item.y - 10);
            
            final iconPath:String = Paths.image('menus/options/category/${page.name.toLowerCase()}');
            if(FlxG.assets.exists(iconPath))
                icon.loadGraphic(iconPath);
            else
                icon.visible = false;

            icon.setGraphicSize(100, 100);
            icon.updateHitbox();
            icon.alpha = 0.6;
            icon.ID = i;
            menuIcons.add(icon);
        }
        #if MOBILE_UI
        final state:FunkinState = cast FlxG.state;
        state.addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, goBack, 1.0);
        #end
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // traditional desktop controls
        final wheel:Float = MouseUtil.getWheel();
        if(controls.justPressed.UI_UP || wheel < 0)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN || wheel > 0)
            changeSelection(1);

        if(controls.justPressed.ACCEPT)
            onAccept();

        // mobile controls (available with mouse on desktop too cuz why not)
        menuItems.forEach(_checkMenuButtonPresses);
        menuIcons.forEach(_checkMenuButtonPresses);

        if(controls.justPressed.BACK) {
            goBack();
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    public function goBack():Void {
        Options.save();
        FlxG.switchState((OptionsState.lastParams.exitState != null) ? OptionsState.lastParams.exitState : MainMenuState.new);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = FlxMath.wrap(curSelected + by, 0, menuItems.length - 1);

        for(i => item in menuItems.members) {
            if(curSelected == i) {
                item.alpha = 1;
                menuIcons.members[i].alpha = 1;
            } else {
                item.alpha = 0.6;
                menuIcons.members[i].alpha = 0.6;
            }
        }
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function onAccept():Void {
        FlxTimer.wait(0.001, pages[curSelected].callback);
    }

    private function _checkMenuButtonPresses(button:FlxSprite):Void {
        final pointer = MouseUtil.getPointer();
        if(MouseUtil.isJustPressed() && pointer.overlaps(button, getDefaultCamera())) {
            if(curSelected != button.ID) {
                curSelected = button.ID;
                changeSelection(0, true);
                return;
            }
            onAccept();
        }
    }
}

typedef PageData = {
    var name:String;
    var callback:Void->Void;
}