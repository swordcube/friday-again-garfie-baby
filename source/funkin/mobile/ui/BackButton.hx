package funkin.mobile.ui;

#if MOBILE_UI
class BackButton extends MobileButton {
    public function new(?xPos:Float = 0, ?yPos:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void = null, ?restOpacity:Float = 0.3, ?instant:Bool = false) {
        super(xPos, yPos, color, confirmCallback, restOpacity, instant);

        loadSparrowFrames('mobile/back');
        anim.addByIndices('out', 'back', [0], "", 24, false);
        anim.addByIndices('down', 'back', [5], "", 24, false);
        anim.addByIndices('up', 'back', [for(i in 6...23) i], "", 24, false);
        anim.onFinish.add((name:String) -> {
            if(name == "up") {
                anim.play("out");
                if(hovered)
                    onConfirm.dispatch();
            }
        });
        anim.play('out');
        
        scale.set(0.7, 0.7);
        updateHitbox();

        onOut.add(() -> anim.play("out", true));
        onDown.add(() -> anim.play("down", true));
        onUp.add(() -> {
            if(hovered) {
                if(instant) {
                    anim.play("out", true);
                    onConfirm.dispatch();
                } else {
                    anim.play("up", true);
                    FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
                }
            }
        });
    }
}
#end