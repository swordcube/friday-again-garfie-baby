package funkin.gameplay.stage.props;

import flixel.util.FlxColor;

class BoxProp extends FlxSprite implements StageProp {
	public var stage:Stage;
    public var layer:FlxGroup;

    public function new(x:Float = 0, y:Float = 0, stage:Stage, layer:FlxGroup) {
        super(x, y);
        this.stage = stage;
        this.layer = layer;

        makeSolid(1, 1, FlxColor.WHITE);
    }

    public function applyProperties(properties:Dynamic):Void {
        var updateLeHitbox:Bool = false;
        for(field in Reflect.fields(properties)) {
            final value:Dynamic = Reflect.field(properties, field);
            switch(field.toLowerCase()) {
                case "color", "tint", "modulate":
                    if(value is String)
                        color = FlxColor.fromString(value);
                    else
                        color = value;

                case "position":
                    setPosition(value.x ?? 0.0, value.y ?? 0.0);
                
                case "offset":
                    offset.set(value.x ?? 1.0, value.y ?? 0.0);

                case "scroll":
                    scrollFactor.set(value.x ?? 1.0, value.y ?? 1.0);

                case "scale", "size":
                    scale.set(value.x ?? 1.0, value.y ?? value.x ?? 1.0);

                case "width":
                    scale.x = value;

                case "height":
                    scale.y = value;

                case "updatehitbox":
                    if(value == true)
                        updateLeHitbox = true;

                default:
                    Reflect.setProperty(this, field, value);
            }
        }
        if(updateLeHitbox)
            updateHitbox();
    }
}