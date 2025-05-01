package funkin.substates;

import lime.system.System;

import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;

import funkin.backend.events.Events;
import funkin.backend.events.ActionEvent;
import funkin.backend.events.GameplayEvents;

import funkin.gameplay.character.Character;

import funkin.states.PlayState;
import funkin.states.menus.StoryMenuState;
import funkin.states.menus.FreeplayState;

import funkin.substates.transition.FadeTransition;

class GameOverSubState extends FunkinSubState {
    public var game:PlayState = PlayState.instance;

    public var character:Character;
    public var isEnding:Bool = false;

    public var camFollow:FlxObject;
    public var deathSFX:FlxSound;
    
    public var prevWindowOnClose:Void->Void;

    override function create():Void {
        super.create();

        FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {
            tmr.cancel();
        });
        FlxTween.globalManager.forEach((twn:FlxTween) -> {
            twn.cancel();
        });
        WindowUtil.onClose = () -> {
            if(!WindowUtil.preventClosing)
                return;

            final warning = new UnsavedWarningSubState();
            warning.onAccept.add(() -> {
                WindowUtil.preventClosing = false;
                WindowUtil.resetClosing();
                System.exit(0);
            });
            warning.onCancel.add(() -> {
                WindowUtil.resetClosing();
                warning.close();
            });
            openSubState(warning);
        };
        FlxG.timeScale = 1;
        prevWindowOnClose = WindowUtil.onClose;
        persistentUpdate = false;
        
        if(_createEvent.cancelled)
            return;

        character = new Character(_createEvent.characterID, game.player?.isPlayer ?? true);
        character.setPosition(game.player?.x ?? 800, game.player?.y ?? 700);
        character.playAnim("death");
        add(character);

        final camPos:FlxPoint = character.getCameraPosition();
        camFollow = new FlxObject(0, 0, 1, 1);
        camFollow.setPosition(camPos.x, camPos.y);
        add(camFollow);

        FlxG.camera.follow(camFollow, LOCKON, 0.05);
        camPos.put();

        deathSFX = FlxG.sound.play(Paths.sound(_createEvent.deathSFX));
    }

    override function update(elapsed):Void {
        super.update(elapsed);
        if(_createEvent.cancelled)
            return;

        if(controls.justPressed.ACCEPT)
            retry();

        if(controls.justPressed.BACK)
            exit();

        if(!isEnding && (!deathSFX.playing || (character.animation.name == "death" && character.animation.finished)) && (FlxG.sound.music == null || !FlxG.sound.music.playing)) {
			CoolUtil.playMusic(_createEvent.music, 1, true);
            Conductor.instance.autoIncrement = true;
			beatHit(0);
		}
    }

    public function retry():Void {
        if(isEnding)
			return;

		isEnding = true;

		final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onRetry", [event]);

		if(event.cancelled)
			return;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.stop();
            FlxG.sound.music = null;
        }
        character.canDance = false;
        character.playAnim("retry", NONE, true);
        
		final sound:FlxSound = FlxG.sound.play(Paths.sound(_createEvent.retrySFX));
		final secsLength:Float = sound.length / 1000;
        
		var waitTime:Float = 0.7;
		var fadeOutTime:Float = secsLength - 0.7;

		if(fadeOutTime < 0.5) {
			fadeOutTime = secsLength;
			waitTime = 0;
		}
		FlxTimer.wait(waitTime, () -> {
			FlxG.camera.fade(FlxColor.BLACK, fadeOutTime, false, () -> {
                FlxTimer.wait(0.001, () -> {
                    FlxG.switchState(PlayState.new.bind({
                        song: game.currentSong,
                        difficulty: game.currentDifficulty,
                        mix: game.currentMix,
                        mod: PlayState.lastParams.mod,
            
                        startTime: PlayState.lastParams.startTime,
            
                        _chart: game.currentChart,
                        _unsaved: PlayState.lastParams._unsaved
                    }));
                });
                close();
			});
		});
        call("onRetryPost", [event.flagAsPost()]);
    }

    public function unsafeExit():Void {
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onExit", [event]);

        if(event.cancelled)
            return;

        FlxTimer.wait(0.001, () -> {
            CoolUtil.playMenuMusic(0.0);
            FlxG.sound.music.fadeIn(0.16, 0, 1);

            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            FadeTransition.nextCamera = transitionCam;
            FlxG.signals.postStateSwitch.addOnce(() -> {
                FlxG.cameras.remove(FadeTransition.nextCamera);
            });
            FlxG.sound.music.onComplete = null;

            if(PlayState.instance.isStoryMode)
                FlxG.switchState(StoryMenuState.new);
            else
                FlxG.switchState(FreeplayState.new);
        });
        FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        close();

        call("onExitPost", [event.flagAsPost()]);
    }

    public function exit():Void {
        if(PlayState.lastParams._unsaved) {
            final warning = new UnsavedWarningSubState();
            warning.onAccept.add(unsafeExit);
            warning.onCancel.add(warning.close);
            openSubState(warning);
            return;
        }
        unsafeExit();
    }

    private var _createEvent:GameOverCreateEvent;

    override function _callCreate():Void {
        _createEvent = cast Events.get(GAME_OVER_CREATE);
        call("onCreate", [_createEvent.recycle(game.player?.data?.deathCharacter ?? "bf-dead", null, "gameplay/death/sfx/default/death", "gameplay/death/music/default", "gameplay/death/sfx/default/retry")]);
    }

    override function _callCreatePost():Void {
        _createEvent.character = character;
        call("onCreatePost", [_createEvent.flagAsPost()]);
    }

    override function destroy():Void {
        WindowUtil.onClose = prevWindowOnClose;
        super.destroy();
    }
}