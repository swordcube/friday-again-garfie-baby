package funkin.states.menus;

import flixel.text.FlxText;

import funkin.ui.UIUtil;
import funkin.ui.AtlasText;
import funkin.ui.AtlasTextList;

import funkin.backend.LevelData;
import funkin.backend.ContentMetadata;

import funkin.backend.events.Events;
import funkin.backend.events.MenuEvents;

import funkin.gameplay.song.Highscore;
import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.SongMetadata;

import funkin.states.editors.ChartEditor;

import funkin.substates.ResetScoreSubState;
import funkin.substates.GameplayModifiersMenu;

@:structInit
class FreeplaySongData {
    public var metadata:Map<String, SongMetadata>;
    public var id:String;
    public var difficulties:Map<String, Array<String>>;
}

class FreeplayState extends FunkinState {
    public static var curSelected:Int = 0;
    public static var curCategory:Int = 0;
    
    public var bg:FlxSprite;

    public var categories:Array<FreeplayCategory> = [];
    public var categoryMap:Map<String, FreeplayCategory> = [];
    
    public var songs:Array<FreeplaySongData> = [];
    public var songListMap:Map<String, Array<FreeplaySongData>> = [];
    
    public var listeningSong:String = "";

    public var grpSongs:AtlasTextList;

    public var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;
    public var currentMix:String = "default";

    public var scoreBG:FlxSprite;

    public var scoreText:FlxText;
    public var diffText:FlxText;

    public var rankBadge:FlxSprite;
    public var accuracyText:FlxText;

    public var hintBG:FlxSprite;

    public var hintText:FlxText;
    public var categoryText:FlxText;

    public var lerpScore:Float = 0;
    public var intendedScore:Int = 0;
    public var curScoreRecord:ScoreRecord;

    public var cachedOpponentMode:Null<Bool> = null;
    
    override function create():Void {
        super.create();

        if(FlxG.sound.music != null)
            FlxG.sound.music.looped = true;

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_blue"));
        bg.screenCenter();
        add(bg);

        grpSongs = new AtlasTextList();
        add(grpSongs);

        call("onGenerateCategories", [categories]);
        for(contentPack in Paths.getEnabledContentPacks()) {
            final contentMetadata:ContentMetadata = Paths.contentMetadata.get(contentPack);
            if(contentMetadata == null)
                continue; // if no metadata was found for this content pack, then don't bother
            
            for(category in contentMetadata.freeplayCategories) {
                categories.push({
                    id: '${contentPack}:${category.id}',
                    name: category.name
                });
                categoryMap.set('${contentPack}:${category.id}', category);
            }
            for(level in contentMetadata.levels) {
                if(!level.showInFreeplay)
                    continue;

                final categoryID:String = '${contentPack}:${level.freeplayCategory}';
                if(!songListMap.exists(categoryID))
                    songListMap.set(categoryID, []);

                final validSongs:Array<String> = [];
                for(song in level.songs) {
                    if(level.hiddenSongs.freeplay.contains(song))
                        continue;

                    if(!FlxG.assets.exists(Paths.json('gameplay/songs/${song}/default/metadata', contentPack)))
                        continue;

                    validSongs.push(song);
                }
                addSongsToCategory(level.freeplayCategory, validSongs, contentPack);
            }
        }
        call("onGenerateCategoriesPost", [categories]);

        for(category in categories.copy()) {
            final songList:Array<FreeplaySongData> = songListMap.get(category.id);
            if(songList != null && songList.length != 0)
                continue;

            // no songs were found for this category
            Logs.warn('No songs found for category "${category.id}"');

            // which means it'd be pointless to show it, so remove it
            songListMap.remove(category.id);
            categories.remove(category);
        }
		scoreBG = new FlxSprite((FlxG.width * 0.7) - 6, 0).makeGraphic(1, 1, 0x99000000);
		scoreBG.antialiasing = false;
		add(scoreBG);

        scoreText = new FlxText(scoreBG.x + 6, 5, 0, "PERSONAL BEST:0", 32);
		scoreText.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, CENTER);
		add(scoreText);
        
		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.setFormat(Paths.font("fonts/vcr"), 24, FlxColor.WHITE, CENTER);
		add(diffText);

