package funkin.gameplay;

import flixel.util.FlxTimer;
import flixel.util.FlxSignal;

import funkin.gameplay.UISkin;
import funkin.graphics.SkinnableUISprite;

import funkin.backend.events.Events;
import funkin.backend.events.CountdownEvents;

class Countdown extends FlxContainer {
    public var timer:FlxTimer;

    public var onStart:FlxTypedSignal<CountdownStartEvent->Void> = new FlxTypedSignal<CountdownStartEvent->Void>();
    public var onStartPost:FlxTypedSignal<CountdownStartEvent->Void> = new FlxTypedSignal<CountdownStartEvent->Void>();
    
    public var onStep:FlxTypedSignal<CountdownStepEvent->Void> = new FlxTypedSignal<CountdownStepEvent->Void>();
    public var onStepPost:FlxTypedSignal<CountdownStepEvent->Void> = new FlxTypedSignal<CountdownStepEvent->Void>();

    public function start(uiSkin:String, ?attachedConductor:Conductor):Void {
        if(attachedConductor == null)
            attachedConductor = Conductor.instance;
        
        final event:CountdownStartEvent = cast Events.get(COUNTDOWN_START);
        onStart.dispatch(event.recycle());
        
        if(event.cancelled)
            return;
        
        if(timer != null)
            timer.cancel();

        var json:UISkinData = UISkin.get(uiSkin);
        var counter:Int = 0;

        timer = FlxTimer.wait(attachedConductor.beatLength / 1000, () -> {
            final stepEvent:CountdownStepEvent = cast Events.get(COUNTDOWN_STEP);
            onStep.dispatch(stepEvent.recycle(counter, json.countdown.steps[counter].soundPath, null, null));
            
            final sprite:CountdownSprite = new CountdownSprite();
            sprite.loadSkin(uiSkin);
            sprite.step = json.countdown.steps[stepEvent.counter].name;
            sprite.visible = json.countdown.steps[stepEvent.counter].visible;
            sprite.screenCenter();
            add(sprite);
            
            stepEvent.tween = FlxTween.tween(sprite, {y: sprite.y + 20, alpha: 0}, attachedConductor.beatLength / 1000, {
                ease: FlxEase.cubeInOut,
                onComplete: (_) -> sprite.destroy()
            });
            stepEvent.sprite = sprite;

            var soundPath:String = Paths.sound('gameplay/uiskins/${uiSkin}/${stepEvent.soundPath}');
            if(!FlxG.assets.exists(soundPath))
                soundPath = Paths.sound('gameplay/uiskins/${Constants.DEFAULT_UI_SKIN}/${stepEvent.soundPath}');

            if(FlxG.assets.exists(soundPath))
                FlxG.sound.play(soundPath);

            onStepPost.dispatch(cast stepEvent.flagAsPost());
            counter++;
        });
        timer.loops = json.countdown.steps.length;

        onStartPost.dispatch(cast event.flagAsPost());
    }

    public function stop():Void {
        if(timer != null)
            timer.cancel();
    }
}

class CountdownSprite extends SkinnableUISprite {
    public var step(default, set):String;

    override function loadSkin(newSkin:String) {
        if(_skin == newSkin)
            return;

        final json:UISkinData = UISkin.get(newSkin);
        loadSkinComplex(newSkin, cast json.countdown, 'gameplay/uiskins/${newSkin}');
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_step(newStep:String):String {
        step = newStep;
        
        if(animation.exists(step))
            animation.play(step);
        
        updateHitbox();
        return step;
    }
}