package funkin.substates;

import funkin.backend.events.ActionEvent;
import lime.app.Future;
import lime.system.System;

import openfl.media.Sound;

import flixel.text.FlxText;
import flixel.sound.FlxSound;

import flixel.tweens.FlxTween;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import funkin.backend.events.Events;
import funkin.backend.events.MenuEvents;

import funkin.states.PlayState;
import funkin.states.menus.StoryMenuState;
import funkin.states.menus.FreeplayState;
import funkin.states.menus.OptionsState;

import funkin.substates.transition.TransitionSubState;

import funkin.ui.AtlasText;
import funkin.ui.AtlasTextList;

#if SCRIPTING_ALLOWED
import funkin.scripting.GlobalScript;
#end

@:access(funkin.states.PlayState)
class PauseSubState extends FunkinSubState {
    public static final CHARTER_FADE_DELAY:Float = 15.0;
    public static final CHARTER_FADE_DURATION:Float = 0.75;

    public var canPlayExitMusic:Bool = true;

    public var pausedTimers:Array<FlxTimer> = [];
    public var pausedTweens:Array<FlxTween> = [];

    public var bg:FlxSprite;
    public var grpItems:AtlasTextList;

    public var artistText:FlxText;
    public var grpStats:FlxTypedContainer<FlxText>;

    public var pauseMusic:FlxSound;
    public var inputAllowed:Bool = false;

    public var prevWindowOnClose:Void->Void;
    public var lastTimeScale:Float = 1;

    override function create():Void {
        super.create();
        
        lastTimeScale = FlxG.timeScale;
        FlxG.timeScale = 1;

        prevWindowOnClose = WindowUtil.onClose;

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);
        
        FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {
            tmr.paused = true;
            pausedTimers.push(tmr);
        });
        FlxTween.globalManager.forEach((twn:FlxTween) -> {
            twn.paused = true;
            pausedTweens.push(twn);
        });
        if(_createEvent.cancelled)
            return;

        bg = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, FlxColor.BLACK);
        bg.alpha = 0;
        bg.screenCenter();
        add(bg);

        grpItems = new AtlasTextList();
        grpItems.active = false;
        add(grpItems);

        grpStats = new FlxTypedContainer<FlxText>();
        add(grpStats);

        loadPauseMusic();
        regenerateItems(MAIN);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

        final game:PlayState = PlayState.instance;
        final stats:Array<PauseMenuStat> = [
            {name: game.currentChart.meta.song.title},
            {name: 'Artist: ${game.currentChart.meta.song.artist}'},
            {name: 'Difficulty: ${game.currentDifficulty.toUpperCase()}'},
            {name: '${PlayState.deathCounter} Blue Ball${(PlayState.deathCounter != 1) ? "s" : ""}'}
        ];
        var yIndex:Int = 0;
        for(i => stat in stats) {
            final text:FlxText = new FlxText(20, 15 + (yIndex * 32), 0, stat.name);
            text.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, RIGHT);
            text.alpha = 0;
            text.x = FlxG.width - (text.width + 20);
            text.visible = stat.visible ?? true;
            grpStats.add(text);

            if(!stat.keepLastY)
                yIndex++;

            FlxTween.tween(text, {alpha: 1, y: text.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3 * yIndex});
        }
        artistText = grpStats.members[1]; // hardcoded but i don't care
        startCharterTimer();

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
    }

    override function update(elapsed:Float):Void {
        if(_createEvent.cancelled) {
            super.update(elapsed);
            
            if(!inputAllowed)
                inputAllowed = true;
            
            return;
        }
        if(inputAllowed)
            grpItems.active = true;

        inputAllowed = true;
        super.update(elapsed);
    }

    public function loadPauseMusic():Void {
        pauseMusic = new FlxSound();
        FlxG.sound.list.add(pauseMusic);
        
        final musicThread:Future<Sound> = CoolUtil.createASyncFuture(() -> {
            return FlxG.assets.getSound(Paths.sound(_createEvent.pauseMusic));
        });
        musicThread.onComplete((snd:Sound) -> {
            if(pauseMusic != null) {
                pauseMusic.loadEmbedded(snd, true);

                pauseMusic.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length / 2));
                pauseMusic.volume = 0;
                
                pauseMusic.play();
                pauseMusic.fadeIn(10, 0, _createEvent.musicVolume);
            }
        });
        musicThread.onError((e:Dynamic) -> {});
    }

    public function regenerateItems(page:PageType):Void {
        grpItems.clearList();
        switch(page) {
            case MAIN:
                final game:PlayState = PlayState.instance;
                grpItems.addItem("Resume", {onAccept: (_, _) -> close()});

                if(game.inCutscene) {
                    grpItems.addItem("Skip Cutscene", {onAccept: (_, _) -> {
                        game.cutscene.finish();
                        close();
                    }});
                    if(game.cutscene.canRestart) {
                        grpItems.addItem("Restart Cutscene", {onAccept: (_, _) -> {
                            game.cutscene.restart();
                            close();
                        }});
                    }
                } else
                    grpItems.addItem("Restart Song", {onAccept: (_, _) -> restartSong()});
                
                if(game.currentChart.meta.song.difficulties.length > 1)
                    grpItems.addItem("Change Difficulty", {onAccept: (_, _) -> regenerateItems(CHANGE_DIFF)});

                if(game.chartingMode)
                    grpItems.addItem("Leave Charting Mode", {onAccept: (_, _) -> restartSong(true)});

                grpItems.addItem("Change Options", {onAccept: (_, _) -> goToOptions()});
                grpItems.addItem("Exit to Menu", {onAccept: (_, _) -> exitToMenu()});
                
            case CHANGE_DIFF:
                final game:PlayState = PlayState.instance;
                for(diff in game.currentChart.meta.song.difficulties.filter((diff:String) -> diff != game.currentDifficulty)) {
                    grpItems.addItem(diff.toUpperCase(), {onAccept: (_, _) -> {
                        game.currentDifficulty = diff;
                        restartSong();
                    }});
                }
                grpItems.addItem("Back", {onAccept: (_, _) -> regenerateItems(MAIN)});
        }
        call("onRegenerateItems", [page]);

        grpItems.curSelected = 0;
        grpItems.changeSelection(0, true);
    }

    public function playExitMusic():Void {
        if(!Constants.PLAY_MENU_MUSIC_AFTER_EXIT) {
            FlxG.sound.music.volume = 0;
            FlxG.sound.music.looped = true;
            FlxG.sound.music.play();
            FlxG.sound.music.fadeIn(0.16, 0, 1);
        } else {
            final curContentPack:String = Paths.forceContentPack;
            Paths.forceContentPack = null;
            CoolUtil.playMenuMusic();
            Paths.forceContentPack = curContentPack;
        }
    }

    public function restartSong(leaveCharting:Bool = false):Void {
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onRestartSong", [event]);
        
        if(event.cancelled)
            return;
        
        pausedTimers.clear();
        pausedTweens.clear();

        FlxTimer.wait(0.001, () -> {
            final game:PlayState = PlayState.instance;
            game.persistentUpdate = false;

            FlxG.sound.music.pause();
            game.vocals.pause();

            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            if(FlxG.keys.pressed.SHIFT) {
                FlxG.signals.preStateCreate.addOnce((_) -> {
                    Cache.clearAll();
                    Paths.reloadContent();
                });
            }
            Cache.uiSkinCache.clear();
            Cache.noteSkinCache.clear();
            Cache.characterCache.clear();

            TransitionSubState.nextCamera = transitionCam;
            FlxG.signals.postStateSwitch.addOnce(() -> {
                FlxG.cameras.remove(TransitionSubState.nextCamera);
            });
            FlxG.timeScale = 1;
            FlxG.sound.music.onComplete = null;

            FlxG.switchState(PlayState.new.bind({
                song: game.currentSong,
                difficulty: game.currentDifficulty,
                mix: game.currentMix,
                mod: PlayState.lastParams.mod,
                isStoryMode: PlayState.lastParams.isStoryMode,

                startTime: PlayState.lastParams.startTime,
                chartingMode: (!leaveCharting) ? PlayState.lastParams.chartingMode : false,

                minimalMode: PlayState.lastParams.minimalMode,
                scriptsAllowed: PlayState.lastParams.scriptsAllowed,
    
                _chart: game.currentChart,
                _unsaved: PlayState.lastParams._unsaved
            }));
        });
        close();
        call("onRestartSongPost", [event.flagAsPost()]);
    }

    public function unsafeGoToOptions():Void {
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onGoToOptions", [event]);
        
        if(event.cancelled)
            return;

        pausedTimers.clear();
        pausedTweens.clear();

        final wasMusicPlaying:Bool = FlxG.sound.music.playing;
        FlxTimer.wait(0.001, () -> {
            final game:PlayState = PlayState.instance;
            game.persistentUpdate = false;

            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            FlxG.timeScale = 1;
            TransitionSubState.nextCamera = transitionCam;

            FlxG.signals.postStateSwitch.addOnce(() -> {
                FlxG.cameras.remove(TransitionSubState.nextCamera);
            });
            final wasMusicPlaying:Bool = FlxG.sound.music.playing;
            FlxG.sound.music.onComplete = null;

            FlxG.switchState(OptionsState.new.bind({
                exitState: PlayState.new.bind(PlayState.lastParams)
            }));
            FlxTimer.wait(0.001, () -> {
                if(wasMusicPlaying)
                    FlxG.sound.music.play();
    
                else if(canPlayExitMusic)
                    playExitMusic();
            });
        });
        close();
        FlxG.sound.music.onComplete = null;

        if(wasMusicPlaying)
            FlxG.sound.music.play();

        else if(canPlayExitMusic)
            playExitMusic();

        call("onGoToOptionsPost", [event.flagAsPost()]);
    }

    public function goToOptions():Void {
        if(PlayState.lastParams._unsaved) {
            final warning = new UnsavedWarningSubState();
            warning.onAccept.add(unsafeExitToMenu);
            warning.onCancel.add(warning.close);
            openSubState(warning);
            return;
        }
        unsafeGoToOptions();
    }

    public function unsafeExitToMenu():Void {
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onExitToMenu", [event]);
        
        if(event.cancelled)
            return;

        pausedTimers.clear();
        pausedTweens.clear();

        final wasMusicPlaying:Bool = FlxG.sound.music.playing;
        FlxTimer.wait(0.001, () -> {
            PlayState.seenCutscene = false;

            final game:PlayState = PlayState.instance;
            game.persistentUpdate = false;
            
            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            FlxG.timeScale = 1;
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
                if(wasMusicPlaying)
                    FlxG.sound.music.play();
    
                else if(canPlayExitMusic)
                    playExitMusic();
            });
        });
        close();
        FlxG.sound.music.onComplete = null;

        if(wasMusicPlaying)
            FlxG.sound.music.play();

        else if(canPlayExitMusic)
            playExitMusic();

        call("onExitToMenuPost", [event.flagAsPost()]);
    }

    public function exitToMenu():Void {
        if(PlayState.lastParams._unsaved) {
            final warning = new UnsavedWarningSubState();
            warning.onAccept.add(unsafeExitToMenu);
            warning.onCancel.add(warning.close);
            openSubState(warning);
            return;
        }
        unsafeExitToMenu();
    }

    //----------- [ Private API ] -----------//

    private var _charterFadeTween:Null<FlxTween> = null;

    private function startCharterTimer():Void {
        _charterFadeTween = FlxTween.tween(artistText, {alpha: 0.0}, CHARTER_FADE_DURATION, {
            startDelay: CHARTER_FADE_DELAY,
            ease: FlxEase.quartOut,
            onComplete: (_) -> {
                final game:PlayState = PlayState.instance;
                if (game.currentChart != null)
                    artistText.text = 'Charter: ${game.currentChart.meta.song.charter ?? 'Unknown'}';
                else
                    artistText.text = 'Charter: Unknown';
                
                artistText.x = FlxG.width - (artistText.width + 20);
                FlxTween.tween(artistText, {alpha: 1.0}, CHARTER_FADE_DURATION, {
                    ease: FlxEase.quartOut,
                    onComplete: (_) -> {
                        startArtistTimer();
                    }
                });
            }
        });
    }

    private function startArtistTimer():Void {
        _charterFadeTween = FlxTween.tween(artistText, {alpha: 0.0}, CHARTER_FADE_DURATION, {
            startDelay: CHARTER_FADE_DELAY,
            ease: FlxEase.quartOut,
            onComplete: (_) -> {
                final game:PlayState = PlayState.instance;
                if (game.currentChart != null)
                    artistText.text = 'Artist: ${game.currentChart.meta.song.artist ?? 'Unknown'}';
                else
                    artistText.text = 'Artist: Unknown';

                artistText.x = FlxG.width - (artistText.width + 20);
                FlxTween.tween(artistText, {alpha: 1.0}, CHARTER_FADE_DURATION, {
                    ease: FlxEase.quartOut,
                    onComplete: (_) -> {
                        startCharterTimer();
                    }
                });
            }
        });
    }

    private var _createEvent:PauseMenuCreateEvent;

    override function _callCreate():Void {
        _createEvent = cast Events.get(PAUSE_MENU_CREATE);
        call("onCreate", [_createEvent.recycle("menus/music/breakfast/music", 0.5)]);
    }

    override function _callCreatePost():Void {
        call("onCreatePost", [_createEvent.flagAsPost()]);
    }

    override function destroy():Void {
        FlxG.timeScale = lastTimeScale;

        for(timer in pausedTimers)
            timer.paused = false;

        for(tween in pausedTweens)
            tween.paused = false;

        if(_charterFadeTween != null) {
            _charterFadeTween.cancel();
            _charterFadeTween = null;
        }
        if(pauseMusic != null)
            pauseMusic = FlxDestroyUtil.destroy(pauseMusic);
        
        FlxG.cameras.remove(camera);
        WindowUtil.onClose = prevWindowOnClose;
        
        super.destroy();
    }
}

enum abstract PageType(String) from String to String {
    final MAIN = "Main";
    final CHANGE_DIFF = "Change Difficulty";
}

typedef PauseMenuStat = {
    var name:String;
    var ?keepLastY:Bool;
    var ?visible:Bool;
}