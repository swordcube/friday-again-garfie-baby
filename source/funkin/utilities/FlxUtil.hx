package funkin.utilities;

import openfl.display.Sprite;

import openfl.events.Event;
import openfl.events.KeyboardEvent;

import flixel.input.keyboard.FlxKey;

import funkin.backend.Main;
import funkin.graphics.RatioScaleModeEx;

/**
 * A utility class for simplifying certain tasks in Flixel.
 */
@:access(openfl.display.Sprite)
@:access(openfl.display.BitmapData)
@:access(flixel.FlxG)
@:access(flixel.FlxState)
@:access(flixel.FlxCamera)
class FlxUtil {
    /**
     * The package for the currently loaded state.
     * 
     * **Example:**
     * `funkin.states.PlayState`
     */
    public static var statePackage:String;

    /**
     * Initializes some hooks to Flixel to
     * allow this class to work correctly.
     */
    public static function init():Void {
        FlxG.signals.preStateSwitch.add(() -> {
            // Reset game size to initial size
            // In the case that you want a custom ratio
            // for only a specific song
            if(FlxG.scaleMode is RatioScaleModeEx) {
                final oldWidth:Int = FlxG.width;
                final oldHeight:Int = FlxG.height;

                for(c in FlxG.cameras.list) {
                    if(c.width == oldWidth && c.height == oldHeight) {
                        c.width = FlxG.initialWidth;
                        c.height = FlxG.initialHeight;
                    }
                }
                final scaleMode:RatioScaleModeEx = cast FlxG.scaleMode;
                scaleMode.resetSize();
            }
        });
        FlxG.signals.postStateSwitch.add(() -> {
            // Cache the class name of the current state
            // for ease of access and performance reasons
            statePackage = Type.getClassName(Type.getClass(FlxG.state));

            // Force GC to run after switching states
            // to clear excess memory
			MemoryUtil.clearAll();

            // Fixes shader coord problems that typically
            // occur when the window is resized
            applyShaderResizeFix();
        });

        // Fixes shader coord problems that typically
        // occur when the window is resized
        FlxG.signals.gameResized.add((width:Int, height:Int) -> {
            applyShaderResizeFix();
        });

        // Add some key event hooks
        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, (e) -> {
            // Prevent Flixel from listening to key inputs when switching fullscreen mode
            // Thanks nebulazorua @crowplexus
            if (e.altKey && e.keyCode == FlxKey.ENTER)
                e.stopImmediatePropagation();
        }, false, 100);

        // Add some frame hooks
        FlxG.stage.addEventListener(Event.ENTER_FRAME, (e) -> {
            // Handle keybind to toggle fullscreen
            if (Controls.instance.justPressed.FULLSCREEN)
                FlxG.fullscreen = !FlxG.fullscreen;
        });
    }

    public static function fixSpriteShaderSize(sprite:Sprite):Void {
        if(sprite == null)
            return;

		@:privateAccess {
            for(cache in [sprite.__cacheBitmapData, sprite.__cacheBitmapData2, sprite.__cacheBitmapData3]) {
                if(cache != null) {
                    if(cache.__texture != null)
                        cache.__texture.dispose();
                    
                    cache.disposeImage();
                    cache.dispose();
                }
            }
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
			sprite.__cacheBitmapData2 = null;
			sprite.__cacheBitmapData3 = null;
			sprite.__cacheBitmapColorTransform = null;
		}
    }

    public static function applyShaderResizeFix():Void {
        fixSpriteShaderSize(Main.instance);
        fixSpriteShaderSize(FlxG.game);

        for(camera in FlxG.cameras.list) {
            if(camera == null || camera.filters == null || camera.filters.length == 0)
                continue;

            fixSpriteShaderSize(camera.flashSprite);
        }
    }
}