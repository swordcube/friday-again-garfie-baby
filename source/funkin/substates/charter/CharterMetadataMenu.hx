package funkin.substates.charter;

import flixel.util.FlxTimer;
import funkin.gameplay.song.SongMetadata;
import funkin.scripting.*;
import funkin.states.editors.ChartEditor;
import funkin.ui.*;
import funkin.ui.dropdown.*;
import funkin.ui.panel.*;
import funkin.ui.slider.*;

class CharterMetadataMenu extends UISubState {
    public var window:CharterMetadataWindow;

    override function create():Void {
        super.create();
        
        camera = new FlxCamera();
        camera.bgColor = 0x80000000;
        FlxG.cameras.add(camera, false);
        
        window = new CharterMetadataWindow();
        window.onClose.add(close);
        window.screenCenter();
        add(window);
    }

    override function update(elapsed:Float):Void {
        final isUIFocused:Bool = UIUtil.isAnyComponentFocused([window.charter.grid, window.charter.selectionBox]);
        FlxG.sound.acceptInputs = !UIUtil.isModifierKeyPressed(ANY) && !isUIFocused;
        
        if(FlxG.mouse.justReleased && !window.checkMouseOverlap())
            FlxTimer.wait(0.001, window.close);

        if(FlxG.mouse.justPressed)
            FlxG.sound.play(Paths.sound("editors/charter/sfx/click_down"));
        
        else if(FlxG.mouse.justReleased)
            FlxG.sound.play(Paths.sound("editors/charter/sfx/click_up"));
        
        super.update(elapsed);
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}

class CharterMetadataWindow extends Window {
    public var charter(default, null):ChartEditor;

    public function new() {
        charter = cast FlxG.state;
        super(0, 0, "Edit chart metadata", false, 510, 370);
    }

