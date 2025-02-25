package funkin.gameplay;

import flixel.FlxCamera;

/**
 * An extension of `FlxCamera` with some extra features tailored to gameplay.
 */
class FunkinCamera extends FlxCamera {
    /**
     * Extra zoom that gets applied to the camera
     * when rendering, useful for making camera bumping effects
     * while also tweening the zoom for a cool effect or something during a song.
     */
    public var extraZoom(default, set):Float = 0;

    //----------- [ Private API ] -----------//
    
    @:noCompletion
    private inline function _setScaleToFloat(Zoom:Float):Void {
        setScale(Zoom, Zoom);
    }

    @:noCompletion
    private function set_extraZoom(ExtraZoom:Float):Float {
        _setScaleToFloat(zoom + ExtraZoom);
        return extraZoom = ExtraZoom;
    }

    override function set_zoom(Zoom:Float):Float {
        zoom = (Zoom == 0) ? FlxCamera.defaultZoom : Zoom;
        _setScaleToFloat(zoom + extraZoom);
        return zoom;
    }
}   