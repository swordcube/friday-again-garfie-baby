package funkin.ui.charter;

import flixel.util.FlxTimer;

class CharterVisualMetronome extends FlxSpriteContainer {
    public var bg:FlxSprite;

    public var smallBars:FlxSpriteContainer;
    public var bigBars:FlxSpriteContainer;

    public var barTimers:Array<FlxTimer> = [];
    public var beatsPerMeasure(default, set):Int;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);

        bg = new FlxSprite(0, -14).loadGraphic(Paths.image("editors/charter/images/metronome/tray"));
        bg.scale.set(0.5, 0.5);
        bg.updateHitbox();
        add(bg);

        smallBars = new FlxSpriteContainer(0, 5);
        add(smallBars);

        bigBars = new FlxSpriteContainer(0, 5);
        add(bigBars);

        beatsPerMeasure = 4;
    }

    public function tick(?instant:Bool = false):Void {
        @:privateAccess
        final timingPoint:TimingPoint = Conductor.instance._latestTimingPoint;
        
        final barIndex:Int = FlxMath.wrap((beatsPerMeasure != 0) ? Math.floor(Conductor.instance.curDecBeat - timingPoint.beat) % beatsPerMeasure : 0, 0, bigBars.length - 1);
        bigBars.forEach((b) -> b.visible = false);

        final bigBar:FlxSprite = bigBars.members[barIndex];
        bigBar.scale.y = ((instant) ? 0.15 : 0.165) * (4 / beatsPerMeasure);
        bigBar.visible = true;

        if(!instant) {
            if(barTimers[barIndex] != null)
                barTimers[barIndex].cancel();
    
            barTimers[barIndex] = new FlxTimer().start(1 / 15, (_) -> bigBar.scale.y = 0.15 * (4 / beatsPerMeasure));
        }
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_beatsPerMeasure(newValue:Int):Int {
        if(beatsPerMeasure != newValue) {
            beatsPerMeasure = newValue;

            for(timer in barTimers) {
                if(timer != null)
                    timer.cancel();
            }
            barTimers = [for(_ in 0...newValue) null];

            for(bars in [smallBars, bigBars]) {
                bars.forEach((b) -> b.destroy());
                bars.clear();
            }
            barTimers.resize(newValue);
    
            smallBars.x = bg.x;
            bigBars.x = bg.x;
    
            final barScale:Float = 0.15 * (4 / newValue);
            for(i in 0...newValue) {
                final bigBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image("editors/charter/images/metronome/big_bar"));
                bigBar.scale.set(barScale, barScale);
                bigBar.updateHitbox();
                bigBar.visible = false;
                bigBar.x = i * bigBar.width;
                
                final smallBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image("editors/charter/images/metronome/small_bar"));
                smallBar.scale.set(barScale, barScale);
                smallBar.updateHitbox();
                smallBar.alpha = 0.45;
                smallBar.x = (i * bigBar.width) + ((bigBar.width - smallBar.width) * 0.5);
                smallBar.y = bigBar.y + (bigBar.height - smallBar.height) * 0.5;
    
                bigBars.add(bigBar);
                smallBars.add(smallBar);
            }
            smallBars.x += (bg.width - bigBars.width) * 0.5;
            bigBars.x += (bg.width - bigBars.width) * 0.5;

            bg.y = y - 14 + (54 * ((4 / beatsPerMeasure) - 1));
            tick();
        }
        return beatsPerMeasure;
    }
}