    override function initContents():Void {
        final meta:SongMetadata = charter.currentChart.meta;
        
        final songTitleLabel:Label = new Label(10, 10, "Song Title");
        addToContents(songTitleLabel);
        
        final songTitleTextbox:Textbox = new Textbox(songTitleLabel.x, songTitleLabel.y + 22, meta.song.title, false, 200);
        songTitleTextbox.callback = (text:String) -> {
            meta.song.title = text;
        };
        addToContents(songTitleTextbox);

        final iconLabel:Label = new Label(songTitleLabel.x + (songTitleTextbox.width + 10), songTitleLabel.y, "Freeplay Icon");
        addToContents(iconLabel);
        
        final iconTextbox:Textbox = new Textbox(iconLabel.x, iconLabel.y + 22, meta.freeplay.icon, false, 130);
        iconTextbox.callback = (text:String) -> {
            meta.freeplay.icon = text;
        };
        addToContents(iconTextbox);

        final albumLabel:Label = new Label(iconLabel.x + (iconTextbox.width + 10), iconLabel.y, "Freeplay Album");
        addToContents(albumLabel);
        
        final albumTextbox:Textbox = new Textbox(albumLabel.x, albumLabel.y + 22, meta.freeplay.album, false, 130);
        albumTextbox.callback = (text:String) -> {
            meta.freeplay.album = text;
        };
        addToContents(albumTextbox);
        
        final stageLabel:Label = new Label(songTitleLabel.x, songTitleTextbox.y + 32, "Stage");
        addToContents(stageLabel);

        final stageTextbox:Textbox = new Textbox(stageLabel.x, stageLabel.y + 22, meta.game.stage, false, 200);
        stageTextbox.callback = (text:String) -> {
            meta.game.stage = text;
        };
        addToContents(stageTextbox);
        
        final scrollSpeedLabel:Label = new Label(stageLabel.x + (stageTextbox.width + 10), stageLabel.y, "Scroll Speed");
        addToContents(scrollSpeedLabel);

        final scrollSpeedTextbox:Textbox = new Textbox(scrollSpeedLabel.x, scrollSpeedLabel.y + 22, Std.string(meta.game.scrollSpeed.get(charter.currentDifficulty)), false, 130);
        scrollSpeedTextbox.callback = (text:String) -> {
            var speed:Float = Std.parseFloat(text);
            if(Math.isNaN(speed))
                speed = 1;

            meta.game.scrollSpeed.set(charter.currentDifficulty, speed);
        };
        scrollSpeedTextbox.restrictChars = "0-9.";
        addToContents(scrollSpeedTextbox);
        
        final uiSkinLabel:Label = new Label(scrollSpeedLabel.x + (scrollSpeedTextbox.width + 10), scrollSpeedLabel.y, "UI Skin");
        addToContents(uiSkinLabel);

        final uiSkinTextbox:Textbox = new Textbox(uiSkinLabel.x, uiSkinLabel.y + 22, meta.game.uiSkin, false, 130);
        uiSkinTextbox.callback = (text:String) -> {
            meta.game.uiSkin = text;
        };
        addToContents(uiSkinTextbox);
        
        final sep:FlxSprite = new FlxSprite(0, uiSkinTextbox.y + 42).loadGraphic(Paths.image("ui/images/separator"));
        sep.setGraphicSize(510 - 8, sep.frameHeight);
        sep.updateHitbox();
        addToContents(sep);

        final bpmLabel:Label = new Label(10, sep.y + 15, "Song BPM");
        addToContents(bpmLabel);
        
        final bpmTextbox:Textbox = new Textbox(bpmLabel.x, bpmLabel.y + 22, Std.string(meta.song.timingPoints.first()?.bpm ?? 100.0), false, 200);
        bpmTextbox.callback = (text:String) -> {
            var bpm:Float = Std.parseFloat(text);
            if(Math.isNaN(bpm))
                bpm = 100;

            final firstTimingPoint:TimingPoint = meta.song.timingPoints.first();
            if(firstTimingPoint != null)
                firstTimingPoint.bpm = bpm;

            Conductor.instance.reset(firstTimingPoint?.bpm ?? 100.0);
		    Conductor.instance.setupTimingPoints(meta.song.timingPoints);

            // TODO: ensure the charter is updated to match the new bpm correctly
        };
        bpmTextbox.restrictChars = "0-9.";
        addToContents(bpmTextbox);
        
        final artistLabel:Label = new Label(bpmLabel.x + (bpmTextbox.width + 10), bpmLabel.y, "Artist");
        addToContents(artistLabel);

        final artistTextbox:Textbox = new Textbox(artistLabel.x, artistLabel.y + 22, meta.song.artist, false, 130);
        artistTextbox.callback = (text:String) -> {
            meta.song.artist = text;
        };
        addToContents(artistTextbox);

        final charterLabel:Label = new Label(artistLabel.x + (artistTextbox.width + 10), artistLabel.y, "Charter");
        addToContents(charterLabel);

        final charterTextbox:Textbox = new Textbox(charterLabel.x, charterLabel.y + 22, meta.song.charter, false, 130);
        charterTextbox.callback = (text:String) -> {
            meta.song.charter = text;
        };
        addToContents(charterTextbox);
        
        final mixesLabel:Label = new Label(bpmLabel.x, charterTextbox.y + 32, "Mixes");
        addToContents(mixesLabel);

        final mixesTextbox:Textbox = new Textbox(mixesLabel.x, mixesLabel.y + 22, meta.song.mixes.join(", "), false, 200);
        mixesTextbox.callback = (text:String) -> {
            final mixes:Array<String> = text.split(",");
            for(i in 0...mixes.length)
                mixes[i] = mixes[i].trim();

            meta.song.mixes = mixes;
        };
        addToContents(mixesTextbox);
        
        final difficultiesLabel:Label = new Label(mixesLabel.x + (mixesTextbox.width + 10), mixesLabel.y, "Difficulties");
        addToContents(difficultiesLabel);

        final difficultiesTextbox:Textbox = new Textbox(difficultiesLabel.x, difficultiesLabel.y + 22, meta.song.difficulties.join(", "), false, 270);
        difficultiesTextbox.callback = (text:String) -> {
            final diffs:Array<String> = text.split(",");
            for(i in 0...diffs.length)
                diffs[i] = diffs[i].trim();

            meta.song.difficulties = diffs;
        };
        addToContents(difficultiesTextbox);

        final sep:FlxSprite = new FlxSprite(0, difficultiesTextbox.y + 42).loadGraphic(Paths.image("ui/images/separator"));
        sep.setGraphicSize(510 - 8, sep.frameHeight);
        sep.updateHitbox();
        addToContents(sep);
        
        final opponentLabel:Label = new Label(10, sep.y + 15, "Opponent");
        addToContents(opponentLabel);
        
        final opponentTextbox:Textbox = new Textbox(opponentLabel.x, opponentLabel.y + 22, meta.game.characters.get("opponent"), false, 153);
        opponentTextbox.callback = (text:String) -> {
            meta.game.characters.set("opponent", text);
        };
        addToContents(opponentTextbox);
        
        final playerLabel:Label = new Label(opponentLabel.x + (opponentTextbox.width + 10), opponentLabel.y, "Player");
        addToContents(playerLabel);
        
        final playerTextbox:Textbox = new Textbox(playerLabel.x, playerLabel.y + 22, meta.game.characters.get("player"), false, 153);
        playerTextbox.callback = (text:String) -> {
            meta.game.characters.set("player", text);
        };
        addToContents(playerTextbox);
        
        final spectatorLabel:Label = new Label(playerLabel.x + (playerTextbox.width + 10), playerLabel.y, "Spectator");
        addToContents(spectatorLabel);
        
        final spectatorTextbox:Textbox = new Textbox(spectatorLabel.x, spectatorLabel.y + 22, meta.game.characters.get("spectator"), false, 153);
        spectatorTextbox.callback = (text:String) -> {
            meta.game.characters.set("spectator", text);
        };
        addToContents(spectatorTextbox);
    }
}