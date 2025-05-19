package funkin.gameplay.song;

import flixel.sound.FlxSound;

class VocalGroup extends FlxBasic {
    public var resyncRange:Float = 30;

    public var spectator(default, null):Array<FlxSound> = [];
    public var opponent(default, null):Array<FlxSound> = [];
    public var player(default, null):Array<FlxSound> = [];

    public var attachedConductor:Conductor;

    public function new(params:VocalGroupParams) {
        super();
        if((params.spectator?.length ?? 0) == 0 && (params.opponent?.length ?? 0) == 0 && (params.player?.length ?? 0) == 0 && params.mainVocals == null)
            Logs.error('You must define main vocals if you\'re not defining character vocals!');

        else if((params.spectator?.length ?? 0) == 0 && (params.opponent?.length ?? 0) == 0 && (params.player?.length ?? 0) == 0 && params.mainVocals != null) {
            if(FlxG.assets.exists(params.mainVocals)) {
                final sound:FlxSound = FlxG.sound.play(params.mainVocals, 0, false, null, false).pause();
                sound.volume = 1;
                spectator.push(sound);
            }
        } else {
            if(params.spectator != null) {
                for(path in params.spectator) {
                    if(!FlxG.assets.exists(path))
                        continue;
        
                    final sound:FlxSound = FlxG.sound.play(path, 0, false, null, false).pause();
                    sound.volume = 1;
                    spectator.push(sound);
                }
            }
            if(params.opponent != null) {
                for(path in params.opponent) {
                    if(!FlxG.assets.exists(path))
                        continue;
        
                    final sound:FlxSound = FlxG.sound.play(path, 0, false, null, false).pause();
                    sound.volume = 1;
                    opponent.push(sound);
                }
            }
            if(params.player != null) {
                for(path in params.player) {
                    if(!FlxG.assets.exists(path))
                        continue;
        
                    final sound:FlxSound = FlxG.sound.play(path, 0, false, null, false).pause();
                    sound.volume = 1;
                    player.push(sound);
                }
            }
        }
        if(params.attachedConductor != null)
            attachedConductor = params.attachedConductor;
        else
            attachedConductor = Conductor.instance;
    }

    public function play():Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.play();
        }
    }

    public function stop():Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.stop();
        }
    }

    public function pause():Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.pause();
        }
    }

    public function resume():Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.resume();
        }
    }

    override function update(elapsed:Float) {
        if(attachedConductor.music == null || !attachedConductor.music.playing)
            return;
        
        for(list in [spectator, opponent, player]) {
            for(sound in list) {
                if(sound != null && sound.playing && Math.abs(attachedConductor.music.time - sound.time) >= resyncRange)
                    sound.time = attachedConductor.music.time;
            }
        }
    }

    public function seek(time:Float):Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.time = time;
        }
    }

    public function setVolume(volume:Float):Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.volume = volume;
        }
    }

    public function setPitch(pitch:Float):Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.pitch = pitch;
        }
    }

    public function setMuted(muted:Bool):Void {
        for(list in [spectator, opponent, player]) {
            for(sound in list)
                sound.muted = muted;
        }
    }

    override function destroy():Void {
        for(list in [spectator, opponent, player])
            list.clear(true);
        
        super.destroy();
    }
}

typedef VocalGroupParams = {
    var ?spectator:Array<String>;
    var ?opponent:Array<String>;
    var ?player:Array<String>;

    var ?mainVocals:String;
    var ?attachedConductor:Conductor;
}