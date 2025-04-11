package funkin.states.menus;

import flixel.text.FlxText;

import funkin.ui.AtlasText;
import funkin.ui.AtlasTextList;

import funkin.backend.WeekData;
import funkin.backend.ContentMetadata;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.SongMetadata;

import funkin.states.editors.ChartEditor;

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
    
    public var songs:Map<String, Array<FreeplaySongData>> = [];
    public var listeningSong:String = "";

    public var grpSongs:AtlasTextList;

    public var curDifficulty:String = "normal";
    public var curMix:String = "default";

    public var scoreBG:FlxSprite;

    public var scoreText:FlxText;
    public var diffText:FlxText;

    public var hintBG:FlxSprite;

    public var hintText:FlxText;
    public var categoryText:FlxText;
    
    override function create():Void {
        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_blue"));
        bg.screenCenter();
        add(bg);

        grpSongs = new AtlasTextList();
        add(grpSongs);

        for(contentFolder in Paths.contentFolders) {
            final contentMetadata:ContentMetadata = Paths.contentMetadata.get(contentFolder);
            if(contentMetadata == null)
                continue; // if no metadata was found for this content pack, then don't bother

            for(category in contentMetadata.freeplayCategories) {
                categories.push({
                    id: '${contentFolder}:${category.id}',
                    name: category.name
                });
            }
            for(week in contentMetadata.weeks) {
                final categoryID:String = '${contentFolder}:${week.freeplayCategory}';
                if(!songs.exists(categoryID))
                    songs.set(categoryID, []);

                final category:Array<FreeplaySongData> = songs.get(categoryID);
                for(song in week.songs) {
                    if(week.hiddenSongs.freeplay.contains(song))
                        continue;

                    if(!FlxG.assets.exists(Paths.json('gameplay/songs/${song}/default/metadata', contentFolder)))
                        continue;

                    final defaultMetadata:SongMetadata = SongMetadata.load(song, null, contentFolder);
                    final metadataMap:Map<String, SongMetadata> = ["default" => defaultMetadata];
                    
                    for(mix in defaultMetadata.song.mixes)
                        metadataMap.set(mix, SongMetadata.load(song, mix, contentFolder));

                    final difficultyMap:Map<String, Array<String>> = ["default" => defaultMetadata.song.difficulties];
                    for(metadata in metadataMap) {
                        for(mix in metadata.song.mixes)
                            difficultyMap.set(mix, metadataMap.get(mix).song.difficulties);
                    }
                    category.push({
                        metadata: metadataMap,
                        id: song,
                        difficulties: difficultyMap
                    });
                }
            }
        }
        for(category in categories.copy()) {
            final songList:Array<FreeplaySongData> = songs.get(category.id);
            if(songList != null && songList.length != 0)
                continue;

            // no songs were found for this category
            Logs.warn('No songs found for category "${category.id}"');

            // which means it'd be pointless to show it, so remove it
            songs.remove(category.id);
            categories.remove(category);
        }
		scoreBG = new FlxSprite((FlxG.width * 0.7) - 6, 0).makeGraphic(1, 66, 0x99000000);
		scoreBG.antialiasing = false;
		add(scoreBG);

        scoreText = new FlxText(scoreBG.x + 6, 5, 0, "PERSONAL BEST:0", 32);
		scoreText.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, CENTER);
		add(scoreText);
        
		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.setFormat(Paths.font("fonts/vcr"), 24, FlxColor.WHITE, CENTER);
		add(diffText);

        hintBG = new FlxSprite().makeSolid(FlxG.width, 26, FlxColor.BLACK);
		hintBG.y = FlxG.height - hintBG.height;
		hintBG.alpha = 0.6;
		add(hintBG);

		hintText = new FlxText(hintBG.x, hintBG.y + 4, 0, "Q/E - Change Category | CTRL - Gameplay Modifiers | SPACE - Listen to Song");
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

        super.create();
    }

    override function update(elapsed:Float) {
        scoreText.text = 'PERSONAL BEST:N/A';
        positionHighscore();

        if(FlxG.keys.justPressed.Q)
            changeCategory(-1);

        if(FlxG.keys.justPressed.E)
            changeCategory(1);

        if(controls.justPressed.UI_LEFT)
            changeDifficulty(-1);

        if(controls.justPressed.UI_RIGHT)
            changeDifficulty(1);

        if(controls.justPressed.BACK) {
            FlxG.switchState(new MainMenuState());
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
        var tryingToListen:Bool = false;
        if(FlxG.keys.justPressed.SPACE) {
            final song:FreeplaySongData = songs.get(categories[curCategory].id)[curSelected];
            final newListeningSong:String = '${categories[curCategory].id}:${song.id}:${curMix}';

            if(newListeningSong != listeningSong) {
                tryingToListen = true;
                grpSongs.active = false;
                
                FlxG.sound.playMusic(Paths.sound('gameplay/songs/${song.id}/${curMix}/music/inst'), 0, false);
                FlxG.sound.music.fadeIn(2.0, 0.0, 1.0);
                
                final meta:SongMetadata = song.metadata.get(curMix);
                Conductor.instance.reset(meta.song.timingPoints.first()?.bpm ?? 100.0);
                Conductor.instance.setupTimingPoints(meta.song.timingPoints);

                listeningSong = newListeningSong;
            }
        }
        super.update(elapsed);

        if(tryingToListen)
            grpSongs.active = true;
    }

    public function changeCategory(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        grpSongs.clearList();
        curCategory = FlxMath.wrap(curCategory + by, 0, categories.length - 1);

        for(song in songs.get(categories[curCategory].id)) {
            grpSongs.addItem(song.metadata.get("default").song.title, {
                onSelect: onChangeSelection,
                onAccept: onAccept
            });
        }
        curSelected = 0;
        grpSongs.curSelected = 0;

        curDifficulty = "normal";
        curMix = "default";

        final song:FreeplaySongData = songs.get(categories[curCategory].id)[curSelected];
        final meta:SongMetadata = song.metadata.get(curMix);
        
        if(!meta.song.difficulties.contains(curDifficulty))
            curDifficulty = meta.song.difficulties.first();

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

        final song:FreeplaySongData = songs.get(categories[curCategory].id)[curSelected];
        final defaultMeta:SongMetadata = song.metadata.get("default");

        var meta:SongMetadata = song.metadata.get(curMix);
        if(meta == null) {
            curMix = "default"; // fallback to default mix
            curDifficulty = "normal"; // attempt to fallback to normal diff, if this fails the code below should correct it
            meta = song.metadata.get(curMix);
        }
        var newDiffIndex:Int = meta.song.difficulties.indexOf(curDifficulty) + by;

        if(newDiffIndex < 0) {
            // go back a mix
            curMix = defaultMeta.song.mixes[FlxMath.wrap(defaultMeta.song.mixes.indexOf(curMix) - 1, 0, defaultMeta.song.mixes.length - 1)];
            meta = song.metadata.get(curMix);

            // reset difficulty to first of this mix
            curDifficulty = meta.song.difficulties.last() ?? "normal";
        }
        else if(newDiffIndex > meta.song.difficulties.length - 1) {
            // go forward a mix
            curMix = defaultMeta.song.mixes[FlxMath.wrap(defaultMeta.song.mixes.indexOf(curMix) + 1, 0, defaultMeta.song.mixes.length - 1)];
            meta = song.metadata.get(curMix);

            // reset difficulty to first of this mix
            curDifficulty = meta.song.difficulties.first() ?? "normal";
        }
        else {
            // change difficulty but keep current mix
            curDifficulty = meta.song.difficulties[newDiffIndex];
        }
        final showArrows:Bool = (meta.song.difficulties.length > 1 || defaultMeta.song.mixes.length > 1);
        diffText.text = '${(showArrows) ? "< " : ""}${curDifficulty.toUpperCase()}${(showArrows) ? " >" : ""}';
        positionHighscore();
    }

    public function positionHighscore():Void {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		diffText.x = Std.int(scoreBG.x + scoreBG.width / 2);
		diffText.x -= (diffText.width / 2);
	}

    public function onAccept(index:Int, item:AtlasText):Void {
        if(FlxG.keys.pressed.SHIFT)
            loadIntoCharter();
        else
            loadIntoSong();

        FlxG.sound.music.fadeOut(0.16, 0);
    }

    public function loadIntoCharter():Void {
        final songData:FreeplaySongData = songs.get(categories[curCategory].id)[curSelected];
        FlxG.switchState(ChartEditor.new.bind({
            song: songData.id,
            difficulty: curDifficulty,
            mix: curMix
        }));
    }

    public function loadIntoSong():Void {
        final songData:FreeplaySongData = songs.get(categories[curCategory].id)[curSelected];
        FlxG.switchState(PlayState.new.bind({
            song: songData.id,
            difficulty: curDifficulty,
            mix: curMix
        }));
    }
}