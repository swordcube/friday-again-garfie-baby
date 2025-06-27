package funkin.states;

// self-explanatory, meant for gameplay but
// could theoretically be used for menus

import sys.thread.Deque;
import sys.thread.Thread;

import openfl.media.Sound;
import openfl.utils.Assets as OpenFLAssets;

import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;

import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;

import funkin.backend.InitState;

import funkin.backend.assets.Cache.AssetPreload;
import funkin.backend.assets.Cache.AssetPreloadType;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.SongMetadata;

import funkin.gameplay.stage.StageData;
import funkin.gameplay.character.CharacterData;

import funkin.gameplay.UISkin;
import funkin.gameplay.UISkin.UISkinData;

import funkin.gameplay.notes.NoteSkin;
import funkin.gameplay.notes.NoteSkin.NoteSkinData;

// TODO: add the fucking lasagna asset.

class LoadingState extends FunkinState {
    public var params:LoadingStateParams;

    public var assetsLoaded:Int = 0;
    public var totalAssetCount:Int = 0;

    public var spinner:FlxSprite;
    public var statusText:FlxText;
    public var pressEnter:FlxSprite;

    public var transitioning:Bool = false;
    public var finished:Bool = false;

    public function new(params:LoadingStateParams) {
        super();
        this.params = params;
    }

    public static function loadIntoState(nextState:NextState, ?assetsToLoad:Array<AssetPreload>):Void {
        if(Options.loadingScreen && assetsToLoad != null && assetsToLoad.length != 0) {
            FlxG.switchState(() -> new LoadingState({
                nextState: nextState,
                assetsToLoad: assetsToLoad
            }));
        } else
            FlxG.switchState(nextState);
    }

    public static function loadIntoGameplay(?assetsToLoad:Array<AssetPreload>):Void {
        final nextState:NextState = () -> new PlayState();
        if(Options.loadingScreen) {
            FlxG.switchState(() -> new LoadingState({
                nextState: nextState,
                assetsToLoad: assetsToLoad,
                goingToGameplay: true
            }));
        } else
            FlxG.switchState(nextState);
    }

    override function create():Void {
        super.create();
        persistentUpdate = true;

        // setup the sprites
        spinner = new FunkinSprite();
        spinner.loadGraphic(Paths.image('menus/loading/spinner'));
        spinner.setGraphicSize(48, 48);
        spinner.updateHitbox();
        spinner.setPosition(
            FlxG.width - spinner.width - 30,
            FlxG.height - spinner.height - 30
        );
        add(spinner);

        statusText = new FlxText(30, 0, 'Loading...');
        statusText.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, LEFT);
        statusText.setPosition(30, FlxG.height - statusText.height - 30);
        statusText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        add(statusText);

        pressEnter = new FunkinSprite().loadFromSheet('menus/loading/press_enter', 'idle', 8);
        pressEnter.scale.set(0.3, 0.3);
        pressEnter.updateHitbox();
        pressEnter.setPosition(FlxG.width - pressEnter.width - 30, FlxG.height);
        pressEnter.alpha = 0;
        pressEnter.kill();
        add(pressEnter);

        FlxTween.tween(spinner, {angle: 360}, 5, {type: LOOPING});

