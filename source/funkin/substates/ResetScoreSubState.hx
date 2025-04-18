package funkin.substates;

import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.ui.AtlasText;

class ResetScoreSubState extends FunkinSubState {
    public var bg:FlxSprite;
    public var warnText:AtlasText;

    public var yesText:AtlasText;
    public var noText:AtlasText;

    public var resetStr:String;
    public var selectedYes:Bool = false;

    public var onAccept:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>(); 
    public var onCancel:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>(); 

    public function new(resetStr:String) {
        super();
        this.resetStr = resetStr;
    }

    override function create():Void {
        super.create();

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        bg = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, FlxColor.BLACK);
		bg.alpha = 0;
		bg.screenCenter();
		add(bg);

        warnText = new AtlasText(0, 0, "bold", CENTER, 'Reset the score of\n${resetStr}?');
        warnText.screenCenter();
        warnText.y -= 100;
        add(warnText);

        yesText = new AtlasText(0, 0, "bold", CENTER, "Yes");
        yesText.screenCenter();
        yesText.x -= 100;
        yesText.y += 100;
        yesText.alpha = 1;
        add(yesText);
        
        noText = new AtlasText(0, 0, "bold", CENTER, "No");
        noText.screenCenter();
        noText.x += 100;
        noText.y += 100;
        noText.alpha = 0.6;
        add(noText);

        changeSelection();
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT)
            changeSelection();

        if(controls.justPressed.ACCEPT) {
            if(selectedYes)
                onAccept.dispatch();
            else
                onCancel.dispatch();

            close();
        }
    }

    public function changeSelection():Void {
        selectedYes = !selectedYes;

        final yesIndex:Int = (selectedYes) ? 0 : 1;
        for(i => text in [yesText, noText])
            text.alpha = (yesIndex == i) ? 1 : 0.6;

        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}