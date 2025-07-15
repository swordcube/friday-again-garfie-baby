package funkin.states.menus;

import flixel.text.FlxText;
import funkin.ui.AtlasText;

import funkin.ui.credits.*;
import funkin.ui.credits.CreditsData;

// TODO: display the roles for each entry Somewhere

class CreditsState extends FunkinState {
    public static final ENTRY_HEIGHT:Float = 120;

    public var categories:Array<CreditCategoryData> = [];

    public var bg:FlxSprite;
    public var grpEntries:FlxTypedContainer<CreditEntry>;

    public var descriptionBG:FlxSprite;
    public var descriptionText:FlxText;

    public var pageBG:FlxSprite;
    public var categoryText:AtlasText;

    public var leftArrow:AtlasText;
    public var rightArrow:AtlasText;

    public var curCategory:Int = 0;
    public var curSelected:Int = 0;

    public var colorTween:FlxTween;

    override function create():Void {
        super.create();
        DiscordRPC.changePresence("Credits Menu", null);
        persistentUpdate = true;

        final contentPacks:Array<String> = Paths.getEnabledContentPacks();
        contentPacks.push("default"); // engine credits always go last

        for(contentPack in contentPacks) {
            if(!FlxG.assets.exists(Paths.json("credits", contentPack, false)))
                continue;

            final config:CreditsData = CreditsData.load(contentPack);
            for(category in config.categories)
                categories.push(category);
        }
        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        bg.screenCenter();
        bg.scrollFactor.set();
        bg.color = FlxColor.WHITE;
        add(bg);

        grpEntries = new FlxTypedContainer<CreditEntry>();
        add(grpEntries);

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

        categoryText = new AtlasText(0, 0, "bold", CENTER, "?", 0.5);
        categoryText.screenCenter(X);
        categoryText.y = pageBG.y + ((pageBG.height - categoryText.height) * 0.5);
        categoryText.alpha = 0.6;
        add(categoryText);

        leftArrow = new AtlasText(0, categoryText.y, "bold", RIGHT, "<", 0.5);
        leftArrow.y = pageBG.y + ((pageBG.height - leftArrow.height) * 0.5);
        leftArrow.alpha = 0.6;
        add(leftArrow);

        rightArrow = new AtlasText(0, categoryText.y, "bold", LEFT, ">", 0.5);
        rightArrow.screenCenter(X);
        rightArrow.y = pageBG.y + ((pageBG.height - rightArrow.height) * 0.5);
        rightArrow.alpha = 0.6;
        add(rightArrow);

        changeCategory(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        for(i => entry in grpEntries.members) {
            var y:Float = ((FlxG.height - ENTRY_HEIGHT) * 0.5) + ((i - curSelected) * ENTRY_HEIGHT);
            entry.y = FlxMath.lerp(entry.y, y, FlxMath.getElapsedLerp(0.16, elapsed));
            entry.x = -50 + (Math.abs(Math.cos((entry.y + (ENTRY_HEIGHT * 0.5) - (getDefaultCamera().scroll.y + (FlxG.height * 0.5))) / (FlxG.height * 1.25) * Math.PI)) * 150);
        }
        final wheel:Float = -FlxG.mouse.wheel;
        if(controls.justPressed.UI_UP || wheel < 0)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN || wheel > 0)
            changeSelection(1);

        if(controls.justPressed.UI_LEFT)
            changeCategory(-1);

        if(controls.justPressed.UI_RIGHT)
            changeCategory(1);

        if(controls.justPressed.ACCEPT) {
            final category:CreditCategoryData = categories[curCategory];
            CoolUtil.openURL(category.items[curSelected].url);
        }
        if(controls.justPressed.BACK) {
            FlxG.switchState(MainMenuState.new);
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    public function changeCategory(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;
        
        curCategory = FlxMath.wrap(curCategory + by, 0, categories.length - 1);
        
        final category:CreditCategoryData = categories[curCategory];
        categoryText.text = category.name;
        categoryText.screenCenter(X);

        leftArrow.x = categoryText.x - (leftArrow.width + 10);
        leftArrow.visible = curCategory > 0;
        
        rightArrow.x = categoryText.x + (categoryText.width + 10);
        rightArrow.visible = curCategory < categories.length - 1;

        regenEntries();

        curSelected = 0;
        changeSelection(0, true);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        final category:CreditCategoryData = categories[curCategory];
        curSelected = FlxMath.wrap(curSelected + by, 0, grpEntries.length - 1);

        for(i => option in grpEntries.members)
            option.alpha = (curSelected == i) ? 1 : 0.6;

        descriptionText.text = category.items[curSelected].description;
        descriptionText.screenCenter(X);
        descriptionText.y = FlxG.height - (descriptionText.height + 50);

        descriptionBG.setGraphicSize(descriptionText.width + 20, descriptionText.height + 20);
        descriptionBG.updateHitbox();
        descriptionBG.screenCenter(X);
        descriptionBG.y = descriptionText.y - 10;

        if(colorTween != null)
            colorTween.cancel();

        colorTween = FlxTween.color(bg, 1, bg.color, FlxColor.fromString(category.items[curSelected].color), {ease: FlxEase.expoOut, onComplete: (_) -> {
            colorTween = null;
        }});
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function regenEntries():Void {
        while(grpEntries.length > 0) {
            final entry:CreditEntry = grpEntries.members.unsafeFirst();
            grpEntries.remove(entry, true);
            entry.destroy();
        }
        final category:CreditCategoryData = categories[curCategory];
        for(item in category.items) {
            final entry:CreditEntry = new CreditEntry(0, 0, item.name, item.icon);
            grpEntries.add(entry);
        }
        for(i => entry in grpEntries)
            entry.setPosition(0, 30 + (70 * i));
    }
}