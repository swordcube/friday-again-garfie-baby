package funkin.graphics;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * Dummy FlxSprite that allows you to cache FlxGraphics, and immediately send them to GPU memory.
 */
class GraphicCacheSprite extends FlxSprite {
	/**
	 * Array containing all of the graphics cached by this sprite.
	 */
	public var cachedGraphics:Array<FlxGraphic> = [];

	/**
	 * Array containing all of the currently non-cached graphics.
	 */
	public var nonCachedGraphics:Array<FlxGraphic> = [];

	public function new() {
		super();
		alpha = 0.00001;
	}

	/**
	 * Caches a given graphic asset.
     * 
	 * @param  path  The graphic asset to cache.
	 */
	public function cache(graphic:FlxGraphicAsset):Void {
		final graphic:FlxGraphic = FlxG.bitmap.add(graphic);
        if(graphic == null)
            return;

        cachedGraphics.push(graphic);
        nonCachedGraphics.push(graphic);
        
        // force it not to clear from cache automatically
        // until this sprite is destroyed
        graphic.incrementUseCount();
        graphic.destroyOnNoUse = false;
	}

    override function draw():Void {
        while(nonCachedGraphics.length > 0) {
            loadGraphic(nonCachedGraphics.shift());
            drawComplex(FlxG.camera);
        }
    }
    
	override function destroy():Void {
		for(g in cachedGraphics) {
			g.destroyOnNoUse = true;
			g.decrementUseCount();
		}
		graphic = null;
		super.destroy();
	}
}