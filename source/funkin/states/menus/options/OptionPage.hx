package funkin.states.menus.options;

import funkin.ui.AtlasText;
import funkin.ui.options.*;

class OptionPage extends Page {
    public static final OPTION_HEIGHT:Float = 120;

    public var curSelected:Int = 0;
    public var grpOptions:FlxTypedContainer<Option>;

    override function create():Void {
        super.create();

        grpOptions = new FlxTypedContainer<Option>();
        add(grpOptions);

        initOptions();

        for(i => option in grpOptions)
            option.setPosition(0, 30 + (70 * i));

        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        final curOption:Option = grpOptions.members[curSelected];
        curOption.handleInputs();
        
        for(i => option in grpOptions.members) {
            var y:Float = ((FlxG.height - OPTION_HEIGHT) * 0.5) + ((i - curSelected) * OPTION_HEIGHT);
			option.y = FlxMath.lerp(option.y, y, FlxMath.getElapsedLerp(0.16, elapsed));
			option.x = -50 + (Math.abs(Math.cos((option.y + (OPTION_HEIGHT * 0.5) - (FlxG.camera.scroll.y + (FlxG.height * 0.5))) / (FlxG.height * 1.25) * Math.PI)) * 150);
        }
        if(controls.justPressed.UI_UP)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN)
            changeSelection(1);

        if(controls.justPressed.BACK) {
            menu.loadPage(new MainPage());
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    /**
     * Initialize your options for this page
     * by overriding this function!
     */
    public function initOptions():Void {}

    public function addOption(data:OptionData):Void {
        switch(data.type) {
            case TCheckbox:
                final o:CheckboxOption = new CheckboxOption(data.id, data.name, data.callback);
                grpOptions.add(o);

            case TFloat(min, max, step, decimals):
                final o:NumberOption = new NumberOption(data.id, data.name, data.callback, false);
                o.min = min;
                o.max = max;
                o.step = step;
                o.decimals = decimals ?? 0;
                grpOptions.add(o);

            case TInt(min, max, step):
                final o:NumberOption = new NumberOption(data.id, data.name, data.callback, true);
                o.min = min;
                o.max = max;
                o.step = step;
                grpOptions.add(o);

            case TList(values):
                final o:ListOption = new ListOption(data.id, data.name, data.callback, values);
                grpOptions.add(o);
        }
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;
        
        curSelected = FlxMath.wrap(curSelected + by, 0, grpOptions.length - 1);

        for(i => option in grpOptions.members)
            option.alpha = (curSelected == i) ? 1 : 0.6;

        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }
}

enum OptionType {
    TCheckbox;
    TFloat(min:Float, max:Float, step:Float, ?decimals:Int);
    TInt(min:Int, max:Int, step:Int);
    TList(values:Array<String>);
}

typedef OptionData = {
    var name:String;
    var description:String;
    
    var id:String;
    var type:OptionType;

    var ?callback:Dynamic->Void;
}