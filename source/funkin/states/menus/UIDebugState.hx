package funkin.states.menus;

import funkin.backend.Main;

import funkin.ui.*;
import funkin.ui.menubar.*;

class UIDebugState extends FunkinState {
    public var lastMouseVisible:Bool = false;

    override function create():Void {
        super.create();
        FlxG.camera.bgColor = FlxColor.GRAY;
        Main.statsDisplay.visible = false;

        #if (FLX_MOUSE && !mobile)
        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;
        #end
        final menuBar:MenuBar = new MenuBar(0, 0);
        menuBar.leftItems = [
            DropDown("File", [
                Button("Exit", [[UIUtil.correctModifierKey(CONTROL), Q]], () -> FlxG.switchState(MainMenuState.new))
            ])
        ];
        menuBar.zIndex = 1;
        add(menuBar);

        final checkbox:Checkbox = new Checkbox(10, menuBar.height + 10, "Testing checkbox");
        checkbox.callback = () -> trace('checkbox is ${(checkbox.checked) ? "on" : "off"}');
        add(checkbox);
    }

    override function destroy():Void {
        Main.statsDisplay.visible = Options.fpsCounter;
        #if (FLX_MOUSE && !mobile)
        FlxG.mouse.visible = lastMouseVisible;
        #end
        FlxG.camera.bgColor = FlxColor.BLACK;
        super.destroy();
    }
}