package funkin.ui;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import lime.system.System;

import openfl.geom.Rectangle;
import openfl.desktop.Clipboard;

import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;

// TODO: add multiline functionality

class Textbox extends UIComponent {
    public var bg:SliceSprite;
    public var label:FlxText;
    public var caret:FlxSprite;

    public var text(get, set):String;
    public var typing(default, set):Bool = false;

    public var autoSize:Bool = false;
    public var callback:String->Void;

    public var position:Int = 0;
    public var maxCharacters:Int = 0;

    public var restrictChars:String = "";

    public function new(x:Float = 0, y:Float = 0, text:String, ?autoSize:Bool = false, ?width:Float = 100, ?height:Float = 22, ?callback:String->Void = null) {
        super(x, y);
        cursorType = TEXT;

        bg = new SliceSprite(0, 0);
        bg.loadGraphic(Paths.image("ui/images/panel"));
        add(bg);

        label = new FlxText(8, 0, 0, text);
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        add(label);

        caret = new FlxSprite(8, 1).makeSolid(1, 18);
        add(caret);

        position = text?.length ?? 0;

        this.callback = callback;
        this.autoSize = autoSize;

        this.width = width;
        this.height = height;

        this.text = text;

        FlxG.stage.window.onKeyDown.add(_onKeyDown);
        FlxG.stage.window.onTextInput.add(_onTextInput);
        FlxG.stage.window.onTextEdit.add(_onTextEdit);
    }

    override function update(elapsed:Float) {
        caret.x = label.x + label.width;
        caret.alpha = (typing) ? Math.abs(Math.sin((System.getTimerPrecise() / 1000) * 2)) : 0;

        if(checkMouseOverlap()) {
            if(FlxG.mouse.justPressed) {
                typing = true;
                
                var pos = FlxG.mouse.getScreenPosition(getDefaultCamera());
                pos.x -= label.x;
                pos.y -= label.y;

                if (pos.x < 0)
                    position = 0;
                else {
                    var index = label.textField.getCharIndexAtPoint(pos.x, pos.y);
                    if (index > -1)
                        position = index;
                    else
                        position = label.text.length;
                }
                pos.put();
            }
        }
        else {
            if(FlxG.mouse.justReleased && typing) {
                if(callback != null)
                    callback(label.text);

                typing = false;
            }
        }
        if(typing) {
            var curPos = switch(position) {
                case 0:
                    FlxPoint.get(0, 0);
                default:
                    if (position >= label.text.length) {
                        @:privateAccess
                        label.textField.__getCharBoundaries(label.text.length - 1, _cacheRect);
                        FlxPoint.get(_cacheRect.x + _cacheRect.width, _cacheRect.y);
                    }
                    else {
                        @:privateAccess
                        label.textField.__getCharBoundaries(position, _cacheRect);
                        FlxPoint.get(_cacheRect.x, _cacheRect.y);
                    }
            };
            caret.x = x + curPos.x + 8;
            curPos.put();
        }
        super.update(elapsed);
    }

    override function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final ret:Bool = FlxG.mouse.overlaps(bg, getDefaultCamera()) && UIUtil.allDropDowns.length == 0;
        _checkingMouseOverlap = false;
        return ret;
    }

    public function changeSelection(change:Int):Void {
		position = FlxMath.wrap(position + change, 0, label.text.length);
	}

    //----------- [ Private API ] -----------//

    private var _hovered:Bool = false;
    private var _cacheRect:Rectangle = new Rectangle();

    private function _onKeyDown(key:KeyCode, mod:KeyModifier):Void {
        if(!typing)
            return;

        switch(key) {
            case RETURN:
                if(callback != null)
                    callback(label.text);

                FlxTimer.wait(0.1, () -> typing = false);

            case BACKSPACE:
				if(position > 0) {
					text = text.substr(0, position - 1) + text.substr(position);
					changeSelection(-1);
				}
            
            case LEFT:
                changeSelection(-1);

            case RIGHT:
                changeSelection(1);

            case HOME:
                position = 0;

            case END:
                position = label.text.length;

            case V:
                if(!mod.ctrlKey)
                    return;

                final clipboardContents:String = Clipboard.generalClipboard.getData(TEXT_FORMAT);
                if(clipboardContents != null) {
                    if(callback != null)
                        callback(clipboardContents);

                    _onTextEdit(clipboardContents, 0, 0);
                }

            case C:
                if(!mod.ctrlKey)
                    return;

                Clipboard.generalClipboard.setData(TEXT_FORMAT, label.text);

            default:
        }
    }

    private function _onTextInput(text:String):Void {
        if(!typing || (maxCharacters > 0 && this.text.length >= maxCharacters))
            return;
        
        if(restrictChars != null && restrictChars.length != 0) {
            var excludeEReg:EReg = ~/\^(.-.|.)/gu;
            var excludeChars:String = '';
            
            final includeChars:String = excludeEReg.map(restrictChars, (ereg:EReg) -> {
                excludeChars += ereg.matched(1);
                return '';
            });
            final testRegexpParts:Array<String> = [];
            
            if(includeChars.length > 0)
                testRegexpParts.push('[^${restrictChars}]');
            
            if(excludeChars.length > 0)
                testRegexpParts.push('[${excludeChars}]');
            
            final regexp:EReg = new EReg('(${testRegexpParts.join(' | ')})', 'g');
            if(regexp != null)
                text = regexp.replace(text, '');
        }
        this.text = this.text.substr(0, position) + text + this.text.substr(position);
        position += text.length;
    }

    private function _onTextEdit(text:String, start:Int, end:Int):Void {
        _onTextInput(text);
    }

    override function set_width(Value:Float):Float {
        if(autoSize || bg == null)
            return Value;

        bg.width = Value;
        label.fieldWidth = Std.int(Value - 16); // TODO: handle text wrapping better

        return width = Value;
    }

    override function set_height(Value:Float):Float {
        if(autoSize || bg == null)
            return Value;

        bg.height = Value;
        return height = Value;
    }

    override function destroy():Void {
        FlxG.stage.window.onKeyDown.remove(_onKeyDown);
        FlxG.stage.window.onTextInput.remove(_onTextInput);
        FlxG.stage.window.onTextEdit.remove(_onTextEdit);
        super.destroy();
    }
    
    @:noCompletion
    private inline function get_text():String {
        return label.text;
    }

    @:noCompletion
    private inline function set_text(Value:String):String {
        label.text = Value ?? "";
        if(autoSize) {
            bg.width = label.width + 16;
            bg.height = label.height - 2;
        }
        return Value;
    }

    @:noCompletion
    private inline function set_typing(Value:Bool):Bool {
        typing = Value;
        if(typing) {
            if(!UIUtil.focusedComponents.contains(this))
                UIUtil.focusedComponents.push(this);
        }
        else {
            if(UIUtil.focusedComponents.contains(this))
                UIUtil.focusedComponents.remove(this);
        }
        return Value;
    }
}