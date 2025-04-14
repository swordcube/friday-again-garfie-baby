package funkin.substates;

class EditorPickerSubState extends FunkinSubState {
    public var bg:FlxSprite;

    override function create():Void {
        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        bg.color = 0xFF4CAF50;
        bg.screenCenter();
        add(bg);
        
        super.create();
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}