        // prepare gameplay assets to load
        // this assumes goingToGameplay was set, along with PlayState.lastParams!
        if(params.goingToGameplay) {
            trace("we goin to gameplay");

            // cache some vars up here for convenience
            final songName:String = PlayState.lastParams.song;
            final songMix:String = PlayState.lastParams.mix ?? "default";
            final contentPack:String = PlayState.lastParams.mod;

            // load song stuff, we need it to load more than just the inst!
            final chart:ChartData = ChartData.load(songName, songMix, contentPack);
            chart.meta = SongMetadata.load(songName, songMix, contentPack);
            PlayState.lastParams._chart = chart;
            
            // init the array, we don't want no null object references in this house!
            final extras:Array<AssetPreload> = params.assetsToLoad ?? new Array<AssetPreload>();
            params.assetsToLoad = [];

            // always try to load inst, if it doesn't exist
            // then                 What The Fuck Happened.
            params.assetsToLoad.push({
                type: SOUND,
                path: Paths.sound('gameplay/songs/${songName}/${songMix}/music/inst', contentPack),
            });

            // try to load vocal tracks
            final spectatorTracks:Array<String> = [];
            final opponentTracks:Array<String> = [];
            final playerTracks:Array<String> = [];

            if(chart.meta.song.tracks != null) {
                for(i => tracks in [chart.meta.song.tracks.spectator, chart.meta.song.tracks.opponent, chart.meta.song.tracks.player]) {
                    if(tracks == null)
                        continue;
                    
                    final trackArray:Array<String> = switch(i) {
                        case 0: spectatorTracks;
                        case 1: opponentTracks;
                        case 2: playerTracks;
                        default: null;
                    };
                    for(fileName in tracks) {
                        final assetPath:String = Paths.sound('gameplay/songs/${songName}/${songMix}/music/${fileName}', contentPack);
                        if(!FlxG.assets.exists(assetPath))
                            continue;
                        
                        trackArray.push(fileName);
                    }
                }
            } else {
                for(i => char in [chart.meta.game.characters.get("spectator"), chart.meta.game.characters.get("opponent"), chart.meta.game.characters.get("player")]) {
                    final trackArray:Array<String> = switch(i) {
                        case 0: spectatorTracks;
                        case 1: opponentTracks;
                        case 2: playerTracks;
                        default: null;
                    };
                    for(fileName in ['vocals-${char}', 'Vocals-${char}', 'voices-${char}', 'Voices-${char}']) {
                        final assetPath:String = Paths.sound('gameplay/songs/${songName}/${songMix}/music/${fileName}', contentPack);
                        if(!FlxG.assets.exists(assetPath))
                            continue;
                        
                        trackArray.push(fileName);
                    }
                }
                for(fileName in ["vocals", "Vocals", "voices", "Voices"]) {
                    final assetPath:String = Paths.sound('gameplay/songs/${songName}/${songMix}/music/${fileName}', contentPack);
                    if(!FlxG.assets.exists(assetPath))
                        continue;
                    
                    if(spectatorTracks.length == 0)
                        spectatorTracks.push(fileName);
                }
            }
            for(trackList in [spectatorTracks, opponentTracks, playerTracks]) {
                for(track in trackList) {
                    params.assetsToLoad.push({
                        type: SOUND,
                        path: Paths.sound('gameplay/songs/${songName}/${songMix}/music/${track}', contentPack)
                    });
                }
            }
            // try to preload stage assets
            final stageData:StageData = StageData.load(chart.meta.game.stage);
            if(stageData.preload != null) {
                for(rawAsset in stageData.preload) {
                    switch(rawAsset.type) {
                        case IMAGE:
                            rawAsset.path = Paths.image('${stageData.getImageFolder()}/${rawAsset.path}');
                        
                        case SOUND:
                            rawAsset.path = Paths.sound('${stageData.getSFXFolder()}/${rawAsset.path}');
                    }
                    params.assetsToLoad.push(rawAsset);
                }
            }
            // try to preload character assets
            for(char in [chart.meta.game.characters.get("spectator"), chart.meta.game.characters.get("opponent"), chart.meta.game.characters.get("player")]) {
                final data:CharacterData = CharacterData.load(char);
                params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/characters/${data.id}/${data.atlas.path}')});

                if(data.deathCharacter != null && data.deathCharacter.length != 0)
                    params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/characters/${data.deathCharacter}/${data.atlas.path}')});
            }
            // try to preload note & ui assets
            var noteSkin:String = chart.meta.game.noteSkin ?? "default";
            if(noteSkin == "default")
                noteSkin = Constants.DEFAULT_NOTE_SKIN;
            
            var uiSkin:String = chart.meta.game.uiSkin ?? "default";
            if(uiSkin == "default")
                uiSkin = Constants.DEFAULT_UI_SKIN;

            final noteSkinData:NoteSkinData = NoteSkin.get(noteSkin);
            final uiSkinData:UISkinData = UISkin.get(uiSkin);
            
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/noteskins/${noteSkin}/${noteSkinData.strum.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/noteskins/${noteSkin}/${noteSkinData.note.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/noteskins/${noteSkin}/${noteSkinData.splash.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/noteskins/${noteSkin}/${noteSkinData.hold.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/noteskins/${noteSkin}/${noteSkinData.holdCovers.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/noteskins/${noteSkin}/${noteSkinData.holdGradients.atlas.path}')});
            
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/uiskins/${uiSkin}/${uiSkinData.rating.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/uiskins/${uiSkin}/${uiSkinData.combo.atlas.path}')});
            params.assetsToLoad.push({type: IMAGE, path: Paths.image('gameplay/uiskins/${uiSkin}/${uiSkinData.countdown.atlas.path}')});

            // concat the previous array (if available) as extra assets to be loaded
            params.assetsToLoad = params.assetsToLoad.concat(extras);
        }
        // filter out any missing assets
        if(params.assetsToLoad != null && params.assetsToLoad.length != 0)
            params.assetsToLoad = params.assetsToLoad.filter((asset:AssetPreload) -> FlxG.assets.exists(asset.path));

        // init the amount of assets we're loading, so we can check when we're done
        _assetCounter = totalAssetCount = (params.assetsToLoad != null) ? params.assetsToLoad.length : 0;

        // put all of the assets onto the preloading queue
        for(asset in params.assetsToLoad)
            _preloadQueue.push(asset);

        // init the thread for loading assets
        FlxTimer.wait(0.7, () -> {
            Thread.create(_loadingScreen_workerLoop);
        });
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        final status:String = _statusQueue.pop(false);
        if(status != null) {
            statusText.text = status;
            statusText.y = FlxG.height - statusText.height - 30;

            if(status != "Finished!")
                FlxG.sound.play(Paths.sound('menus/sfx/scroll'));
        }
        if(finished) {
            if(!transitioning && (FlxG.keys.justPressed.ENTER || controls.justPressed.ACCEPT)) {
                transitioning = true;
                fadeToNextState();
            }
        } else {
            final msg:Message = _messageQueue.pop(false);
            if(msg != null) {
                switch(msg) {
                    case Loaded(asset, data):
                        switch(asset.type) {
                            case IMAGE:
                                final graph:FlxGraphic = cast data;
                                FlxG.bitmap.addGraphic(graph);
                            
                            case SOUND:
                                final key:String = asset.path;
                                final sound:Sound = cast data;
    
                                final canUseCache:Bool = OpenFLAssets.cache.enabled;
                                if(canUseCache)
                                    OpenFLAssets.cache.setSound(key, sound);
                        }
                        assetsLoaded++;
                        
                        if(assetsLoaded >= totalAssetCount)
                            _finished = true;
                    
                    case Finished: finishLoading();
                }
            }
        }
    }

    public function finishLoading():Void {
        finished = true;
        FlxTween.tween(spinner, {alpha: 0}, 0.5);
        FlxTween.tween(spinner, {y: FlxG.height}, 0.5, {ease: FlxEase.backOut});
        
        pressEnter.revive();
        FlxTween.tween(pressEnter, {alpha: 1}, 0.5);
        FlxTween.tween(pressEnter, {y: FlxG.height - pressEnter.height - 30}, 0.5, {ease: FlxEase.backOut, startDelay: 0.5});

        FlxG.sound.play(Paths.sound('menus/sfx/select'));
        _statusQueue.push("Finished!");
    }

    public function fadeToNextState():Void {
        FlxG.camera.fade(FlxColor.BLACK, 1, false, () -> {
            // wait a frame before switching state, so that the graphics are pushed to gpu
            FlxTimer.wait(0.001, () -> {
                // trick the game into not clearing assets on switch to gameplay
                // this SHOULD be okay because menus won't report playstate, and will clear assets anyways
                @:privateAccess
                InitState._lastState = PlayState;

                // switch! switch! switch! switch! switch! (bfdi ref)
                FlxG.switchState(params.nextState);
            });
        });
    }

    //----------- [ Private API ] -----------//

    private var _preloadQueue:Deque<AssetPreload> = new Deque<AssetPreload>(); // to be accessed by worker thread ONLY >:(
    private var _assetCounter:Int = 0; // to be accessed by worker thread ONLY >:(
        
    private var _messageQueue:Deque<Message> = new Deque<Message>(); // to be accessed by main thread ONLY >:(
    private var _statusQueue:Deque<String> = new Deque<String>(); // to be accessed by main thread ONLY >:(

    private var _finished:Bool = false;

    private function _loadingScreen_workerLoop():Void {
        while(true) {
            if(_finished) {
                _statusQueue.push('Finished!');
                _messageQueue.push(Finished);
                break;
            }
            final msg:AssetPreload = _preloadQueue.pop(false);
            if(msg == null)
                continue;

            final contentFolder:String = Paths.getContentFolderFromPath(msg.path, true);
            _statusQueue.push('Loading ${msg.path.substr('${Paths.getContentDirectory()}/${contentFolder}/'.length)} (${(totalAssetCount - _assetCounter) + 1}/${totalAssetCount})');
            
            switch(msg.type) {
                case IMAGE:
                    final key:String = FlxG.bitmap.generateKey(msg.path, null);

                    final graph:FlxGraphic = FlxGraphic.fromAssetKey(msg.path, false, key, false);
                    Reflect.setProperty(graph, 'key', key); // bypass stupid haxe bullshit

                    _messageQueue.push(Loaded(msg, graph)); // offload adding to the cache to the main thread
                    
                case SOUND:
                    final sound:Sound = Sound.fromFile(msg.path);
                    _messageQueue.push(Loaded(msg, sound)); // offload adding to the cache to the main thread
            }
            _assetCounter--;
        }
    }
}

typedef LoadingStateParams = {
    var nextState:NextState;
    var assetsToLoad:Array<AssetPreload>;
    var ?goingToGameplay:Bool; // makes it easier to do gameplay specific shit
}

enum Message {
    Loaded(asset:AssetPreload, data:Dynamic);
    Finished;
}