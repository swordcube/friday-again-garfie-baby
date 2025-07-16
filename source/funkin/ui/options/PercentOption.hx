package funkin.ui.options;

class PercentOption extends NumberOption {
    public function new(id:String, name:String, description:String, callback:Dynamic->Option->Void, isGameplayModifier:Bool) {
        super(id, name, description, callback, isGameplayModifier);

        min = 0;
        max = 1;
        step = 0.01;
        decimals = 2;

        updateValue = (value:Dynamic) -> {
            valueText.text = '${Math.floor(value * 100)}%';
        };
        updateValue(value);
    }
}