package funkin.states.menus;

import flixel.text.FlxText;

import funkin.ui.AtlasText;
import funkin.backend.WeekData;

import funkin.gameplay.song.ChartData;
import funkin.gameplay.song.SongMetadata;

import funkin.states.editors.ChartEditor;

@:structInit
class FreeplaySongData {
    public var meta:Map<String, SongMetadata>;
    public var data:WeekSongData;
}

class FreeplayState extends FunkinState {
    public var bg:FlxSprite;
    public var songs:Array<FreeplaySongData> = [];

    public var curSelected:Int = 0;
    public var grpSongs:FlxTypedGroup<AtlasText>;

    public var curDifficulty:String = "normal";
    public var curMix:String = "default";

    public var scoreBG:FlxSprite;

    public var scoreText:FlxText;
    public var diffText:FlxText;
    
    override function create() {
        super.create();

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg_blue"));
        bg.screenCenter();
        add(bg);

        grpSongs = new FlxTypedGroup();
        add(grpSongs);

        for(weekList in WeekData.getWeekLists()) {
            for(weekID in weekList.data) {
                final weekData:WeekData = WeekData.load(weekID, weekList.loaderID);
                for(songData in weekData.songs) {
                    if(songData.hiddenOnFreeplay)
                        continue;

                    if(!FlxG.assets.exists(Paths.json('gameplay/songs/${songData.id}/default/meta', weekList.loaderID)))
                        continue;

                    final meta:SongMetadata = SongMetadata.load(songData.id, null, weekList.loaderID);
                    final metaMap:Map<String, SongMetadata> = ["default" => meta];
                    
                    for(mix in meta.song.mixes)
                        metaMap.set(mix, SongMetadata.load(songData.id, mix, weekList.loaderID));
                    
                    songs.push({
                        meta: metaMap,
                        data: songData
                    });
                    final text:AtlasText = new AtlasText(0, 0, "bold", LEFT, meta.song.title);
                    text.isMenuItem = true;
                    text.targetY = grpSongs.length;
                    grpSongs.add(text);
                }
            }
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

        changeSelection(0, true);
    }

    override function update(elapsed:Float) {
        scoreText.text = 'PERSONAL BEST:N/A';
        positionHighscore();

        if(controls.justPressed.UI_UP)
            changeSelection(-1);

        if(controls.justPressed.UI_DOWN)
            changeSelection(1);

        if(controls.justPressed.UI_LEFT)
            changeDifficulty(-1);

        if(controls.justPressed.UI_RIGHT)
            changeDifficulty(1);

        if(controls.justPressed.ACCEPT) {
            if(FlxG.keys.pressed.SHIFT)
                loadIntoCharter();
            else
                loadIntoSong();
        }
        super.update(elapsed);
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        var song:AtlasText = null;
        curSelected = FlxMath.wrap(curSelected + by, 0, grpSongs.length - 1);
        
        for(i in 0...grpSongs.length) {
            song = grpSongs.members[i];
            song.targetY = i - curSelected;
            song.alpha = (i == curSelected) ? 1.0 : 0.6;
        }
        changeDifficulty(0, true);
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function changeDifficulty(by:Int = 0, ?force:Bool):Void {
        if(by == 0 && !force)
            return;

        final song:FreeplaySongData = songs[curSelected];
        final defaultMeta:SongMetadata = song.meta.get("default");

        var meta:SongMetadata = song.meta.get(curMix);
        if(meta == null) {
            curMix = "default"; // fallback to default mix
            curDifficulty = "normal"; // attempt to fallback to normal diff, if this fails the code below should correct it
            meta = song.meta.get(curMix);
        }
        var newDiffIndex:Int = meta.song.difficulties.indexOf(curDifficulty) + by;

        if(newDiffIndex < 0) {
            // go back a mix
            curMix = defaultMeta.song.mixes[FlxMath.wrap(defaultMeta.song.mixes.indexOf(curMix) - 1, 0, defaultMeta.song.mixes.length - 1)];
            meta = song.meta.get(curMix);

            // reset difficulty to first of this mix
            curDifficulty = meta.song.difficulties.last() ?? "normal";
        }
        else if(newDiffIndex > meta.song.difficulties.length - 1) {
            // go forward a mix
            curMix = defaultMeta.song.mixes[FlxMath.wrap(defaultMeta.song.mixes.indexOf(curMix) + 1, 0, defaultMeta.song.mixes.length - 1)];
            meta = song.meta.get(curMix);

            // reset difficulty to first of this mix
            curDifficulty = meta.song.difficulties.first() ?? "normal";
        }
        else {
            // change difficulty but keep current mix
            curDifficulty = meta.song.difficulties[newDiffIndex];
        }
        final showArrows:Bool = (meta.song.difficulties.length > 1 || meta.song.mixes.length > 1);
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

    public function loadIntoCharter():Void {
        final songData:FreeplaySongData = songs[curSelected];
        FlxG.switchState(ChartEditor.new.bind({
            song: songData.data.id,
            difficulty: curDifficulty,
            mix: curMix
        }));
    }

    public function loadIntoSong():Void {
        final songData:FreeplaySongData = songs[curSelected];
        FlxG.switchState(PlayState.new.bind({
            song: songData.data.id,
            difficulty: curDifficulty,
            mix: curMix
        }));
    }
}