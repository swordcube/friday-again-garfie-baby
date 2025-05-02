package funkin.states.menus;

import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;

import funkin.backend.LevelData;
import funkin.backend.ContentMetadata;

import funkin.gameplay.PlayerStats;
import funkin.gameplay.song.Highscore;
import funkin.gameplay.song.SongMetadata;

import funkin.ui.story.*;
import funkin.ui.story.character.*;

// TODO: level locking

@:structInit
class StorySongData {
    public var metadata:Map<String, SongMetadata>;
    public var id:String;
    public var difficulties:Map<String, Array<String>>;
}

class StoryMenuState extends FunkinState {
    public var levels:Array<LevelData> = [];
    public var levelMap:Map<String, LevelData> = [];
    public var songs:Map<String, Array<StorySongData>> = [];

    public var grpLevelTitles:FlxTypedContainer<LevelTitle>;

    public var scoreText:FlxText;
    public var taglineText:FlxText;

    public var banner:FlxSprite;
    public var grpCharacters:FlxTypedContainer<StoryCharacter>;

    public var tracksText:FlxSprite;
    public var trackList:FlxText;

    public var leftArrow:FlxSprite;
    public var rightArrow:FlxSprite;
    public var difficultySprites:Map<String, FlxSprite> = [];

    public var currentDifficulty:String = null;
    public var currentMix:String = null;
    
    public var curSelected:Int = 0;
    public var transitioning:Bool = false;

    public var lerpScore:Float = 0;
    public var intendedScore:Int = 0;

    public var grpWarningTexts:FlxTypedContainer<FlxText>;

    override function create():Void {
        super.create();
        persistentUpdate = true;
        
        grpLevelTitles = new FlxTypedContainer<LevelTitle>();
        add(grpLevelTitles);

        for(contentFolder in Paths.contentFolders) {
            final contentMetadata:ContentMetadata = Paths.contentMetadata.get(contentFolder);
            if(contentMetadata == null)
                continue; // if no metadata was found for this content pack, then don't bother

            var i:Int = 0;
            var y:Float = 0;
            for(level in contentMetadata.levels) {
                if(!level.showInStory)
                    continue;

                if(songs.get(level.name) == null)
                    songs.set(level.name, []);
                
                level.loaderID = contentFolder;
                for(song in level.songs) {
                    if(level.hiddenSongs.story.contains(song))
                        continue;

                    final metaExists:Bool = FlxG.assets.exists(Paths.json('gameplay/songs/${song}/default/metadata', contentFolder));
                    // if(!metaExists)
                    //     continue;

                    final defaultMetadata:SongMetadata = (metaExists) ? SongMetadata.load(song, null, contentFolder) : null;
                    final metadataMap:Map<String, SongMetadata> = ["default" => defaultMetadata];
                    final difficultyMap:Map<String, Array<String>> = ["default" => defaultMetadata?.song?.difficulties ?? ["easy", "normal", "hard", "challenge"]];
                    
                    if(defaultMetadata != null) {
                        for(mix in defaultMetadata.song.mixes)
                            metadataMap.set(mix, SongMetadata.load(song, mix, contentFolder));
    
                        for(metadata in metadataMap) {
                            for(mix in metadata.song.mixes)
                                difficultyMap.set(mix, metadataMap.get(mix).song.difficulties);
                        }
                    }
                    final songList:Array<StorySongData> = songs.get(level.name);
                    songList.push({
                        metadata: metadataMap,
                        id: song,
                        difficulties: difficultyMap
                    });
                }
                final songList:Array<StorySongData> = songs.get(level.name);
                if(songList.length == 0)
                    continue;

                for(diffs in level.difficulties) {
                    for(diff in diffs) {
                        final key:String = '${contentFolder}:${diff}';
                        if(difficultySprites.exists(key))
                            continue;
    
                        final spr:FlxSprite = new FlxSprite();
                        if(FlxG.assets.exists(Paths.xml('menus/story/difficulties/${diff}', contentFolder))) {
                            spr.frames = Paths.getSparrowAtlas('menus/story/difficulties/${diff}', contentFolder);
                            spr.animation.addByPrefix("idle", "idle", 24); // TODO: add a config json for these??
                            spr.animation.play("idle");
                        } else
                            spr.loadGraphic(Paths.image('menus/story/difficulties/${diff}', contentFolder));
                        
                        difficultySprites.set(key, spr);
                    }
                }
                for(characterID in level.characters) {
                    if(characterID == null)
                        continue;

                    final character:StoryCharacter = new StoryCharacter(characterID);
                    graphicCache.cache(character.graphic);
                    character.destroy();
                }
                levelMap.set(level.name, level);
                
                final title:LevelTitle = new LevelTitle(0, LevelTitle.Y_OFFSET + y, level.name, isLevelLocked(level.name), contentFolder);
                title.screenCenter(X);
                grpLevelTitles.add(title);
                y += title.height;

                levels.push(level);
                i++;
            }
        }
        scoreText = new FlxText(10, 10, 0, "LEVEL SCORE: 0");
        scoreText.setFormat(Paths.font("fonts/vcr"), 32);
        add(scoreText);

        taglineText = new FlxText(FlxG.width - 10, 10, 0, "NO TAGLINE SPECIFIED");
        taglineText.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, RIGHT);
        taglineText.alpha = 0.6;
        add(taglineText);

