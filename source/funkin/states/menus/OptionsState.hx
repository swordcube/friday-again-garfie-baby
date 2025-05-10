package funkin.states.menus;

import flixel.util.typeLimit.NextState;
import funkin.ui.options.pages.*;

typedef OptionsStateParams = {
    var exitState:NextState;
}

class OptionsState extends FunkinState {
    public var initParams:OptionsStateParams = {
        exitState: null
    };
    public var bg:FlxSprite;
    public var currentPage:Page;

    public function new(?params:OptionsStateParams) {
		super();
		if(params == null) {
			params = {
                exitState: null
            };
        }
		initParams = params;
    }

    override function create():Void {
        super.create();

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_blue"));
        bg.screenCenter();
        bg.scrollFactor.set();
        add(bg);

        loadPage(new MainPage());
    }

    public function loadPage(newPage:Page):Void {
        final pageIndex:Int = members.indexOf(currentPage);
        if(currentPage != null) {
            remove(currentPage, true);
            currentPage.destroy();
        }
        currentPage = newPage;
        currentPage.menu = this;

        currentPage.create();
        currentPage.createPost();

        if(pageIndex != -1)
            insert(pageIndex, currentPage);
        else
            add(currentPage);
    }
}