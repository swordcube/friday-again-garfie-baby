package funkin.ui.options;

class PercentOption extends NumberOption {
    private var _initialized:Bool = false;

    public function new(id:String, name:String, description:String, callback:Dynamic->Option->Void, isGameplayModifier:Bool) {
        super(id, name, description, callback, isGameplayModifier);

        min = 0;
        max = 1;
        step = 0.01;
        decimals = 2;

        updateValue = (value:Dynamic) -> {
            if(_initialized)
                FlxG.sound.play(Paths.sound('editors/charter/sfx/hitsound'), cast value); // TODO: move the hitsound.ogg file somewhere else
            
            valueText.text = '${Math.floor(value * 100)}%';
            _initialized = true;
        };
        updateValue(value);
    }
}