        banner = new FlxSprite(0, 56).makeSolid(FlxG.width, 400, 0xFFF9CF51);
        add(banner);

        grpCharacters = new FlxTypedContainer<StoryCharacter>();
        add(grpCharacters);

        // writing this for later
        // positioning characters: FlxG.width * 0.25 * index

        tracksText = new FlxSprite(0, 500).loadGraphic(Paths.image("menus/story/tracks"));
        tracksText.screenCenter(X);
        tracksText.x -= FlxG.width * 0.35;
        add(tracksText);

        trackList = new FlxText(0, tracksText.y + tracksText.height + 30, 0, "???\n???\n???");
        trackList.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, CENTER);
        trackList.color = 0xFFE55777;
        add(trackList);

        leftArrow = new FlxSprite(FlxG.width * 0.68, 480);
        leftArrow.frames = Paths.getSparrowAtlas("menus/story/ui/arrows");
        leftArrow.animation.addByPrefix("idle", "leftIdle", 24, false);
        leftArrow.animation.addByPrefix("press", "leftConfirm", 24, false);
        leftArrow.animation.play("idle");
        add(leftArrow);

        rightArrow = new FlxSprite(leftArrow.x + 375, 480);
        rightArrow.frames = Paths.getSparrowAtlas("menus/story/ui/arrows");
        rightArrow.animation.addByPrefix("idle", "rightIdle", 24, false);
        rightArrow.animation.addByPrefix("press", "rightConfirm", 24, false);
        rightArrow.animation.play("idle");
        add(rightArrow);

        final spr:FlxSprite = new FlxSprite();
        if(FlxG.assets.exists(Paths.xml('menus/story/difficulties/${Constants.DEFAULT_DIFFICULTY}'))) {
            spr.frames = Paths.getSparrowAtlas('menus/story/difficulties/${Constants.DEFAULT_DIFFICULTY}');
            spr.animation.addByPrefix("idle", "idle", 24); // TODO: add a config json for these??
            spr.animation.play("idle");
        } else
            spr.loadGraphic(Paths.image('menus/story/difficulties/${Constants.DEFAULT_DIFFICULTY}'));

        difficultySprites.set(Constants.DEFAULT_DIFFICULTY, spr);

        for(spr in difficultySprites) {
            spr.visible = false;
            add(spr);
        }
        grpWarningTexts = new FlxTypedContainer<FlxText>();
        add(grpWarningTexts);

        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        var y:Float = 0;
        var offset:Float = 0;

        var i:Int = 0;
        while(i < curSelected) {
            offset -= grpLevelTitles.members[i].height + 40;
            i++;
        }
        for(j in 0...grpLevelTitles.length) {
            final title:LevelTitle = grpLevelTitles.members[j];
            title.y = FlxMath.lerp(title.y, LevelTitle.Y_OFFSET + y + offset, FlxMath.getElapsedLerp(0.16, elapsed));
            y += title.height + 40;
        }
        super.update(elapsed);

        lerpScore = FlxMath.lerp(lerpScore, intendedScore, FlxMath.getElapsedLerp(0.4, elapsed));
        if(Math.abs(lerpScore - intendedScore) < 10)
            lerpScore = intendedScore;

        scoreText.text = 'LEVEL SCORE: ${FlxStringUtil.formatMoney(Math.floor(lerpScore), false)}';

        if(!transitioning) {
            final wheel:Float = -FlxG.mouse.wheel;
            if(controls.justPressed.UI_UP || wheel < 0)
                changeSelection(-1);
    
            if(controls.justPressed.UI_DOWN || wheel > 0)
                changeSelection(1);

            if(controls.justPressed.UI_LEFT) {
                leftArrow.animation.play("press");
                changeDifficulty(-1);
            }
            if(controls.justPressed.UI_RIGHT) {
                rightArrow.animation.play("press");
                changeDifficulty(1);
            }
            if(controls.justReleased.UI_LEFT)
                leftArrow.animation.play("idle");
            
            if(controls.justReleased.UI_RIGHT)
                rightArrow.animation.play("idle");
            
            if(controls.justPressed.ACCEPT)
                onSelect();

            if(controls.justPressed.BACK) {
                persistentUpdate = false;
                FlxG.switchState(new MainMenuState());
                FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            }
        }
        for(i => t in grpWarningTexts)
            t.y = 20 + (i * 20);
    }

    public function showWarning(warning:String):Void {
        final warningText:FlxText = new FlxText(0, 20, 0, warning);
        warningText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
        warningText.screenCenter(X);
        grpWarningTexts.add(warningText);

        FlxTween.tween(warningText, {alpha: 0}, 1, {ease: FlxEase.cubeInOut, startDelay: 2, onComplete: (_) -> {
            grpWarningTexts.remove(warningText, true);
            warningText.destroy();
        }});
    }

    public function isLevelLocked(name:String):Bool {
        final level:LevelData = levelMap.get(name);
        if(level == null)
            return false;
        
        var levelBeforeCompleted:Bool = false;
        var levelBefore:LevelData = (level.levelBefore != null && level.levelBefore.length != 0) ? levelMap.get(level.levelBefore) : null;
        
        if(levelBefore != null) {
            for(diffs in levelBefore.difficulties) {
                for(diff in diffs) {
                    if(Highscore.getLevelRecord(Highscore.getLevelRecordID(level.levelBefore, diff)).score > 0) {
                        levelBeforeCompleted = true;
                        break;
                    }
                }
            }
        }
        return !level.startUnlocked && (level.levelBefore != null && level.levelBefore.length != 0 && !levelBeforeCompleted);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        final prevSelected:Int = curSelected;
        curSelected = FlxMath.wrap(curSelected + by, 0, grpLevelTitles.length - 1);

        if(levels[curSelected].banner.startsWith("#")) {
            // hex color code for banner
            if(levels[prevSelected].banner.toUpperCase() != levels[curSelected].banner.toUpperCase()) {
                final oldBanner:FlxSprite = banner;
                banner = new FlxSprite(0, 56).makeSolid(FlxG.width, 400, FlxColor.fromString(levels[curSelected].banner));
                banner.alpha = 0;
                insert(members.indexOf(oldBanner) + 1, banner);
    
                FlxTween.tween(banner, {alpha: 1}, 0.9, {ease: FlxEase.quartOut, onComplete: (_) -> {
                    remove(oldBanner, true);
                    oldBanner.destroy();
                }});
            }
        } else {
            // image for banner
            if(levels[prevSelected].banner != levels[curSelected].banner) {
                final oldBanner:FlxSprite = banner;
                banner = new FlxSprite(0, 56).loadGraphic(Paths.image('menus/story/banners/${levels[curSelected].banner}'));
                banner.alpha = 0;
                insert(members.indexOf(oldBanner) + 1, banner);
    
                FlxTween.tween(banner, {alpha: 1}, 0.9, {ease: FlxEase.quartOut, onComplete: (_) -> {
                    remove(oldBanner, true);
                    oldBanner.destroy();
                }});
            }
        }
        final contentPack:String = levels[curSelected].loaderID;
        Paths.forceContentPack = (contentPack.length > 0 && contentPack != "default") ? contentPack : null;

        for(i => title in grpLevelTitles.members)
            title.alpha = (curSelected == i) ? 1.0 : 0.6;
        
        final tracks:Array<String> = [];
        for(song in songs.get(levels[curSelected].name))
            tracks.push(song.metadata.get("default")?.song?.title ?? song.id);

        for(i => characterID in levels[curSelected].characters) {
            if(characterID == null) {
                final character:StoryCharacter = grpCharacters.members[i];
                if(character != null)
                    character.visible = false;

                continue;
            }
            final oldCharacter:StoryCharacter = grpCharacters.members[i];
            if(oldCharacter == null || !oldCharacter.visible || oldCharacter.characterID != characterID) {
                if(oldCharacter != null) {
                    grpCharacters.remove(oldCharacter, true);
                    oldCharacter.destroy();
                }
                final newCharacter:StoryCharacter = new StoryCharacter(characterID);
                newCharacter.setPosition(FlxG.width * 0.25 * i, 400);
                grpCharacters.insert(i, newCharacter);
            }
        }
        trackList.text = tracks.join("\n");
        trackList.screenCenter(X);
        trackList.x -= FlxG.width * 0.35;

        taglineText.text = levels[curSelected].tagline;
        taglineText.x = FlxG.width - (taglineText.width + 10);
        
        changeDifficulty(0, true);
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function changeDifficulty(by:Int = 0, ?force:Bool):Void {
        if(by == 0 && !force)
            return;

        final level:LevelData = levels[curSelected];
        final prevDifficulty:String = currentDifficulty;

        var difficulties:Array<String> = level.difficulties.get(currentMix);
        if(difficulties == null) {
            currentMix = "default"; // fallback to default mix
            currentDifficulty = Constants.DEFAULT_DIFFICULTY; // attempt to fallback to default diff, if this fails the code below should correct it
            difficulties = level.difficulties.get(currentMix);
        }
        final newDiffIndex:Int = difficulties.indexOf(currentDifficulty) + by;
        if(newDiffIndex < 0) {
            // go back a mix
            currentMix = level.mixes[FlxMath.wrap(level.mixes.indexOf(currentMix) - 1, 0, level.mixes.length - 1)];
            
            // reset difficulty to last of this mix
            final difficulties:Array<String> = level.difficulties.get(currentMix) ?? ["easy", "normal", "hard"];
            currentDifficulty = difficulties.last() ?? Constants.DEFAULT_DIFFICULTY;
        }
        else if(newDiffIndex > difficulties.length - 1) {
            // go forward a mix
            currentMix = level.mixes[FlxMath.wrap(level.mixes.indexOf(currentMix) + 1, 0, level.mixes.length - 1)];
            
            // reset difficulty to first of this mix
            final difficulties:Array<String> = level.difficulties.get(currentMix) ?? ["easy", "normal", "hard"];
            currentDifficulty = difficulties.first() ?? Constants.DEFAULT_DIFFICULTY;
        }
        else {
            // change difficulty but keep current mix
            currentDifficulty = difficulties[newDiffIndex];
        }
        // update the score stuff
        final currentLevel:LevelData = levels[curSelected];
        intendedScore = Highscore.getLevelRecord(Highscore.getLevelRecordID(currentLevel.name, currentDifficulty)).score;

        // update the difficulty display
        if(currentDifficulty != prevDifficulty) {
            for(spr in difficultySprites)
                spr.visible = false;
            
            final difficultySpr:FlxSprite = difficultySprites.get('${Paths.forceContentPack}:${currentDifficulty}') ?? difficultySprites.get(Constants.DEFAULT_DIFFICULTY);
            difficultySpr.alpha = 0;
            difficultySpr.visible = true;
            difficultySpr.setPosition(leftArrow.x + leftArrow.width + ((difficultySprites.get(Constants.DEFAULT_DIFFICULTY).width - difficultySpr.width) * 0.5) + 10, leftArrow.y - 15);
    
            FlxTween.cancelTweensOf(difficultySpr);
            FlxTween.tween(difficultySpr, {y: leftArrow.y + ((difficultySprites.get(Constants.DEFAULT_DIFFICULTY).height - difficultySpr.height) * 0.5) + 10, alpha: 1}, 0.07);
        }
    }
    
    public function onSelect():Void {
        if(transitioning)
            return;

        if(isLevelLocked(levels[curSelected].name)) {
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            return;
        }
        var excludedSome:Bool = false;
        var pendingPlaylist:Array<String> = [];

        for(song in levels[curSelected].songs) {
            if(FlxG.assets.exists(Paths.json('gameplay/songs/${song}/default/metadata')))
                pendingPlaylist.push(song);
            else
                excludedSome = true;
        }
        if(pendingPlaylist.length != 0) {
            for(character in grpCharacters) {
                if(character.animation.exists(character.data.confirmAnim)) {
                    character.canDance = false;
                    character.animation.play(character.data.confirmAnim);
                }
            }
            FlxTimer.wait(1, () -> {
                PlayState.storyStats = new PlayerStats();
                PlayState.storyPlaylist = pendingPlaylist;
                PlayState.storyLevel = levels[curSelected].name;
                
                FlxG.switchState(PlayState.new.bind({
                    song: PlayState.storyPlaylist.shift(),
                    difficulty: currentDifficulty,
                    mix: currentMix,
                    mod: Paths.forceContentPack,
                    isStoryMode: true
                }));
                FlxG.sound.music.fadeOut(0.16, 0);
                grpLevelTitles.members[curSelected].stopFlashing();
            });
            grpLevelTitles.members[curSelected].startFlashing();

            if(excludedSome)
                showWarning("Some of the songs in this level are missing!");

            transitioning = true;
            FlxG.sound.play(Paths.sound("menus/sfx/select"));
        } else {
            showWarning("There are no valid songs in this level!");
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    override function destroy():Void {
        Paths.forceContentPack = null;
        super.destroy();
    }
}