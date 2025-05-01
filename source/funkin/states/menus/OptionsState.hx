package funkin.states.menus;

import funkin.ui.options.pages.*;

class OptionsState extends FunkinState {
    public var bg:FlxSprite;
    public var currentPage:Page;

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