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
        
        var fontPath = Paths.font("fonts/montserrat/semibold");
        var font = FlxG.assets.getFont(fontPath);
        
        if(font == null && OpenFLAssets.exists(fontPath, FONT))
            font = OpenFLAssets.getFont(fontPath);
        
        mainFPSText = new TextField();
        mainFPSText.setupTextField(font?.fontName ?? fontPath, 16, FlxColor.WHITE, LEFT, "0");
        mainFPSText.selectable = false;
        addChild(mainFPSText);
        
        subFPSText = new TextField();
        subFPSText.y = 4;
        subFPSText.setupTextField(font?.fontName ?? fontPath, 12, FlxColor.WHITE, LEFT, "FPS");
        subFPSText.selectable = false;
        addChild(subFPSText);

        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    public function onEnterFrame(e:Event):Void {
        _framesPassed++;

        final deltaTime:Float = Math.max(System.getTimerPrecise() - _previousTime, 0);
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