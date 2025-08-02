package funkin.mobile.ui;

#if MOBILE_UI
import flixel.util.FlxSignal.FlxTypedSignal;

class MobileButton extends FunkinSprite {
    /**
     * Signal that is emitted when this button is pressed down
     */
    public var onDown:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    /**
     * Signal that is emitted when this button is released
     */
    public var onUp:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    
    /**
     * Signal that is emitted when this button is no longer hovered
     */
    public var onOut:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    /**
     * Signal that is emitted when this button's action is about to be ran
     */
    public var onConfirm:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public var restOpacity:Float = 0.3;

    public var instant:Bool = false;

    public var pressed:Bool = false;

    public var hovered:Bool = false;
    
    public function new(?xPos:Float = 0, ?yPos:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void = null, ?restOpacity:Float = 0.3, ?instant:Bool = false) {
        super(xPos, yPos);
        this.color = color;

        alpha = restOpacity;
        this.restOpacity = restOpacity;
        this.instant = instant;
        
        if(confirmCallback != null)
            onConfirm.add(confirmCallback);
    }   

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        final pointer = MouseUtil.getPointer();
        if(pointer != null) {
            final curHovered:Bool = pointer.overlaps(this, getDefaultCamera()) ?? false;
            if(curHovered != hovered) {
                hovered = curHovered;
                if(!hovered) {
                    onOut.dispatch();
                    alpha = restOpacity;
                }
            }
        }
        if(MouseUtil.isJustPressed() && hovered && !pressed) {
            pressed = true;
            onDown.dispatch();
            alpha = 1;
        }
        if(MouseUtil.isJustReleased() && pressed) {
            pressed = false;
            onUp.dispatch();
        }
    }
}
#end