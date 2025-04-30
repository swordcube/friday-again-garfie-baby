package funkin.states.menus.options;

import flixel.text.FlxText;
import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.ui.AtlasText;
import funkin.ui.options.*;

class OptionPage extends Page {
    public static final OPTION_HEIGHT:Float = 120;

    public var pageName:String;

    public var curSelected:Int = 0;
    public var grpOptions:FlxTypedContainer<Option>;

    public var descriptionBG:FlxSprite;
    public var descriptionText:FlxText;

    public var pageBG:FlxSprite;
    public var pageText:AtlasText;

    public var onExit:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public function new(pageName:String) {
        super();
        this.pageName = pageName;
    }

    override function create():Void {
        super.create();

        grpOptions = new FlxTypedContainer<Option>();
        add(grpOptions);

        initOptions();

        for(i => option in grpOptions)
            option.setPosition(0, 30 + (70 * i));

        descriptionBG = new FlxSprite().makeSolid(1, 1, FlxColor.BLACK);
        descriptionBG.alpha = 0.8;
        add(descriptionBG);

        descriptionText = new FlxText(0, 0, 0, "");
        descriptionText.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 2;
        add(descriptionText);

        pageBG = new FlxSprite().makeSolid(FlxG.width, 60, FlxColor.BLACK);
        pageBG.alpha = 0.8;
        add(pageBG);

        pageText = new AtlasText(0, 0, "bold", CENTER, pageName, 0.5);
        pageText.screenCenter(X);
        pageText.y = pageBG.y + ((pageBG.height - pageText.height) * 0.5);
        pageText.alpha = 0.6;
        add(pageText);

        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        final curOption:Option = grpOptions.members[curSelected];
        curOption.handleInputs();
        
        for(i => option in grpOptions.members) {
            var y:Float = ((FlxG.height - OPTION_HEIGHT) * 0.5) + ((i - curSelected) * OPTION_HEIGHT);
			option.y = FlxMath.lerp(option.y, y, FlxMath.getElapsedLerp(0.16, elapsed));
			option.x = -50 + (Math.abs(Math.cos((option.y + (OPTION_HEIGHT * 0.5) - (getDefaultCamera().scroll.y + (FlxG.height * 0.5))) / (FlxG.height * 1.25) * Math.PI)) * 150);
        }
        final wheel:Float = -FlxG.mouse.wheel;
        if(controls.justPressed.UI_UP || wheel < 0)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN || wheel > 0)
            changeSelection(1);

        if(controls.justPressed.BACK) {
            if(menu != null)
                menu.loadPage(new MainPage());

            onExit.dispatch();
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    /**
     * Initialize your options for this page
     * by overriding this function!
     */
    public function initOptions():Void {}

    public function addOption(data:OptionData):Void {
        final isGameplayModifier:Bool = data.isGameplayModifier ?? false;
        switch(data.type) {
            case TCheckbox:
                final o:CheckboxOption = new CheckboxOption(data.id, data.name, data.description, data.callback, isGameplayModifier);
                grpOptions.add(o);

            case TFloat(min, max, step, decimals):
                final o:NumberOption = new NumberOption(data.id, data.name, data.description, data.callback, isGameplayModifier, false);
                o.min = min;
                o.max = max;
                o.step = step;
                o.decimals = decimals ?? 0;
                grpOptions.add(o);

            case TInt(min, max, step):
                final o:NumberOption = new NumberOption(data.id, data.name, data.description, data.callback, isGameplayModifier, true);
                o.min = min;
                o.max = max;
                o.step = step;
                grpOptions.add(o);

            case TList(values):
                final o:ListOption = new ListOption(data.id, data.name, data.description, data.callback, isGameplayModifier, values);
                grpOptions.add(o);
        }
    }

    public function addGameplayModifier(data:OptionData):Void {
        data.isGameplayModifier = true;
        addOption(data);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;
        
        curSelected = FlxMath.wrap(curSelected + by, 0, grpOptions.length - 1);

        for(i => option in grpOptions.members)
            option.alpha = (curSelected == i) ? 1 : 0.6;

        descriptionText.text = grpOptions.members[curSelected].description;
        descriptionText.screenCenter(X);
        descriptionText.y = FlxG.height - (descriptionText.height + 50);

        descriptionBG.setGraphicSize(descriptionText.width + 20, descriptionText.height + 20);
        descriptionBG.updateHitbox();
        descriptionBG.screenCenter(X);
        descriptionBG.y = descriptionText.y - 10;

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
    var ?isGameplayModifier:Bool;
}