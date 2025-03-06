package funkin.ui;

import openfl.geom.Rectangle;
import flixel.math.FlxRect;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawQuadsItem;

import flixel.system.FlxAssets.FlxGraphicAsset;

class SliceSprite extends UISprite {
	public var leftBorder:Float = 5;
	public var rightBorder:Float = 5;
	public var topBorder:Float = 5;
	public var bottomBorder:Float = 5;

	public function new(x:Float = 0, y:Float = 0, ?graphic:FlxGraphicAsset) {
		super(x, y, graphic);

		for (i in 0...9)
			_slices[i] = new Slice();
	}

	public function setBorders(left:Float, right:Float, top:Float, bottom:Float):Void {
		leftBorder = left;
		rightBorder = right;
		topBorder = top;
		bottomBorder = bottom;
	}

	public override function draw() {
		checkEmptyFrame();
        getScreenPosition(_point, camera).subtractPoint(offset);

		final cW:Float = frameWidth - (leftBorder + rightBorder);
		final cH:Float = frameHeight - (topBorder + bottomBorder);

		_frameX = frame.frame.x;
		_frameY = frame.frame.y;

		final rf:FlxFrame = _frame;
		final draw:FlxDrawQuadsItem = camera.startQuadBatch(_frame.parent, false, false, blend, antialiasing, shader);

		for (i in 0...9) {
			final slice:Slice = _slices.unsafeGet(i);
			slice.frame = rf.frame;
			slice.resetScale();

			switch (i) {
				case 0:
					renderSlice(slice, 0, 0, 0, 0, leftBorder, topBorder);
				
				case 1:
					slice.scaleX = (_width - leftBorder - rightBorder) / (frameWidth - leftBorder - rightBorder);
					renderSlice(slice, leftBorder, 0, leftBorder, 0, cW, topBorder);
				
				case 2:
					renderSlice(slice, (_prev.scaleX * cW) + rightBorder, 0, frameWidth - rightBorder, 0, rightBorder, topBorder);
				
				case 3:
					slice.scaleY = (_height - topBorder - bottomBorder) / (frameHeight - topBorder - bottomBorder);
					renderSlice(slice, 0, topBorder, 0, topBorder, leftBorder, cH);
				
				case 4:
					slice.scaleX = (_width - leftBorder - rightBorder) / (frameWidth - leftBorder - rightBorder);
					slice.scaleY = (_height - topBorder - bottomBorder) / (frameHeight - topBorder - bottomBorder);
					renderSlice(slice, leftBorder, topBorder, leftBorder, topBorder, cW, cH);
				
				case 5:
					slice.scaleY = (_height - topBorder - bottomBorder) / (frameHeight - topBorder - bottomBorder);
					renderSlice(slice, (_prev.scaleX * cW) + rightBorder, topBorder, frameWidth - rightBorder, topBorder, rightBorder, cH);
				
				case 6:
					renderSlice(slice, 0, (_prev.scaleY * cH) + bottomBorder, 0, frameHeight - bottomBorder, leftBorder, bottomBorder);
				
				case 7:
					slice.scaleX = (_width - leftBorder - rightBorder) / (frameWidth - leftBorder - rightBorder);
					renderSlice(slice, leftBorder, _prev.ty, leftBorder, frameHeight - bottomBorder, cW, bottomBorder);
				
				case 8:
					renderSlice(slice, (_prev.scaleX * cW) + rightBorder, _prev.ty, frameWidth - rightBorder, frameHeight - bottomBorder, rightBorder, bottomBorder);
			}
			draw.addQuad(rf, _matrix, colorTransform);
		}
	}

	public inline function renderSlice(slice:Slice, ?_x:Float, ?_y:Float, ?fx:Float, ?fy:Float, w:Float, h:Float) {
		slice.frame.x = fx + _frameX;
		slice.frame.y = fy + _frameY;
		slice.frame.width = w;
		slice.frame.height = h;
		slice.tx = _x * slice.scaleX;
		slice.ty = _y * slice.scaleY;

		_matrix.a = slice.scaleX * scale.x;
		_matrix.d = slice.scaleY * scale.y;

		_matrix.tx = (_point.x + _x) * scale.x;
		_matrix.ty = (_point.y + _y) * scale.y;
		_prev = slice;
	}

	//----------- [ Private API ] -----------//
    
	private var _slices:Array<Slice> = [];
	private var _frameX:Float;
	private var _frameY:Float;
	private var _width:Float;
	private var _height:Float;
	private var _prev:Slice;

	override function set_width(val:Float):Float {
		return _width = val;
	}

	override function get_width():Float {
		return _width;
	}

	override function set_height(val:Float):Float {
		return _height = val;
	}

	override function get_height():Float {
		return _height;
	}
}

@:structInit
class Slice {
	public var tx:Float;
	public var ty:Float;
	public var w:Float;
	public var h:Float;
	public var frame:FlxRect;
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;

	public function new() {}

	public function resetScale():Void {
		scaleX = 1.0;
		scaleY = 1.0;
	}
}
