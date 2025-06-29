package funkin.states.menus;

import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;

class OffsetCalibrationState extends FunkinState {
    public static final MAX_TIMESTAMP_COUNT:Int = 16; // max amount of timestamps

    public var bg:FunkinSprite;

    public var strums:FlxTypedContainer<FunkinSprite>;
    public var notes:FlxTypedContainer<OffsetCalibrationNote>;

    public var noteEnumerator:Int = 0;
    public var storedTimestamps:Array<Float> = [];

    public var audioLatency:Float = 0;
    public var offsetText:FlxText;
    
    override function create():Void {
        super.create();
        persistentUpdate = true;

        DiscordRPC.changePresence("Offset Calibration", null);
        
        if(FlxG.sound.music != null && FlxG.sound.music.playing) {
            audioLatency = FlxG.sound.music.latency;
            FlxG.sound.music.fadeOut(0.16, 0, (_) -> {
                FlxG.sound.music.pause();
            });
        } else {
            var prevTime:Float = 0;
            if(FlxG.sound.music != null) {
                prevTime = FlxG.sound.music.time;
                FlxG.sound.music.volume = 0;
                FlxG.sound.music.resume();
            } else
                CoolUtil.playMenuMusic(0);
            
            audioLatency = FlxG.sound.music.latency;

            FlxG.sound.music.pause();
            FlxG.sound.music.time = prevTime;
        }
        bg = new FunkinSprite().loadGraphic(Paths.image("menus/bg_transparent"));
        bg.alpha = 0.1;
        bg.screenCenter();
        add(bg);

        strums = new FlxTypedContainer<FunkinSprite>();
        add(strums);

        notes = new FlxTypedContainer<OffsetCalibrationNote>();
        add(notes);

        for(i in 0...4) {
            final strum:FunkinSprite = new FunkinSprite((i * Constants.STRUM_SPACING) + ((FlxG.width - (Constants.STRUM_SPACING * 4)) * 0.5));
            strum.frames = Paths.getSparrowAtlas("editors/charter/images/strums");
            strum.animation.addByPrefix("static", '${Constants.NOTE_DIRECTIONS[i]} static', 24, false);
            strum.animation.addByPrefix("confirm", '${Constants.NOTE_DIRECTIONS[i]} confirm', 24, false);
            strum.animation.play("static");
            strum.scale.set(0.7, 0.7);
            strum.updateHitbox();
            strum.screenCenter(Y);
            strums.add(strum);
        }
        offsetText = new FlxText(0, FlxG.height * 0.9, 0, "Estimated Song Offset: 0ms");
        offsetText.setFormat(Paths.font("fonts/vcr"), 22, FlxColor.WHITE, CENTER);
        offsetText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        offsetText.screenCenter(X);
        add(offsetText);
        
        Conductor.instance.reset();
        Conductor.instance.music = null;
        Conductor.instance.offset = 0;
        Conductor.instance.autoIncrement = true;

        Conductor.instance.hasMetronome = false;
        Conductor.instance.rawTime = -(Conductor.instance.getTimeAtBeat(8));
        Conductor.instance.update(0);
        
        // skip ahead to essentially force notes to spawn
        Conductor.instance.hasMetronome = true;
        Conductor.instance.rawTime = 0;
        Conductor.instance.update(0);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(controls.justPressed.BACK) {
            Options.save();
            Conductor.instance.hasMetronome = false;

            FlxG.sound.music.resume();
            FlxG.sound.music.fadeIn(0.16);

            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            FlxG.switchState(OptionsState.new.bind(OptionsState.lastParams));
        }
        if(controls.justPressed.ACCEPT) {
            final newSongOffset:Null<Float> = storedTimestamps.getAverage();
            if(newSongOffset != null) {
                offsetText.color = FlxColor.LIME;
                FlxTween.cancelTweensOf(offsetText);
                FlxTween.color(offsetText, 0.5, offsetText.color, FlxColor.WHITE);

                final estimatedSongOffset:Float = Math.floor((newSongOffset - audioLatency) / 5) * 5;
                Options.songOffset = Math.ffloor(estimatedSongOffset);

                FlxG.sound.play(Paths.sound("menus/sfx/select"));
            } else {
                offsetText.color = FlxColor.RED;
                FlxTween.cancelTweensOf(offsetText);
                FlxTween.color(offsetText, 0.5, offsetText.color, FlxColor.WHITE);
                FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            }
        }
        for(i => control in OffsetCalibrationNote.CONTROLS) {
            if(controls.justPressed.check(control)) {
                final validNotes:Array<OffsetCalibrationNote> = notes.members.filter((note:OffsetCalibrationNote) -> {
                    return note.direction == i && note.isInRange();
                });
                if(validNotes.length != 0) {
                    validNotes.sort(noteSort);
                    validNotes[0].hit();

                    final estimatedSongOffset:Float = Math.floor((storedTimestamps.getAverage() - audioLatency) / 5) * 5;
                    offsetText.text = 'Estimated Song Offset: ${estimatedSongOffset}ms\nPress ACCEPT to apply this offset';
                    offsetText.screenCenter(X);

                    offsetText.scale.set(1.1, 1.1);
                    FlxTween.cancelTweensOf(offsetText.scale);
                    FlxTween.tween(offsetText.scale, {x: 1, y: 1}, 0.2);
                }
                break;
            }
        }
    }

    override function beatHit(beat:Int):Void {
        final direction:Int = noteEnumerator++ % 4;
        final strum:FunkinSprite = strums.members[direction];
        
        final note:OffsetCalibrationNote = notes.recycle(OffsetCalibrationNote);
        note.setup(strum.x, -9999, Conductor.instance.getTimeAtBeat(beat + 4), direction, strum);

        super.beatHit(beat);
    }

    public function storeTimestamp(timestamp:Float):Void {
        while(storedTimestamps.length >= MAX_TIMESTAMP_COUNT)
            storedTimestamps.shift();

        storedTimestamps.push(timestamp);
    }

    public function noteSort(a:OffsetCalibrationNote, b:OffsetCalibrationNote):Int {
        return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    }
}

class OffsetCalibrationNote extends FunkinSprite {
    public static final CONTROLS:Array<Control> = [Control.NOTE_LEFT, Control.NOTE_DOWN, Control.NOTE_UP, Control.NOTE_RIGHT];

    public var menu:OffsetCalibrationState;
    public var time:Float;
    public var direction:Int;
    public var strum:FunkinSprite;
    public var wasHit:Bool;

    public function setup(x:Float = 0, y:Float = 0, time:Float, direction:Int, strum:FunkinSprite) {
        menu = cast FlxG.state;
        setPosition(x, y);

        this.time = time;
        this.direction = direction;
        this.strum = strum;

        wasHit = false;
        alpha = 1;
        FlxTween.cancelTweensOf(this);

        frames = Paths.getSparrowAtlas("editors/charter/images/notes");
        animation.addByPrefix("scroll", '${Constants.NOTE_DIRECTIONS[direction]} scroll', 24, false);
        animation.play("scroll");

        scale.set(0.7, 0.7);
        updateHitbox();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        y = strum.y + (Constants.PIXELS_PER_MS * (time - Conductor.instance.rawTime));

        if(y < -height)
            kill();
    }

    public function hit():Void {
        wasHit = true;
        menu.storeTimestamp(Conductor.instance.rawTime - time);
        FlxTween.tween(this, {alpha: 0.6}, 0.5, {ease: FlxEase.cubeOut});
    }

    public function isInRange():Bool {
        return Math.abs(time - Conductor.instance.rawTime) <= 1000;
    }
}