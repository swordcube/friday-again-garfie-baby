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
            if(params.spectator != null && FlxG.assets.exists(params.spectator)) {
                spectator = FlxG.sound.play(params.spectator, 0, false, null, false).pause();
                spectator.volume = 1;
            }
            if(params.opponent != null && FlxG.assets.exists(params.opponent)) {
                opponent = FlxG.sound.play(params.opponent, 0, false, null, false).pause();
                opponent.volume = 1;
            }
        }
        if(params.player != null && FlxG.assets.exists(params.player)) {
            player = FlxG.sound.play(params.player, 0, false, null, false).pause();
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
        if(attachedConductor.music == null || !attachedConductor.music.playing)
            return;
        
        if(!isSingleTrack) {
            if(spectator != null && spectator.playing && Math.abs(attachedConductor.music.time - spectator.time) >= resyncRange)
                spectator.time = attachedConductor.music.time;
            
            if(opponent != null && opponent.playing && Math.abs(attachedConductor.music.time - opponent.time) >= resyncRange)
                opponent.time = attachedConductor.music.time;
        }
        if(player != null && player.playing && Math.abs(attachedConductor.music.time - player.time) >= resyncRange)
            player.time = attachedConductor.music.time;
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

    public function setVolume(volume:Float):Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.volume = volume;
            
            if(opponent != null)
                opponent.volume = volume;
        }
        if(player != null)
            player.volume = volume;
    }

    public function setPitch(pitch:Float):Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.pitch = pitch;
            
            if(opponent != null)
                opponent.pitch = pitch;
        }
        if(player != null)
            player.pitch = pitch;
    }

    public function setMuted(muted:Bool):Void {
        if(!isSingleTrack) {
            if(spectator != null)
                spectator.muted = muted;
            
            if(opponent != null)
                opponent.muted = muted;
        }
        if(player != null)
            player.muted = muted;
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