        rankBadge = new FlxSprite(scoreBG.x + 6, scoreBG.y + 70);
        rankBadge.frames = Paths.getSparrowAtlas("menus/freeplay/rank_badges");
        
        for(rank in Highscore.ALL_RANKS)
            rankBadge.animation.addByPrefix(rank, '${Std.string(rank).toUpperCase()} rank', 24, false);

        rankBadge.animation.play(Rank.LOSS);
        rankBadge.setGraphicSize(24, 24);
        rankBadge.updateHitbox();
        add(rankBadge);

        accuracyText = new FlxText(rankBadge.x + 30, rankBadge.y, 0, "• 93.57%", 20);
		accuracyText.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, CENTER);
		add(accuracyText);

        hintBG = new FlxSprite().makeSolid(FlxG.width, 26, FlxColor.BLACK);
		hintBG.y = FlxG.height - hintBG.height;
		hintBG.alpha = 0.6;
		add(hintBG);

		hintText = new FlxText(hintBG.x, hintBG.y + 4, 0, 'Q/E - Change Category | ${(UIUtil.correctModifierKey(CONTROL) == WINDOWS) ? "CMD" : "CTRL"} - Gameplay Modifiers | SPACE - Listen to Song');
		hintText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, RIGHT);
        hintText.x += FlxG.width - (hintText.width + 4);
		add(hintText);

        categoryText = new FlxText(hintBG.x + 4, hintBG.y + 4, 0, "N/A");
		categoryText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, LEFT);
		add(categoryText);

        final lastSelected:Int = curSelected;
        changeCategory(0, true);

        grpSongs.curSelected = lastSelected;
        grpSongs.changeSelection(0, true, false);

        #if mobile
        FlxG.touches.swipeThreshold.x = 500;
        FlxG.touches.swipeThreshold.y = 150;
        #end
        #if MOBILE_UI
        addBackButton(FlxG.width - 230, FlxG.height - 220, FlxColor.WHITE, goBack, 1.0);
        #end
        #if (FLX_MOUSE && !mobile)
        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;
        #end
    }

    override function update(elapsed:Float) {
        var tryingToListen:Bool = false;
        if(FlxG.keys.justPressed.SPACE) {
            final song:FreeplaySongData = songListMap.get(categories[curCategory].id)[curSelected];
            final newListeningSong:String = '${categories[curCategory].id}:${song.id}:${currentMix}';

            if(newListeningSong != listeningSong) {
                tryingToListen = true;
                grpSongs.active = false;
                
                FlxG.sound.playMusic(Paths.sound('gameplay/songs/${song.id}/${currentMix}/music/inst'), 0, true);
                FlxG.sound.music.fadeIn(2.0, 0.0, 1.0);
                
                final meta:SongMetadata = song.metadata.get(currentMix);
                Conductor.instance.reset(meta.song.timingPoints.first()?.bpm ?? 100.0);
                Conductor.instance.setupTimingPoints(meta.song.timingPoints);

                listeningSong = newListeningSong;
            }
        }
        super.update(elapsed);

        lerpScore = FlxMath.lerp(lerpScore, intendedScore, FlxMath.getElapsedLerp(0.4, elapsed));
        if(Math.abs(lerpScore - intendedScore) < 10)
            lerpScore = intendedScore;

        scoreText.text = 'PERSONAL BEST:${Math.floor(lerpScore)}';
        positionHighscore();

        final pointer = TouchUtil.touch;
        if(FlxG.keys.justPressed.Q || (SwipeUtil.swipeLeft && (pointer?.overlaps(scoreBG) ?? false) == false))
            changeCategory(-1);

        if(FlxG.keys.justPressed.E || (SwipeUtil.swipeRight && (pointer?.overlaps(scoreBG) ?? false) == false))
            changeCategory(1);

        if(controls.justPressed.UI_LEFT || (SwipeUtil.swipeLeft && (pointer?.overlaps(scoreBG) ?? false) == true))
            changeDifficulty(-1);

        if(controls.justPressed.UI_RIGHT || (SwipeUtil.swipeRight && (pointer?.overlaps(scoreBG) ?? false) == true))
            changeDifficulty(1);

        if(controls.justPressed.BACK) {
            goBack();
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
        if(controls.justPressed.RESET) {
            final song:FreeplaySongData = songListMap.get(categories[curCategory].id)[curSelected];
            
            var meta:SongMetadata = song.metadata.get(currentMix);
            if(meta == null)
                meta = song.metadata.get("default");

            final subState:ResetScoreSubState = new ResetScoreSubState(meta.song.title);
            subState.onAccept.add(() -> {
                final recordID:String = Highscore.getScoreRecordID(
                    song.id, currentDifficulty, currentMix, null,
                    Options.gameplayModifiers.get("opponentMode") == true && meta.game.allowOpponentMode
                );
                Highscore.resetScoreRecord(recordID);
                updateHighscore();
            });
            openSubState(subState);
        }
        final pressedCtrl:Bool = #if (mac || macos) FlxG.keys.justPressed.WINDOWS #else FlxG.keys.justPressed.CONTROL #end;
        if(pressedCtrl)
            openSubState(new GameplayModifiersMenu());

        final curSongData:FreeplaySongData = songListMap.get(categories[curCategory].id)[curSelected];

        var curSongMeta:SongMetadata = curSongData.metadata.get(currentMix);
        if(curSongMeta == null)
            curSongMeta = curSongData.metadata.get("default");

        final opponentMode:Bool = Options.gameplayModifiers.get("opponentMode") == true && curSongMeta.game.allowOpponentMode;
        if(cachedOpponentMode != opponentMode) {
            cachedOpponentMode = opponentMode;
            updateHighscore();
        }
        #if TEST_BUILD
        if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.G) {
            final recordID:String = Highscore.getScoreRecordID(
                curSongData.id, currentDifficulty, currentMix, null,
                opponentMode
            );
            Highscore.forceSaveScoreRecord(recordID, {
                score: FlxG.random.int(0, 999999),
                misses: 0,
                accuracy: 1,
                rank: GOLD,
                judges: [
                    "killer" => 0,
                    "sick" => 0,
                    "good" => 0,
                    "bad" => 0,
                    "shit" => 0,
                    "miss" => 0,
                    "cb" => 0
                ],
                version: Highscore.RECORD_VERSION
            });
            updateHighscore();
            Logs.success('Congrats! You cheated on ${curSongMeta.song.title} [${currentDifficulty.toUpperCase()} - ${currentMix.toUpperCase()}]! Fuck you');
        }
        #end
        if(tryingToListen)
            grpSongs.active = true;
    }

    public function goBack():Void {
        FlxG.switchState(MainMenuState.new);
    }

    public function addCategory(id:String, name:String, ?songIDs:Array<String>, ?contentPack:String):Void {
        if(contentPack == null)
            contentPack = Paths.forceContentPack;

        final category:FreeplayCategory = {
            id: '${contentPack}:${id}',
            name: name
        };
        categories.push(category);
        categoryMap.set('${contentPack}:${id}', category);
        
        addSongsToCategory(id, songIDs, contentPack);
    }

    public function addSongsToCategory(categoryID:String, ?songIDs:Array<String>, ?contentPack:String, ?priority:Int = 0):Void {
        if(contentPack == null)
            contentPack = Paths.forceContentPack;

        if(songIDs == null || songIDs.length == 0)
            return;

        var songList:Array<FreeplaySongData> = songListMap.get('${contentPack}:${categoryID}');
        if(songList == null) {
            songList = [];
            songListMap.set('${contentPack}:${categoryID}', songList);
        }
        for(song in songIDs) {
            final defaultMetadata:SongMetadata = SongMetadata.load(song, null, contentPack);
            final metadataMap:Map<String, SongMetadata> = ["default" => defaultMetadata];
            
            for(mix in defaultMetadata.song.mixes)
                metadataMap.set(mix, SongMetadata.load(song, mix, contentPack));

            final difficultyMap:Map<String, Array<String>> = ["default" => defaultMetadata.song.difficulties];
            for(metadata in metadataMap) {
                for(mix in metadata.song.mixes)
                    difficultyMap.set(mix, metadataMap.get(mix).song.difficulties);
            }
            final songData:FreeplaySongData = {
                metadata: metadataMap,
                id: song,
                difficulties: difficultyMap
            };
            songs.insert(songs.length - priority, songData);
            songList.insert(songList.length - priority, songData);
        }
    }

    public function removeSongsFromCategory(categoryID:String, ?songIDs:Array<String>, ?contentPack:String):Void {
        if(contentPack == null)
            contentPack = Paths.forceContentPack;

        if(songIDs == null || songIDs.length == 0)
            return;

        final songList:Array<FreeplaySongData> = songListMap.get('${contentPack}:${categoryID}');
        for(song in songIDs) {
            for(i in 0...songList.length) {
                final songData:FreeplaySongData = songList[i];
                if(songData.id == song) {
                    songs.remove(songData);
                    songList.remove(songData);
                    break;
                }
            }
        }
    }

    public function changeCategory(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        grpSongs.clearList();
        curCategory = FlxMath.wrap(curCategory + by, 0, categories.length - 1);

        for(song in songListMap.get(categories[curCategory].id)) {
            grpSongs.addItem(song.metadata.get("default").song.title, {
                onSelect: onChangeSelection,
                onAccept: onAccept
            });
        }
        curSelected = 0;
        grpSongs.curSelected = 0;

        currentDifficulty = "normal";
        currentMix = "default";

        final song:FreeplaySongData = songListMap.get(categories[curCategory].id)[curSelected];
        final meta:SongMetadata = song.metadata.get(currentMix);
        
        if(!meta.song.difficulties.contains(currentDifficulty))
            currentDifficulty = meta.song.difficulties.first();

        categoryText.text = categories[curCategory].name;
        grpSongs.changeSelection(0, true);
    }

    public function onChangeSelection(index:Int, item:AtlasText):Void {
        curSelected = index;
        changeDifficulty(0, true);
    }

    public function changeDifficulty(by:Int = 0, ?force:Bool):Void {
        if(by == 0 && !force)
            return;

        final contentPack:String = categories[curCategory].id.split(":").first();
        Paths.forceContentPack = (contentPack.length > 0 && contentPack != "default") ? contentPack : null;

        final song:FreeplaySongData = songListMap.get(categories[curCategory].id)[curSelected];
        final defaultMeta:SongMetadata = song.metadata.get("default");

        var meta:SongMetadata = song.metadata.get(currentMix);
        if(meta == null) {
            currentMix = "default"; // fallback to default mix
            currentDifficulty = Constants.DEFAULT_DIFFICULTY; // attempt to fallback to default diff, if this fails the code below should correct it
            meta = song.metadata.get(currentMix);
        }
        var newDiffIndex:Int = meta.song.difficulties.indexOf(currentDifficulty) + by;

        if(newDiffIndex < 0) {
            // go back a mix
            currentMix = defaultMeta.song.mixes[FlxMath.wrap(defaultMeta.song.mixes.indexOf(currentMix) - 1, 0, defaultMeta.song.mixes.length - 1)];
            meta = song.metadata.get(currentMix);

            // reset difficulty to first of this mix
            currentDifficulty = meta.song.difficulties.last() ?? Constants.DEFAULT_DIFFICULTY;
        }
        else if(newDiffIndex > meta.song.difficulties.length - 1) {
            // go forward a mix
            currentMix = defaultMeta.song.mixes[FlxMath.wrap(defaultMeta.song.mixes.indexOf(currentMix) + 1, 0, defaultMeta.song.mixes.length - 1)];
            meta = song.metadata.get(currentMix);

            // reset difficulty to first of this mix
            currentDifficulty = meta.song.difficulties.first() ?? Constants.DEFAULT_DIFFICULTY;
        }
        else {
            // change difficulty but keep current mix
            currentDifficulty = meta.song.difficulties[newDiffIndex];
        }
        // update the score & rank display
        updateHighscore();

        // update the difficulty display
        final showArrows:Bool = (meta.song.difficulties.length > 1 || defaultMeta.song.mixes.length > 1);
        diffText.text = '${(showArrows) ? "< " : ""}${currentDifficulty.toUpperCase()}${(showArrows) ? " >" : ""}';
        positionHighscore();

        // update discord rpc
        DiscordRPC.changePresence("Freeplay Menu", '${meta.song.title ?? song.id} [${currentDifficulty.toUpperCase()} - ${currentMix.toUpperCase()}]');
    }

    public function updateHighscore():Void {
        // update the score display
        final song:FreeplaySongData = songListMap.get(categories[curCategory].id)[curSelected];

        var meta:SongMetadata = song.metadata.get(currentMix);
        if(meta == null)
            meta = song.metadata.get("default");

        final recordID:String = Highscore.getScoreRecordID(
            song.id, currentDifficulty, currentMix, null,
            Options.gameplayModifiers.get("opponentMode") == true && meta.game.allowOpponentMode
        );
        curScoreRecord = Highscore.getScoreRecord(recordID);
        intendedScore = curScoreRecord.score;

        // update the rank display
        if(curScoreRecord.rank != UNKNOWN) {
            rankBadge.animation.play(curScoreRecord.rank, !rankBadge.visible);
            rankBadge.visible = true;
            
            accuracyText.text = '• ${FlxMath.roundDecimal(curScoreRecord.accuracy * 100, 2)}%';
            accuracyText.visible = true;
        } else {
            rankBadge.visible = false;
            accuracyText.visible = false;
        }
    }

    public function positionHighscore():Void {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x * 0.5;

        scoreBG.scale.y = (curScoreRecord.rank != UNKNOWN) ? 96 : 66;
        scoreBG.y = scoreBG.scale.y * 0.5;

		diffText.x = Std.int(scoreBG.x + scoreBG.width * 0.5);
		diffText.x -= (diffText.width * 0.5);
        
        rankBadge.x = scoreBG.x - ((accuracyText.width + 32) * 0.5);
        accuracyText.x = rankBadge.x + 32;
	}

    public function onAccept(index:Int, item:AtlasText):Void {
        final categoryID:String = categories[curCategory].id;
        final songData:FreeplaySongData = songListMap.get(categoryID)[curSelected];

        final e:FreeplaySongAcceptEvent = cast Events.get(FREEPLAY_SONG_ACCEPT);
        e.recycle(
            songData.id, currentDifficulty, currentMix,
            categoryID.split(":").first(), FlxG.keys.pressed.SHIFT
        );
        call("onAccept", [e]);

        if(e.cancelled)
            return;

        if(e.goingToChartEditor)
            loadIntoCharter();
        else
            loadIntoSong();

        FlxG.sound.music.fadeOut(0.16, 0);
        call("onAcceptPost", [e.flagAsPost()]);
    }

    public function loadIntoCharter():Void {
        final categoryID:String = categories[curCategory].id;
        final songData:FreeplaySongData = songListMap.get(categoryID)[curSelected];

        FlxG.switchState(ChartEditor.new.bind({
            song: songData.id,
            difficulty: currentDifficulty,
            mix: currentMix,
            mod: categoryID.split(":").first()
        }));
    }

    public function loadIntoSong():Void {
        final categoryID:String = categories[curCategory].id;
        final songData:FreeplaySongData = songListMap.get(categoryID)[curSelected];

        PlayState.deathCounter = 0;
        PlayState.lastParams = {
            song: songData.id,
            difficulty: currentDifficulty,
            mix: currentMix,
            mod: categoryID.split(":").first()
        };
		LoadingState.loadIntoGameplay();
    }

    private var lastMouseVisible:Bool = true;

    override function destroy():Void {
        #if (FLX_MOUSE && !mobile)
        FlxG.mouse.visible = lastMouseVisible;
        #end
        Paths.forceContentPack = null;
        super.destroy();
    }
}