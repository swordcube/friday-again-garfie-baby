package funkin.gameplay.stage.props;

import flixel.util.FlxColor;

class SpriteProp extends FlxSprite implements StageProp {
	public var stage:Stage;
    public var layer:FlxGroup;

    public function new(x:Float = 0, y:Float = 0, stage:Stage, layer:FlxGroup) {
        super(x, y);
        this.stage = stage;
        this.layer = layer;
    }

    public function applyProperties(properties:Dynamic):Void {
        for(field in Reflect.fields(properties)) {
            final value:Dynamic = Reflect.field(properties, field);
            switch(field.toLowerCase()) {
                case "texture":
                    final gridSize:Dynamic = value.gridSize;
                    if(gridSize != null)
                        loadGraphic(Paths.image('${stage.data.getImageFolder()}/${value}'), true, gridSize.x ?? 0, gridSize.y ?? gridSize.x ?? 0);
                    else    
                        loadGraphic(Paths.image('${stage.data.getImageFolder()}/${value}'));

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

                case "scale":
                    scale.set(value.x ?? 1.0, value.y ?? value.x ?? 1.0);

                case "updatehitbox":
                    if(value == true)
                        updateHitbox();

                default:
                    Reflect.setProperty(this, field, value);
            }
        }
    }
}