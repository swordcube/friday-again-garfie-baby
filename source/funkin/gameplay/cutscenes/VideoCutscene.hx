package funkin.gameplay.cutscenes;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import funkin.states.PlayState;
import funkin.graphics.VideoSprite;

class VideoCutscene extends Cutscene {
    public var name:String;
    public var video:VideoSprite;

    public function new(name:String) {
        super();
        this.name = name;
        canRestart = true;
    }

    override function start():Void {
        super.start();

        final game:PlayState = PlayState.instance;
        game.camGame.visible = false;
        
        video = new VideoSprite();
        video.bitmap.onFormatSetup.add(() -> {
            video.setGraphicSize(FlxG.width, FlxG.height);
            video.updateHitbox();
            video.screenCenter();
        });
        video.bitmap.onEndReached.add(finish);
        video.load(Paths.video(name));
        video.play();
        add(video);

        cameras = [game.camOther];
    }

    override function pause():Void {
        super.pause();
        video.pause();
    }

    override function resume():Void {
        super.resume();
        video.play();
    }

    override function restart():Void {
        super.restart();

        video.pause();
        FlxTimer.wait(0.001, () -> {
            video.bitmap.time = 0;
            video.play();
        });
    }
    
    override function finish():Void {
        super.finish();

        final game:PlayState = PlayState.instance;
        game.camGame.visible = true;
    }
}