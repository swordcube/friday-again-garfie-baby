package funkin.substates;

import lime.app.Future;
import lime.system.System;

import openfl.media.Sound;

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

#if VIDEOS_ALLOWED
import funkin.graphics.VideoSprite;
#end

import funkin.substates.transition.TransitionSubState;

class GameOverSubState extends FunkinSubState {
    public var game:PlayState = PlayState.instance;

    public var character:Character;
    public var deathLoopStarted:Bool = false;
    public var isEnding:Bool = false;

    public var camFollow:FlxObject;
    public var deathSFX:FlxSound;
    
    public var loadingMusic:Bool = true;
    public var prevWindowOnClose:Void->Void;

    public var doFunnyDeath:Bool = false;

    override function create():Void {
        #if VIDEOS_ALLOWED
        doFunnyDeath = FlxG.random.bool(5);
        #end
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

        if(doFunnyDeath) {
            #if VIDEOS_ALLOWED
            final vidCam:FlxCamera = new FlxCamera();
            vidCam.bgColor = 0;
            FlxG.cameras.add(vidCam, false);

            final shits:Array<String> = [];
            Paths.iterateDirectory("shitpost", (f) -> {
                shits.push(f);
            });
            final vid:VideoSprite = new VideoSprite();
            vid.bitmap.onFormatSetup.add(() -> {
                vid.setGraphicSize(400, 0);
                vid.updateHitbox();
                vid.screenCenter();
            });
            vid.cameras = [vidCam];
            vid.bitmap.onEndReached.add(retry);
            add(vid);

            if(vid.load(shits[FlxG.random.int(0, shits.length - 1)]))
                FlxTimer.wait(0.001, () -> vid.play());
            #end
        } else {
            final musicThread:Future<Sound> = CoolUtil.createASyncFuture(() -> {
                return FlxG.assets.getSound(Paths.sound('${_createEvent.music}/music'));
            });
            musicThread.onComplete((snd:Sound) -> {
                loadingMusic = false;
                CoolUtil.playMusic(_createEvent.music, 0, true, snd);
                FlxG.sound.music.pause();
                FlxG.sound.music.time = 0;
            });
            musicThread.onError((e:Dynamic) -> {
                loadingMusic = false;
            });
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
    }

    override function update(elapsed):Void {
        super.update(elapsed);
        if(_createEvent.cancelled)
            return;

        if(controls.justPressed.ACCEPT)
            retry();

        if(controls.justPressed.BACK)
            exit();

        if(!doFunnyDeath) {
            if(!isEnding && (character.animation.name == "death" && character.animation.finished) && (FlxG.sound.music == null || !FlxG.sound.music.playing)) {
                call("onDeathLoopStart");
                deathLoopStarted = true;
                Conductor.instance.autoIncrement = true;
                beatHit(0);
                call("onDeathLoopStartPost");
            }
            if(deathLoopStarted && !loadingMusic && FlxG.sound.music != null && !FlxG.sound.music.playing) {
                FlxG.sound.music.volume = 1;
                FlxG.sound.music.play();
            }
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
        inline function goBackToGame() {
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
        }
        if(!doFunnyDeath) {
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
                    goBackToGame();
                });
            });
        } else
            goBackToGame();
        
        call("onRetryPost", [event.flagAsPost()]);
    }

    public function unsafeExit():Void {
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onExit", [event]);

        if(event.cancelled)
            return;

        FlxTimer.wait(0.001, () -> {
            CoolUtil.playMenuMusic(0.0);

            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            TransitionSubState.nextCamera = transitionCam;
            FlxG.signals.postStateSwitch.addOnce(() -> {
                FlxG.cameras.remove(TransitionSubState.nextCamera);
            });
            final wasMusicPlaying:Bool = FlxG.sound.music.playing;
            FlxG.sound.music.onComplete = null;

            if(PlayState.instance.isStoryMode)
                FlxG.switchState(StoryMenuState.new);
            else
                FlxG.switchState(FreeplayState.new);

            FlxTimer.wait(0.001, () -> {
                if(wasMusicPlaying) {
                    FlxG.sound.music.time = 0;
                    FlxG.sound.music.play();
                    FlxG.sound.music.fadeIn(0.16, 0, 1);
                }
            });
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