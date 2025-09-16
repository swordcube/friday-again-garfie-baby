package funkin.ui;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

import flixel.system.ui.FlxSoundTray;
import flixel.system.FlxAssets.FlxSoundAsset;

class SoundTray extends FlxSoundTray {
    public static final GRAPHIC_SCALE:Float = 0.3;

    public var barBitmapDatas:Map<Int, BitmapData> = [];

    public var trayContainer:Sprite;
    public var barDisplay:Bitmap;

    public var volumeMaxSound:String;

    public var lerpYPos:Float = 0;
    public var alphaTarget:Float = 0;

    private var _squashTimer:Float = 0;
    private var _shakeMult:Float = 0;

    public function new() {
        super();
        FlxG.signals.postStateSwitch.addOnce(create);
    }
    
    private function create():Void {
        removeChildren();

        trayContainer = new Sprite();
        addChild(trayContainer);

        final bg:Bitmap = new Bitmap(FlxG.assets.getBitmapData(Paths.image("ui/images/volume/volumebox")));
        bg.smoothing = true;
        bg.scaleX = bg.scaleY = GRAPHIC_SCALE;
        trayContainer.addChild(bg);

        final backingBar:Bitmap = new Bitmap(FlxG.assets.getBitmapData(Paths.image("ui/images/volume/bars_10")));
        backingBar.x = 9;
        backingBar.y = 5;
        backingBar.smoothing = true;
        backingBar.alpha = 0.4;
        backingBar.scaleX = backingBar.scaleY = GRAPHIC_SCALE;
        trayContainer.addChild(backingBar);

        barDisplay = new Bitmap(FlxG.assets.getBitmapData(Paths.image("ui/images/volume/bars_10")));
        barDisplay.x = 9;
        barDisplay.y = 5;
        barDisplay.smoothing = true;
        barDisplay.scaleX = barDisplay.scaleY = GRAPHIC_SCALE;
        trayContainer.addChild(barDisplay);

        _bars = [];
        for(i in 1...11)
            barBitmapDatas.set(i, FlxG.assets.getBitmapData(Paths.image("ui/images/volume/bars_" + i)));
        
        y = -88;
        visible = false;
        screenCenter();

        volumeUpSound = Paths.sound("ui/sfx/volume/up");
        volumeDownSound = Paths.sound("ui/sfx/volume/down");
        volumeMaxSound = Paths.sound("ui/sfx/volume/max");

        FlxG.sound.applySoundCurve = applySoundCurve;
        FlxG.sound.reverseSoundCurve = reverseSoundCurve;
        FlxG.sound.amountChange = 0.1;
    }

    public static function applySoundCurve(x:Float):Float {
        x = Math.max(0, Math.min(1, x));
        return Math.exp(Math.log(0.001) * (1 - x));
    }

    public static function reverseSoundCurve(x:Float):Float {
        x = Math.max(0, Math.min(1, x));
        return 1 - (Math.log(Math.max(x, 0.001)) / Math.log(0.001));
    }

    public function destroy():Void {
        for(bmp in barBitmapDatas) {
            @:privateAccess {
                if(bmp.__texture != null)
                    bmp.__texture.dispose();
            }
            bmp.disposeImage();
            bmp.dispose();
        }
        barBitmapDatas = null;
    }

    override function update(MS:Float):Void {
        MS = Math.min(MS, FlxG.maxElapsed * 1000);

        y = FlxMath.lerp(y, lerpYPos, Math.min(FlxMath.getElapsedLerp(0.1, MS / 1000), 1));
        if(Math.abs(y + -88) < 0.01)
            y = -88;

        alpha = FlxMath.lerp(alpha, alphaTarget, Math.min(FlxMath.getElapsedLerp(0.25, MS / 1000), 1));
    
        final shouldHide:Bool = (FlxG.sound.muted == false && FlxG.sound.volume > 0);
        if(_timer > 0) {
            if(shouldHide)
                _timer -= (MS / 1000);

            if(_shakeMult > 0) {
                trayContainer.x = FlxG.random.float(-2, 2) * _shakeMult;
                trayContainer.y = FlxG.random.float(-2, 2) * _shakeMult;

                _shakeMult -= (MS / 1000) * 3;
            }
            if(_squashTimer > 0) {
                _squashTimer -= (MS / 1000);
                if(_squashTimer <= 0) {
                    scaleX = scaleY = _defaultScale;
                    screenCenter();
                }
            }
            alphaTarget = 1;
        }
        else if(y > -88) {
            lerpYPos = -88;
            alphaTarget = 0;
            trayContainer.x = trayContainer.y = 0;
        }
        if(Math.floor(y) <= -88) {
            y = -88;

            visible = false;
            active = false;
    
            #if FLX_SAVE
            // Save sound preferences
            if(FlxG.save.isBound) {
                FlxG.save.data.mute = FlxG.sound.muted;
                FlxG.save.data.volume = FlxG.sound.volume;
                FlxG.save.flush();
            }
            #end
        }
    }
    
    /**
     * Makes the little volume tray slide out.
     *
     * @param	up Whether the volume is increasing.
     */
    override function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME"):Void {
        _timer = duration;
        lerpYPos = 10;

        visible = true;
        active = true;
        
        var globalVolume:Int = Math.round(FlxG.sound.volume * 10);
        if(FlxG.sound.muted || FlxG.sound.volume == 0)
            globalVolume = 0;
    
        if(!silent)
            FlxG.sound.play(sound);
        
        if(globalVolume != 0) {
            barDisplay.bitmapData = barBitmapDatas.get(globalVolume);
            barDisplay.visible = true;
        } else
            barDisplay.visible = false;
        
        if(globalVolume == 10)
            _shakeMult = 1;
        else {
            _squashTimer = (1 / 18);
            scaleX = _defaultScale * 1.035;
            scaleY = _defaultScale * 0.965;
            screenCenter();
        }
    }

    override function showIncrement():Void {
		final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
		showAnim(volume, silent ? null : ((volume >= 1) ? volumeMaxSound : volumeUpSound));
	}
	
	override function showDecrement():Void {
		final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
		showAnim(volume, silent ? null : volumeDownSound);
	}

    override function screenCenter():Void {
        if(trayContainer == null)
            return;
        
		x = (0.5 * (FlxG.stage.stageWidth - width) - FlxG.game.x);
	}
}