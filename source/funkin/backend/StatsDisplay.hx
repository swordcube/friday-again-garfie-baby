package funkin.backend;

import lime.system.System;

import openfl.events.Event;
import openfl.display.Sprite;
import openfl.text.TextField;

import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;

import funkin.utilities.MemoryUtil;

using funkin.utilities.OpenFLUtil;

class StatsDisplay extends Sprite {
    public var currentFPS:Int = 0;

    public var mainFPSText:TextField;
    public var subFPSText:TextField;

    private var _framesPassed:Int = 0;
    private var _previousTime:Float = 0;
    private var _updateClock:Float = 999999;

    public function new(x:Float = 0, y:Float = 0) {
        super();

        this.x = x;
        this.y = y;
        
        mainFPSText = new TextField();
        mainFPSText.setupTextField(Paths.font("fonts/montserrat/semibold"), 16, FlxColor.WHITE, LEFT, "0");
        addChild(mainFPSText);

        subFPSText = new TextField();
        subFPSText.y = 4;
        subFPSText.setupTextField(Paths.font("fonts/montserrat/semibold"), 12, FlxColor.WHITE, LEFT, "FPS");
        addChild(subFPSText);

        visible = Options.fpsCounter;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    public function onEnterFrame(e:Event):Void {
        _framesPassed++;

        final deltaTime:Float = Math.abs(System.getTimerPrecise() - _previousTime);
        _updateClock += deltaTime;
        
        if(_updateClock >= 1000) {
            currentFPS = (FlxG.drawFramerate > 0) ? FlxMath.minInt(_framesPassed, FlxG.drawFramerate) : _framesPassed;
            mainFPSText.text = Std.string(currentFPS);
            subFPSText.x = mainFPSText.x + mainFPSText.width;
            
            _framesPassed = 0;
            _updateClock = 0;
        }
        _previousTime = System.getTimerPrecise();
    }
}