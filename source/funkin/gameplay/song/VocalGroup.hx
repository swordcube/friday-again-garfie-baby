package funkin.gameplay.song;

import flixel.util.FlxDestroyUtil;
import flixel.sound.FlxSound;

class VocalGroup extends FlxBasic {
    public var resyncRange:Float = 30;

    public var spectator(default, null):FlxSound;
    public var opponent(default, null):FlxSound;
    public var player(default, null):FlxSound;

    /**
     * Whether or not the vocals are a single track.
     * 
     * If this is true, the `player` vocals will be the
     * only vocal track active.
     * 
     * They will also not mute on player note missing.
     */
    public var isSingleTrack(default, null):Bool = false;

    public var attachedConductor:Conductor;

    public function new(params:VocalGroupParams) {
        super();
        if(params.isSingleTrack)
            isSingleTrack = true;
        else {
            if(FlxG.assets.exists(params.spectator)) {
                spectator = FlxG.sound.play(params.spectator, 0).pause();
                spectator.volume = 1;
            }
            if(FlxG.assets.exists(params.opponent)) {
                opponent = FlxG.sound.play(params.opponent, 0).pause();
                opponent.volume = 1;
            }
        }
        if(FlxG.assets.exists(params.player)) {
            player = FlxG.sound.play(params.player, 0).pause();
            player.volume = 1;
        }
        if(params.attachedConductor != null)
            attachedConductor = params.attachedConductor;
        else
            attachedConductor = Conductor.instance;
    }

    public function play():Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.play();

            if(opponent != null)
                opponent.play();
        }
        if(player != null)
            player.play();
    }

    public function stop():Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.stop();

            if(opponent != null)
                opponent.stop();
        }
        if(player != null)
            player.stop();
    }

    public function pause():Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.pause();

            if(opponent != null)
                opponent.pause();
        }
        if(player != null)
            player.pause();
    }

    public function resume():Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.resume();

            if(opponent != null)
                opponent.resume();
        }
        if(player != null)
            player.resume();
    }

    override function update(elapsed:Float) {
        if(!isSingleTrack) {
            if(spectator != null && spectator.playing && Math.abs(attachedConductor.rawTime - spectator.time) >= resyncRange)
                spectator.time = attachedConductor.rawTime;
            
            if(opponent != null && opponent.playing && Math.abs(attachedConductor.rawTime - opponent.time) >= resyncRange)
                opponent.time = attachedConductor.rawTime;
        }
        if(player != null && player.playing && Math.abs(attachedConductor.rawTime - player.time) >= resyncRange)
            player.time = attachedConductor.rawTime;
    }

    public function seek(time:Float):Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.time = time;
            
            if(opponent != null)
                opponent.time = time;
        }
        if(player != null)
            player.time = time;
    }

    override function destroy() {
        if(!isSingleTrack) {
            spectator = FlxDestroyUtil.destroy(spectator);
            opponent = FlxDestroyUtil.destroy(opponent);
        }
        player = FlxDestroyUtil.destroy(player);
        super.destroy();
    }
}

typedef VocalGroupParams = {
    var ?spectator:String;
    var ?opponent:String;
    var player:String;

    var ?isSingleTrack:Bool;
    var ?attachedConductor:Conductor;
}