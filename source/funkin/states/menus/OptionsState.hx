package funkin.states.menus;

import flixel.util.typeLimit.NextState;

import funkin.backend.InitState;
import funkin.ui.options.pages.*;

typedef OptionsStateParams = {
    var exitState:NextState;
    var ?fromGameplay:Bool; // makes it easier to do gameplay specific shit
}

class OptionsState extends FunkinState {
    public static var lastParams:OptionsStateParams = {
        exitState: null,
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
		lastParams = params;
    }

    override function create():Void {
        super.create();
        DiscordRPC.changePresence("Options Menu", null);

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_blue"));
        bg.screenCenter();
        bg.scrollFactor.set();
        add(bg);
        
        if(lastParams.fromGameplay == true) {
            // trick the game into not clearing assets on switch to gameplay
            // this SHOULD be okay because menus won't report playstate, and will clear assets anyways
            @:privateAccess
            InitState._lastState = PlayState;
        }
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