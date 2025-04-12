package funkin.gameplay.stage.props;

import flixel.FlxObject;
import flixel.util.FlxDestroyUtil;

class ComboProp extends FlxObject implements StageProp {
	public var stage:Stage;
    public var layer:FlxGroup;

    public function new(x:Float = 0, y:Float = 0, stage:Stage, layer:FlxGroup) {
        super(x, y);

        this.stage = stage;
        this.layer = layer;

        kill();
    }

    public function applyProperties(properties:Dynamic):Void {
        for(field in Reflect.fields(properties)) {
            final value:Dynamic = Reflect.field(properties, field);
            switch(field.toLowerCase()) {
                case "position":
                    setPosition(value.x ?? (FlxG.width * 0.55), value.y ?? ((FlxG.height * 0.5) - 60));

                case "scroll":
                    scrollFactor.set(value.x ?? 1.0, value.y ?? 1.0);

                default:
            }
        }
    }

    override function destroy():Void {
        scrollFactor = FlxDestroyUtil.put(scrollFactor);
        super.destroy();
    }
}