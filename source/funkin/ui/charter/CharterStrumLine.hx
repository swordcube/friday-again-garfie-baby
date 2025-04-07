package funkin.ui.charter;

import funkin.states.editors.ChartEditor;

class CharterStrumLine extends FlxSpriteContainer {
    /**
     * The number of strums to display.
     * 
     * Make sure to set `directionList` before
     * setting this value!
     */
    public var keyCount(default, set):Int;
    public var directionList:Array<String>;

    public var strumGlowTimers:Array<Float> = [];

    public function new(x:Float = 0, y:Float = 0, ?keyCount:Int) {
        super(x, y);
        if(keyCount == null)
            keyCount = Constants.KEY_COUNT;

        directionList = Constants.NOTE_DIRECTIONS;
        this.keyCount = keyCount;

        scrollFactor.set(0, 0);
    }

    public function glowStrum(index:Int, duration:Float):Void {
        final strum:FlxSprite = members[index];
        strum.animation.play("confirm");
        strum.centerOrigin();
        strum.centerOffsets();

        strumGlowTimers[index] = duration;
    }
    
    public function resetStrum(index:Int):Void {
        final strum:FlxSprite = members[index];
        strum.animation.play("static");
        strum.centerOrigin();
        strum.centerOffsets();
        
        strumGlowTimers[index] = Math.POSITIVE_INFINITY;
    }

    public function resetAllStrums():Void {
        for(i in 0...keyCount)
            resetStrum(i);
    }

    override function update(elapsed:Float):Void {
        final rate:Float = Conductor.instance.rate;
        for(i in 0...keyCount) {
            strumGlowTimers[i] -= elapsed * 1000 * rate;
            if(strumGlowTimers[i] <= 0)
                resetStrum(i);
        }
        super.update(elapsed);
    }
    
    //----------- [ Private API ] -----------//
    
    @:noCompletion
    private function set_keyCount(newKeyCount:Int):Int {
        while(length > 0) {
            final first:FlxSprite = members.unsafeFirst();
            first.destroy();
            remove(first, true);
        }
        strumGlowTimers = [];

        for(i in 0...newKeyCount) {
            final strum:FlxSprite = new FlxSprite(i * ChartEditor.CELL_SIZE);
            strum.frames = Paths.getSparrowAtlas("editors/charter/images/strums");
            strum.animation.addByPrefix("static", '${directionList[i]} static', 24, false);
            strum.animation.addByPrefix("confirm", '${directionList[i]} confirm', 24, false);
            strum.animation.play("static");

            if(strum.width > strum.height)
                strum.setGraphicSize(ChartEditor.CELL_SIZE, 0);
            else
                strum.setGraphicSize(0, ChartEditor.CELL_SIZE);

            strum.updateHitbox();
            strum.scrollFactor.set(0, 0);
            add(strum);

            strumGlowTimers.push(Math.POSITIVE_INFINITY);
        }
        return keyCount = newKeyCount;
    }
}