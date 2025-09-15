package funkin.ui;

import flixel.system.ui.FlxSoundTray;
import flixel.system.FlxAssets.FlxSoundAsset;

import flixel.util.FlxSignal.FlxTypedSignal;

#if SCRIPTING_ALLOWED    
import funkin.scripting.FunkinScript;
#end

class CustomSoundTray extends FlxSoundTray {
    public var volumeMaxSound:String;

    public var onCreate:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public var onUpdate:FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();
    public var onShowAnim:FlxTypedSignal<Float->Bool->Void> = new FlxTypedSignal<Float->Bool->Void>();
    public var onDestroy:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public function new() {
        super();
    }
    
    public function create():Void {
        removeChildren();
        volumeMaxSound = volumeUpSound;

        FlxG.sound.applySoundCurve = SoundTray.applySoundCurve;
        FlxG.sound.reverseSoundCurve = SoundTray.reverseSoundCurve;

        onCreate.dispatch();
    }

    override function update(MS:Float):Void {
        final elapsed:Float = Math.min(MS / 1000, FlxG.maxElapsed);
        onUpdate.dispatch(elapsed);
    }

    #if SCRIPTING_ALLOWED
    public function attachToScript(script:FunkinScript):Void {
        script.setParent(this);
        onCreate.add(() -> script.call("onCreate"));
        onUpdate.add((elapsed:Float) -> script.call("onUpdate", [elapsed]));
        onShowAnim.add((volume:Float, up:Bool) -> script.call("onShowAnim", [volume, up]));
        onDestroy.add(() -> script.call("onDestroy"));
    }
    #end

    public function saveVolume():Void {
        #if FLX_SAVE
        // Save sound preferences
        if(FlxG.save.isBound) {
            FlxG.save.data.mute = FlxG.sound.muted;
            FlxG.save.data.volume = FlxG.sound.volume;
            FlxG.save.flush();
        }
        #end
    }
    
    /**
     * Makes the little volume tray slide out.
     *
     * @param	up Whether the volume is increasing.
     */
    override function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME"):Void {
        onShowAnim.dispatch(volume, _up);
    }

    override function showIncrement():Void {
		final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
        _up = true;
		showAnim(volume, silent ? null : ((volume >= 1) ? volumeMaxSound : volumeUpSound));
	}
	
	override function showDecrement():Void {
		final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
        _up = false;
		showAnim(volume, silent ? null : volumeDownSound);
	}

    override function screenCenter():Void {
		x = (0.5 * (FlxG.stage.stageWidth - width) - FlxG.game.x);
	}

    public function destroy():Void {
        FlxG.sound.applySoundCurve = SoundTray.applySoundCurve;
        FlxG.sound.reverseSoundCurve = SoundTray.reverseSoundCurve;
        FlxG.sound.amountChange = 0.1;
        onDestroy.dispatch();
    }

    private var _up:Bool = false;
}