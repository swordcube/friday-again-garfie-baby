package funkin.gameplay.notes;

import flixel.tweens.FlxTween;
import funkin.gameplay.notes.HoldTrail;

class StrumLine extends FlxSpriteGroup {
    public var strums:FlxTypedSpriteGroup<Strum>;
    public var notes:FlxTypedSpriteGroup<Note>;
    public var holdTrails:FlxTypedSpriteGroup<HoldTrail>;

    public var downscroll:Bool = false;
    public var botplay:Bool = false;
    
    public var scrollSpeed:Float = 1;
    public var playField:PlayField;
    
    public function new(x:Float = 0, y:Float = 0, downscroll:Bool, botplay:Bool, skin:String) {
        super(x, y);

        this.downscroll = downscroll;
        this.botplay = botplay;

        strums = new FlxTypedSpriteGroup<Strum>();
        add(strums);

        holdTrails = new FlxTypedSpriteGroup<HoldTrail>();
        add(holdTrails);
        
        notes = new FlxTypedSpriteGroup<Note>();
        add(notes);

        for(i in 0...Constants.KEY_COUNT) {
            final strum:Strum = new Strum((i - (Constants.KEY_COUNT * 0.5)) * Constants.STRUM_SPACING, 0, i, skin);
            strum.strumLine = this;
            strums.add(strum);
        }
        for(i in 0...48) {
            final note:Note = new Note().setup(this, 0, i % Constants.KEY_COUNT, 0, "Default", strums.members[i % Constants.KEY_COUNT].skin);
            note.kill();
            notes.add(note);
        }
    }

    public function hitNote(note:Note):Void {
        note.wasHit = true;

        if(note.length <= 0)
            killNote(note);
        else {
            note.colorTransform.redOffset = note.colorTransform.greenOffset = note.colorTransform.blueOffset = 40;
        }
        final strum:Strum = strums.members[note.direction];
        strum.holdTime = Math.max(note.length, (botplay) ? (playField?.attachedConductor.stepLength ?? Conductor.instance.stepLength) : 250);
        strum.animation.play('${Constants.NOTE_DIRECTIONS[note.direction]} confirm', true);
    }

    public function killNote(note:Note):Void {
        note.kill();
        note.holdTrail.kill();
    }

    public function missNote(note:Note):Void {
        note.wasHit = false;
        note.wasMissed = true;

        // the note is now cum colored
        note.colorTransform.redOffset = note.colorTransform.greenOffset = note.colorTransform.blueOffset = 200;

        note.holdTrail.strip.colorTransform.redOffset = note.holdTrail.strip.colorTransform.greenOffset = note.holdTrail.strip.colorTransform.blueOffset = 200;
        note.holdTrail.tail.colorTransform.redOffset = note.holdTrail.tail.colorTransform.greenOffset = note.holdTrail.tail.colorTransform.blueOffset = 200;
        
        note.alpha = 0.3;
        note.holdTrail.alpha = 0.3;
    }

    public function processNote(note:Note):Void {
        final strum:Strum = strums.members[note.direction];
        final attachedConductor:Conductor = playField?.attachedConductor ?? Conductor.instance;
        
        final absSpeed:Float = Math.abs(scrollSpeed);
        final scrollMult:Float = ((downscroll) ? -1 : 1) * ((scrollSpeed < 0) ? -1 : 1);

        note.x = strum.x + note.offsetX;
        
        note.holdTrail.x = note.x + note.holdTrail.offsetX + ((note.width - note.holdTrail.width) * 0.5);
        
        note.holdTrail.strip.x = note.holdTrail.x;
        note.holdTrail.tail.x = note.holdTrail.x;
        
        note.holdTrail.strip.flipY = (absSpeed * scrollMult) < 0;
        
        if(note.wasHit && !note.wasMissed) {
            note.y = strum.y + note.offsetY;
            
            final sexo:Float = Constants.PIXELS_PER_MS * (attachedConductor.time - note.time) * absSpeed;
            final calcHeight:Float = Math.max((Constants.PIXELS_PER_MS * note.length * absSpeed) - sexo, 0);
            
            note.holdTrail.y = strum.y + note.holdTrail.offsetY + (strum.height * 0.5);
            note.holdTrail.height = calcHeight;
        } else {
            note.y = strum.y + note.offsetY + (Constants.PIXELS_PER_MS * (note.time - attachedConductor.time) * absSpeed * scrollMult);
            
            final calcHeight:Float = (Constants.PIXELS_PER_MS * note.length * absSpeed);
            note.holdTrail.y = note.y + note.holdTrail.offsetY + (strum.height * 0.5);
            
            note.holdTrail.height = calcHeight; 
        }
        if(botplay) {
            if(!note.wasHit && !note.wasMissed && note.time <= attachedConductor.time)
                hitNote(note);
            
            if(note.wasHit && note.length > 0 && note.time <= attachedConductor.time - note.length) {
                // kill the note if it is a hold note and it was
                // held the entire way through
                killNote(note);
            }
            if(note.time <= attachedConductor.time - ((350 / scrollSpeed) + note.length)) {
                // kill the note if it goes off-screen, regardless of if it was missed or not
                // nobody will know trust 🤫
                killNote(note);
            }
        } else {
            if(!note.wasHit && !note.wasMissed && note.time <= attachedConductor.time - Options.hitWindow) {
                // miss the note if it's out of range to be hit
                missNote(note);
            }
            if(note.wasHit && note.length > 0 && note.time <= attachedConductor.time - note.length) {
                // kill the note if it is a hold note and it was
                // held the entire way through
                killNote(note);
            }
            if(note.wasMissed && note.time <= attachedConductor.time - ((350 / scrollSpeed) + note.length)) {
                // kill the note if it goes off-screen (only if it was missed)
                killNote(note);
            }
        }
    }

    override function update(elapsed:Float) {
        notes.forEachAlive(processNote);
        super.update(elapsed);
    }
}