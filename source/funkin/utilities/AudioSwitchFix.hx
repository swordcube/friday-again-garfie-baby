package funkin.utilities;

import lime.media.AudioManager;

import flixel.FlxState;
import flixel.sound.FlxSound;

import funkin.backend.Main;
import funkin.backend.native.NativeAPI;

/**
 * if youre stealing this keep this comment at least please lol
 *
 * hi gray itsa me yoshicrafter29 i fixed it hehe
 * 
 * @see https://github.com/FNF-CNE-Devs/CodenameEngine/blob/main/source/funkin/backend/system/modules/AudioSwitchFix.hx
 */
@:dox(hide)
class AudioSwitchFix {
	@:noCompletion
	private static function onStateSwitch(state:FlxState):Void {
		#if windows
        if (Main.audioDisconnected) {
            var playingList:Array<PlayingSound> = [];
            for(e in FlxG.sound.list) {
                if (e.playing) {
                    playingList.push({
                        sound: e,
                        time: e.time
                    });
                    e.stop();
                }
            }
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();

            AudioManager.shutdown();
            AudioManager.init();

            Main.changeID++;

            for(e in playingList) {
                e.sound.play(e.time);
            }
            Main.audioDisconnected = false;
        }
		#end
	}

	public static function init() {
		#if windows
		NativeAPI.registerAudio();
		FlxG.signals.preStateCreate.add(onStateSwitch);
		#end
	}
}

typedef PlayingSound = {
	var sound:FlxSound;
	var time:Float;
}