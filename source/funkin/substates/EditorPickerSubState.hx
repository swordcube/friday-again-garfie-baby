package funkin.substates;

import flixel.util.FlxTimer;
import funkin.ui.AtlasText;

import funkin.states.editors.*;
import funkin.states.TransitionableState;

import funkin.substates.transition.TransitionSubState;

class EditorPickerSubState extends FunkinSubState {
    public var bg:FlxSprite;

    public var curSelected:Int = 0;
    public var grpItems:FlxTypedContainer<AtlasText>;

    public var callbacks:Map<String, Void->Void> = [];

    override function create():Void {
        super.create();
        
        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        bg.color = 0xFF4CAF50;
        bg.screenCenter();
        bg.scrollFactor.set();
        add(bg);

        grpItems = new FlxTypedContainer<AtlasText>();
        add(grpItems);

        addItem("Chart Editor", () -> {
            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            TransitionSubState.nextCamera = transitionCam;
            FlxG.switchState(ChartEditor.new.bind({
                song: null,
                difficulty: null
            }));
        });
        addItem("Chart Converter", () -> {
            TransitionableState.skipNextTransIn = true;
            TransitionableState.skipNextTransOut = true;
            FlxG.switchState(ChartConverter.new);
        });
        addItem("Character Editor", () -> {
            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            TransitionSubState.nextCamera = transitionCam;
            FlxG.switchState(CharacterEditor.new);
        });
        call("onAddItems");
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        if(controls.justPressed.UI_UP)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN)
            changeSelection(1);

        if(controls.justPressed.BACK)
            exit();

        if(controls.justPressed.ACCEPT) {
            final callback:Void->Void = callbacks.get(grpItems.members[curSelected].text);
            if(callback != null) {
                FlxTimer.wait(0.001, callback);
                close();
            }
        }
        super.update(elapsed);
    }

    public function addItem(name:String, callback:Void->Void):Void {
        final item:AtlasText = new AtlasText(0, 90 * grpItems.length, "bold", LEFT, name);
        item.alpha = 0.6;
        item.screenCenter(X);
        item.scrollFactor.x = 0;
        grpItems.add(item);
        callbacks.set(name, callback);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = FlxMath.wrap(curSelected + by, 0, grpItems.length - 1);

        for(i in 0...grpItems.length) {
            if(curSelected == i) {
                grpItems.members[i].alpha = 1.0;
                camera.follow(grpItems.members[i], LOCKON, 0.16);
            } else
                grpItems.members[i].alpha = 0.6;
        }
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function exit():Void {
        close();
        FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}