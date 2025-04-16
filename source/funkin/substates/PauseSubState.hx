package funkin.substates;

import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import funkin.states.PlayState;
import funkin.states.menus.FreeplayState;
import funkin.substates.transition.FadeTransition;
import funkin.ui.AtlasText;
import funkin.ui.AtlasTextList;
import lime.app.Future;
import openfl.media.Sound;

#if SCRIPTING_ALLOWED
import funkin.scripting.GlobalScript;
#end

@:access(funkin.states.PlayState)
class PauseSubState extends FunkinSubState {
    public static final CHARTER_FADE_DELAY:Float = 15.0;
    public static final CHARTER_FADE_DURATION:Float = 0.75;

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
        lastTimeScale = FlxG.timeScale;
        FlxG.timeScale = 1;

        prevWindowOnClose = WindowUtil.onClose;

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        bg = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, FlxColor.BLACK);
		bg.alpha = 0;
		bg.screenCenter();
		add(bg);

        FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {
            tmr.paused = true;
            pausedTimers.push(tmr);
        });
        FlxTween.globalManager.forEach((twn:FlxTween) -> {
            twn.paused = true;
            pausedTweens.push(twn);
        });
        grpItems = new AtlasTextList();
        grpItems.active = false;
        add(grpItems);

        grpStats = new FlxTypedContainer<FlxText>();
        add(grpStats);

        pauseMusic = new FlxSound();
        FlxG.sound.list.add(pauseMusic);
        
        final musicThread:Future<Sound> = CoolUtil.createASyncFuture(() -> {
            return FlxG.assets.getSound(Paths.sound('menus/music/breakfast/music'));
        });
        musicThread.onComplete((snd:Sound) -> {
            if(pauseMusic != null) {
                pauseMusic.loadEmbedded(snd, true);

                pauseMusic.time = FlxG.random.int(0, Std.int(FlxG.sound.music.length / 2));
                pauseMusic.volume = 0;
                
                pauseMusic.play();
                pauseMusic.fadeIn(20, 0, 0.5);
            }
        });
        musicThread.onError((e:Dynamic) -> {});

        regenerateItems(MAIN);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

        final game:PlayState = PlayState.instance;
        final stats:Array<PauseMenuStat> = [
            {name: game.currentChart.meta.song.title},
            {name: 'Artist: ${game.currentChart.meta.song.artist}'},
            {name: 'Difficulty: ${game.currentDifficulty.toUpperCase()}'},
            {name: 'N/A Blue Balls'}, // TODO: make this actually do something
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
                unsafeExitToMenu();
            });
            warning.onCancel.add(() -> {
                WindowUtil.resetClosing();
                warning.close();
            });
            openSubState(warning);
        };
        super.create();
    }

    override function update(elapsed:Float):Void {
        if(inputAllowed)
            grpItems.active = true;

        inputAllowed = true;
        super.update(elapsed);
    }

    public function regenerateItems(page:PageType):Void {
        grpItems.clearList();
        switch(page) {
            case MAIN:
                final game:PlayState = PlayState.instance;
                grpItems.addItem("Resume", {onAccept: (_, _) -> resume()});
                grpItems.addItem("Restart Song", {onAccept: (_, _) -> restartSong()});

                if(game.currentChart.meta.song.difficulties.length > 1)
                    grpItems.addItem("Change Difficulty", {onAccept: (_, _) -> regenerateItems(CHANGE_DIFF)});

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
        grpItems.curSelected = 0;
        grpItems.changeSelection(0, true);
    }

    public function resume():Void {
        for(timer in pausedTimers)
            timer.paused = false;

        for(tween in pausedTweens)
            tween.paused = false;

        Conductor.instance.music = FlxG.sound.music;
        Conductor.instance.autoIncrement = true;

        final game:PlayState = PlayState.instance;
        game.camGame.followEnabled = true;

        if(!game.startingSong) {
            FlxG.sound.music.time = Conductor.instance.rawTime;
            FlxG.sound.music.resume();

            game.vocals.seek(FlxG.sound.music.time);
            game.vocals.resume();
        }
        close();
    }

    public function restartSong():Void {
        FlxTimer.wait(0.001, () -> {
            final game:PlayState = PlayState.instance;

            FlxG.sound.music.pause();
            game.vocals.pause();

            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            if(FlxG.keys.pressed.SHIFT) {
                FlxG.signals.preStateCreate.addOnce((_) -> {
                    Cache.clearAll();
                    Paths.reloadContent();

                    #if SCRIPTING_ALLOWED
                    GlobalScript.reloadScripts();
                    #end
                });
            }
            Cache.noteSkinCache.clear();
            Cache.uiSkinCache.clear();

            FadeTransition.nextCamera = transitionCam;
            FlxG.signals.postStateSwitch.addOnce(() -> {
                FlxG.cameras.remove(FadeTransition.nextCamera);
            });
            FlxG.sound.music.onComplete = null;
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

    public function unsafeExitToMenu():Void {
        // TODO: story mode
        FlxTimer.wait(0.001, () -> {
            FlxG.sound.music.volume = 0;
            FlxG.sound.music.looped = true;
            FlxG.sound.music.play();
            FlxG.sound.music.fadeIn(0.16, 0, 1);

            final transitionCam:FlxCamera = new FlxCamera();
            transitionCam.bgColor = 0;
            FlxG.cameras.add(transitionCam, false);

            FadeTransition.nextCamera = transitionCam;
            FlxG.signals.postStateSwitch.addOnce(() -> {
                FlxG.cameras.remove(FadeTransition.nextCamera);
            });
            FlxG.sound.music.onComplete = null;
            FlxG.switchState(FreeplayState.new);
        });
        close();
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

    override function destroy():Void {
        if(pauseMusic != null)
            pauseMusic = FlxDestroyUtil.destroy(pauseMusic);
        
        FlxG.timeScale = lastTimeScale;
        FlxG.cameras.remove(camera);
        
        WindowUtil.onClose = prevWindowOnClose;
        super.destroy();
    }
}

enum abstract PageType(String) from String to String {
    final MAIN = "main";
    final CHANGE_DIFF = "change_diff";
}

typedef PauseMenuStat = {
    var name:String;
    var ?keepLastY:Bool;
    var ?visible:Bool;
}