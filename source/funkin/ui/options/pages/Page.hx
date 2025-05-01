package funkin.ui.options.pages;

import funkin.states.menus.OptionsState;

class Page extends FlxContainer {
    public var menu:OptionsState;
    public var controls(get, never):Controls;

    public function create():Void {}
    public function createPost():Void {}

    @:noCompletion
    private inline function get_controls():Controls {
        return Controls.instance;
    }
}