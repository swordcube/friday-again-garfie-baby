package funkin.states.menus;

import flixel.text.FlxText;

import funkin.backend.LevelData;
import funkin.backend.ContentMetadata;

import funkin.gameplay.song.Highscore;
import funkin.gameplay.song.SongMetadata;

import funkin.ui.story.*;

// TODO: level locking

@:structInit
class StorySongData {
    public var metadata:Map<String, SongMetadata>;
    public var id:String;
    public var difficulties:Map<String, Array<String>>;
}

class StoryMenuState extends FunkinState {
    public var levels:Array<LevelData> = [];
    public var songs:Map<String, Array<StorySongData>> = [];

    public var grpLevelTitles:FlxTypedContainer<LevelTitle>;

    public var scoreText:FlxText;
    public var banner:FlxSprite;

    public var tracksText:FlxSprite;
    public var trackList:FlxText;

    public var leftArrow:FlxSprite;
    public var rightArrow:FlxSprite;
    public var difficultySprites:Map<String, FlxSprite> = [];

    public var currentDifficulty:String = null;
    public var currentMix:String = null;
    
    public var curSelected:Int = 0;
    public var transitioning:Bool = false;

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
                    for(diffs in difficultyMap) {
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
                
                final title:LevelTitle = new LevelTitle(0, LevelTitle.Y_OFFSET + y, level.name, contentFolder);
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

        banner = new FlxSprite(0, 56).makeSolid(FlxG.width, 400, 0xFFF9CF51);
        add(banner);

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
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = FlxMath.wrap(curSelected + by, 0, grpLevelTitles.length - 1);

        for(i => title in grpLevelTitles.members)
            title.alpha = (curSelected == i) ? 1.0 : 0.6;
        
        final tracks:Array<String> = [];
        for(song in songs.get(levels[curSelected].name))
            tracks.push(song.metadata.get("default")?.song?.title ?? song.id);

        trackList.text = tracks.join("\n");
        trackList.screenCenter(X);
        trackList.x -= FlxG.width * 0.35;
        
        changeDifficulty(0, true);
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function changeDifficulty(by:Int = 0, ?force:Bool):Void {
        if(by == 0 && !force)
            return;

        final level:LevelData = levels[curSelected];
        final prevDifficulty:String = currentDifficulty;

        final contentPack:String = levels[curSelected].loaderID;
        Paths.forceContentPack = (contentPack.length > 0 && contentPack != "default") ? contentPack : null;

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
        // update the difficulty display
        if(currentDifficulty != prevDifficulty) {
            for(spr in difficultySprites)
                spr.visible = false;
            
            final difficultySpr:FlxSprite = difficultySprites.get('${Paths.forceContentPack}:${currentDifficulty}');
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
        
        grpLevelTitles.members[curSelected].startFlashing();

        transitioning = true;
        FlxG.sound.play(Paths.sound("menus/sfx/select"));
    }

    override function destroy():Void {
        Paths.forceContentPack = null;
        super.destroy();
    }
}