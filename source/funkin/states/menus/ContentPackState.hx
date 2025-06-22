package funkin.states.menus;

import thx.semver.Version;
import funkin.backend.ContentMetadata;
import flixel.text.FlxText;
import flixel.util.FlxSort;

import funkin.ui.AtlasText;
import funkin.substates.transition.TransitionSubState;

class ContentPackState extends FunkinState {
    public var bg:FlxSprite;
    public var curSelected:Int = 0;

    public var packCam:FlxCamera;
    public var packCamFollow:FlxObject;

    public var scrollBarBG:FlxSprite;
    public var scrollBar:FlxSprite;

    public var grpItems:FlxTypedContainer<ContentPackItem>;
    public var lastMouseVisible:Bool = false;

    public var descriptionBG:FlxSprite;
    public var descriptionText:FlxText;

    public var hintBG:FlxSprite;
    public var hintText:FlxText;

    public var grpWarnings:FlxTypedContainer<ContentPackWarning>;

    override function create():Void {
        final transitionCam:FlxCamera = new FlxCamera();
        transitionCam.bgColor = 0;
        FlxG.cameras.add(transitionCam, false);

        TransitionSubState.nextCamera = transitionCam;
        super.create();

        DiscordRPC.changePresence("Managing Content Packs", null);
        persistentUpdate = true;

        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_blue"));
        bg.screenCenter();
        bg.scrollFactor.set();
        add(bg);

        packCamFollow = new FlxObject(0, 0, 1, 1);
        add(packCamFollow);

        packCam = new FlxCamera(20, 20, Std.int(FlxG.width * 0.4), Std.int(FlxG.height - 40 - 70));
        packCam.bgColor = FlxColor.BLACK;
        packCam.bgColor.alphaFloat = 0.6;
        packCam.follow(packCamFollow, LOCKON, 0.16);
        packCam.deadzone.set(0, 0, packCam.width, packCam.height - 40);
        packCam.minScrollY = 0;
        FlxG.cameras.insert(packCam, 1, false);

        grpItems = new FlxTypedContainer<ContentPackItem>();
        grpItems.cameras = [packCam];
        add(grpItems);

        scrollBarBG = new FlxSprite(packCam.width, 0).makeSolid(2, packCam.height, FlxColor.WHITE);
        scrollBarBG.alpha = 0.25;
        scrollBarBG.x -= scrollBarBG.width;
        scrollBarBG.cameras = [packCam];
        scrollBarBG.scrollFactor.set();
        add(scrollBarBG);

        scrollBar = new FlxSprite(scrollBarBG.x, scrollBarBG.y).makeSolid(scrollBarBG.width, scrollBarBG.height, FlxColor.WHITE);
        scrollBar.cameras = [packCam];
        scrollBar.scrollFactor.set();
        add(scrollBar);

        descriptionBG = new FlxSprite(packCam.x + packCam.width + 20, packCam.y);
        descriptionBG.makeSolid(FlxG.width - descriptionBG.x - 20, FlxG.height - 40, FlxColor.BLACK);
        descriptionBG.alpha = 0.6;
        add(descriptionBG);

        descriptionText = new FlxText(descriptionBG.x + 10, descriptionBG.y + 10, descriptionBG.width - 20, "asdlkadslkjasdlkjasdjlkasdlkjasdaljskdalskjdadlkjadkljdalkjadkljadasdlkadslkjasdlkjasdjlkasdlkjasdaljskdalskjdadlkjadkljdalkjadkljadasdlkadslkjasdlkjasdjlkasdlkjasdaljskdalskjdadlkjadkljdalkjadkljad");
        descriptionText.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 2;
        add(descriptionText);

        hintBG = new FlxSprite(packCam.x, packCam.y + packCam.height + 20).makeSolid(packCam.width, 50, FlxColor.BLACK);
        hintBG.alpha = 0.6;
        add(hintBG);

        hintText = new FlxText(hintBG.x, hintBG.y, 0, 'Press ACCEPT to toggle the pack on/off');
        hintText.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        hintText.borderSize = 2;
        hintText.x = hintBG.x + ((hintBG.width - hintText.width) * 0.5);
        hintText.y += (hintBG.height - hintText.height) * 0.5;
        add(hintText);

        grpWarnings = new FlxTypedContainer<ContentPackWarning>();
        add(grpWarnings);

        final packs:Array<String> = cast Options.contentPackOrder;
        // for(i in 0...30)
        //     packs.push("base-game");

        for(i in 0...packs.length) {
            final item:ContentPackItem = new ContentPackItem(0, i * 40, packCam.width, packs[i]);
            item.menu = this;
            item.onClick = () -> {
                curSelected = grpItems.members.indexOf(item);
                changeSelection(0, true);
            };
            item.unselect();
            grpItems.add(item);
        }
        scrollBar.setGraphicSize(scrollBarBG.width, FlxMath.bound(scrollBarBG.height * Math.min(scrollBarBG.height / (grpItems.length * 40), 1), 30, scrollBarBG.height));
        scrollBar.updateHitbox();
        
        scrollBarBG.visible = scrollBar.visible = grpItems.length * 40 > packCam.height;
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        final percent:Float = FlxMath.bound(packCam.scroll.y / ((grpItems.length * 40) - packCam.height), 0, 1);
        scrollBar.y = FlxMath.lerp(scrollBarBG.y, scrollBarBG.y + scrollBarBG.height - scrollBar.height, percent);

        final wheel:Float = -FlxG.mouse.wheel;
        if(controls.justPressed.UI_UP || wheel < 0) {
            if(FlxG.keys.pressed.SHIFT)
                moveItem(true);
            else
                changeSelection(-1);
        }
        if(controls.justPressed.UI_DOWN || wheel > 0) {
            if(FlxG.keys.pressed.SHIFT)
                moveItem(false);
            else
                changeSelection(1);
        }
        if(controls.justPressed.ACCEPT) {
            final item:ContentPackItem = grpItems.members[curSelected];
            item.check.loadGraphic(Paths.image('menus/content_manager/${(Options.toggledContentPacks.get(item.contentPack)) ? "cross" : "check"}'));
            item.check.setGraphicSize(20, 20);
            item.check.updateHitbox();
            Options.toggledContentPacks.set(item.contentPack, !Options.toggledContentPacks.get(item.contentPack));
        }
        if(controls.justPressed.BACK) {
            final packs:Array<String> = cast Options.contentPackOrder;
            packs.clear();

            for(item in grpItems)
                packs.push(item.contentPack);

            Options.contentPackOrder = packs.removeDuplicates();
            Options.save();

            Paths.reloadContent();
            GlobalScript.reloadScripts();
            
            FlxG.signals.preStateCreate.addOnce((_) -> {
                Cache.clearAll();
            });
            persistentUpdate = false;
            FlxG.switchState(MainMenuState.new);
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    public function showWarning(text:String):Void {
        final warning:ContentPackWarning = new ContentPackWarning(0, 0, descriptionBG.width, text);
        grpWarnings.add(warning);

        var totalHeight:Float = 0;
        for(warning in grpWarnings.members)
            totalHeight += warning.height;

        warning.setPosition(descriptionBG.x, (descriptionBG.y + descriptionBG.height) - totalHeight);
    }

    public function moveItem(up:Bool):Void {
        final curItem:ContentPackItem = grpItems.members[curSelected];
        curItem.y += 40.5 * ((up) ? -1 : 1);
        grpItems.sort(ContentPackItem.sortByY, FlxSort.ASCENDING);

        for(i => item in grpItems.members)
            item.y = i * 40;

        curSelected = grpItems.members.indexOf(curItem);
        changeSelection(0, true);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        final prevSelected:Int = curSelected;
        curSelected = FlxMath.boundInt(curSelected + by, 0, grpItems.length - 1);

        if(curSelected == prevSelected && !force)
            return;

        while(grpWarnings.length > 0) {
            final warning:ContentPackWarning = grpWarnings.members.unsafeFirst();
            grpWarnings.remove(warning, true);
            warning.destroy();
        }
        final metadata:Null<ContentMetadata> = Paths.contentMetadata.get(grpItems.members[curSelected].contentPack);
        if((metadata?.allowUnsafeScripts ?? false))
            showWarning("This content pack may contain unsafe scripts!");

        final contentAPIVersion:Version = Version.stringToVersion(metadata?.apiVersion ?? FlxG.stage.application.meta.get("version"));
        final currentAPIVersion:Version = Version.stringToVersion(FlxG.stage.application.meta.get("version"));
        if(currentAPIVersion != contentAPIVersion)
            showWarning('This content pack may be incompatible with\nyour current game version (${currentAPIVersion})!');

        for(i => item in grpItems.members) {
            if(curSelected == i)
                item.select();
            else
                item.unselect();
        }
        packCamFollow.y = grpItems.members[curSelected].y;
        descriptionText.text = metadata?.description ?? "This content pack has no description.";
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    override function destroy():Void {
        FlxG.mouse.visible = lastMouseVisible;
        super.destroy();
    }
}

class ContentPackItem extends FlxSpriteContainer {
    public var menu:ContentPackState;

    public var contentPack:String;
    public var bg:FlxSprite;

    public var icon:FlxSprite;
    public var check:FlxSprite;
    public var title:AtlasText;

    public var canDrag:Bool = false;
    public var dragging:Bool = false;
    public var onClick:Void->Void;

    public function new(x:Float = 0, y:Float = 0, width:Float, contentPack:String) {
        super(x, y);
        this.contentPack = contentPack;

        bg = new FlxSprite().makeSolid(width, 40, FlxColor.BLACK);
        bg.alpha = 0.0;
        add(bg);

        final iconPath:String = Paths.image("icon", contentPack, false);
        icon = new FlxSprite(5, 5).loadGraphic((FlxG.assets.exists(iconPath)) ? iconPath : Paths.image("menus/missing_content_pack"));
        icon.setGraphicSize(30, 30);
        icon.updateHitbox();
        add(icon);

        check = new FlxSprite(icon.x + (icon.width * 0.7), 0).loadGraphic(Paths.image('menus/content_manager/${(Options.toggledContentPacks.get(contentPack)) ? "check" : "cross"}'));
        check.setGraphicSize(20, 20);
        check.updateHitbox();
        add(check);

        var maxTitleLength:Int = 26;
        var titleStr:String = Paths.contentMetadata.get(contentPack)?.title ?? contentPack;
        
        if(titleStr.length > maxTitleLength)
            titleStr = titleStr.substr(0, maxTitleLength - 3) + "...";

        title = new AtlasText(icon.x + icon.width + 10, 0, "bold", LEFT, titleStr, 0.35);
        title.y = (bg.height - title.height) * 0.5;
        add(title);
    }

    public function select():Void {
        icon.alpha = 1;
        title.alpha = 1;
    }

    public function unselect():Void {
        icon.alpha = 0.6;
        title.alpha = 0.6;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        final hovered:Bool = FlxG.mouse.overlaps(bg, getDefaultCamera());
        if(hovered && FlxG.mouse.justPressed) {
            canDrag = true;
            if(onClick != null)
                onClick();
        }
        if(FlxG.mouse.justReleased) {
            menu.grpItems.sort(sortByY, FlxSort.ASCENDING);
            for(i => item in menu.grpItems.members)
                item.y = i * 40;

            if(dragging)
                menu.curSelected = menu.grpItems.members.indexOf(this);

            canDrag = false;
            dragging = false;
        }
        if(canDrag && !dragging && FlxG.mouse.justMoved) {
            dragging = true;

            _lastY = y;
            _lastMouseY = FlxG.mouse.y;  
        }
        if(dragging && FlxG.mouse.justMoved) {
            final newY:Float = _lastY + (FlxG.mouse.y - _lastMouseY);
            y = newY;

            menu.grpItems.sort(sortByY, FlxSort.ASCENDING);
            for(i => item in menu.grpItems.members) {
                if(item == this)
                    continue;

                item.y = i * 40;
            }
        }
        bg.alpha = FlxMath.lerp(bg.alpha, (hovered) ? ((FlxG.mouse.pressed) ? 0.6 : 0.4) : 0.0, FlxMath.getElapsedLerp(0.25, elapsed));
    }

    public static inline function sortByY(Order:Int, Obj1:FlxObject, Obj2:FlxObject):Int {
		return FlxSort.byValues(Order, Obj1.y + Obj1.height, Obj2.y + Obj2.height);
	}

    private var _lastY:Float = 0;
    private var _lastMouseY:Float = 0;
}

class ContentPackWarning extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var icon:FlxSprite;
    public var title:FlxText;

    public function new(x:Float = 0, y:Float = 0, width:Float, warning:String) {
        super(x, y);

        bg = new FlxSprite().makeSolid(width, 40, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        icon = new FlxSprite(5, 5).loadGraphic(Paths.image("menus/content_manager/warning"));
        icon.setGraphicSize(30, 30);
        icon.updateHitbox();
        add(icon);

        title = new FlxText(icon.x + icon.width + 10, 0, warning);
        title.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        title.borderSize = 2;
        title.y = (bg.height - 22) * 0.5;
        add(title);

        if((title.y + title.height) > bg.height) {
            bg.setGraphicSize(bg.width, title.height + 20);
            bg.updateHitbox();
        }
    }
}