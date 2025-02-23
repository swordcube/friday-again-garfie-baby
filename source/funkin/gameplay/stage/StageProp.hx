package funkin.gameplay.stage;

interface StageProp {
    public var stage:Stage;   
    public var layer:FlxGroup; 

    public function applyProperties(properties:Dynamic):Void;
}