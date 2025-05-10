package funkin.gameplay.notes;

import flixel.util.FlxSort;
import flixel.util.FlxSignal;
import flixel.tweens.FlxTween;

import funkin.gameplay.notes.HoldTrail;

class StrumLine extends FlxSpriteGroup {
    public var strums:FlxTypedSpriteGroup<Strum>;
    
    public var holdTrails:FlxTypedSpriteGroup<HoldTrail>;
    public var notes:FlxTypedSpriteGroup<Note>;

    public var holdGradients:FlxTypedSpriteGroup<HoldGradient>;
    public var holdCovers:FlxTypedSpriteGroup<HoldCover>;
    public var splashes:FlxTypedSpriteGroup<NoteSplash>;

    public var downscroll:Bool = false;
    public var botplay(default, set):Bool = false;
    
    public var scrollSpeed:Float = 1;
    public var playField:PlayField;

    public var skin(default, set):String;
    public var onBotplayToggle:FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();
    
    public function new(x:Float = 0, y:Float = 0, downscroll:Bool, botplay:Bool, skin:String) {
        super(x, y);
        @:bypassAccessor this.skin = skin;

        this.downscroll = downscroll;
        this.botplay = botplay;

        strums = new FlxTypedSpriteGroup<Strum>();
        add(strums);

        holdTrails = new FlxTypedSpriteGroup<HoldTrail>();
        add(holdTrails);
        
        notes = new FlxTypedSpriteGroup<Note>();
        add(notes);

        holdGradients = new FlxTypedSpriteGroup<HoldGradient>();
        add(holdGradients);
        
        holdCovers = new FlxTypedSpriteGroup<HoldCover>();
        add(holdCovers);

        splashes = new FlxTypedSpriteGroup<NoteSplash>();
        add(splashes);

        for(i in 0...Constants.KEY_COUNT) {
            final strum:Strum = new Strum((i - (Constants.KEY_COUNT * 0.5)) * Constants.STRUM_SPACING, 0, i, skin);
            strum.strumLine = this;
            strums.add(strum);
            
            final gradient:HoldGradient = new HoldGradient((i - (Constants.KEY_COUNT * 0.5)) * Constants.STRUM_SPACING, 0, i, skin);
            gradient.strumLine = this;
            gradient.kill();
            holdGradients.add(gradient);

            final cover:HoldCover = new HoldCover((i - (Constants.KEY_COUNT * 0.5)) * Constants.STRUM_SPACING, 0, i, skin);
            cover.strumLine = this;
            cover.onHoldStart.add(updateHoldCover.bind(i));
            cover.onHold.add(updateHoldCover.bind(i));
            cover.onHoldEnd.add(updateHoldCover.bind(i));
            cover.kill();
            holdCovers.add(cover);
        }
        for(i in 0...48) {
            final note:Note = new Note().setup(this, 0, i % Constants.KEY_COUNT, 0, "Default", skin);
            note.kill();
            notes.add(note);
        }
        for(i in 0...8) {
            final splash:NoteSplash = new NoteSplash().setup(this, i % Constants.KEY_COUNT, skin);
            splash.kill();
            splashes.add(splash);
        }
        @:privateAccess {
            // force this splash to draw to force it
            // into vram, since flixel only puts the shit in vram when the sprite is drawn
            // instead of immediately as the graphic is loaded
            final cacheSplash:NoteSplash = splashes.members[0];
            cacheSplash.alpha = 0.001;
            cacheSplash.drawComplex(FlxG.camera);
        }
    }

    public function sortVisualNotes(_):Void {
        notes.sort(FlxSort.byY, (downscroll) ? FlxSort.ASCENDING : FlxSort.DESCENDING);
    }

    public function showSplash(direction:Int):Void {
        final strum:Strum = strums.members[direction];
        final splash:NoteSplash = splashes.recycle(_splashFactory).setup(this, direction, strum.skin);
        splash.setPosition(strum.x - ((splash.width - strum.width) * 0.5), strum.y - ((splash.height - strum.height) * 0.5));
    }

    public function showHoldGradient(direction:Int):Void {
        final strum:Strum = strums.members[direction];
        final gradient:HoldGradient = holdGradients.members[direction];
        gradient.revive();
        gradient.setPosition(strum.x - ((gradient.width - strum.width) * 0.5), strum.y - ((downscroll) ? gradient.height - (strum.height * 0.75) : 0));
        
        gradient.alpha = gradient.skinData.alpha;
        gradient.flipY = downscroll;
        gradient.holding = true;
    }

    public function showHoldCover(direction:Int):Void {
        final cover:HoldCover = holdCovers.members[direction];
        cover.start();
    }
    
    public function updateHoldCover(direction:Int):Void {
        final strum:Strum = strums.members[direction];
        final cover:HoldCover = holdCovers.members[direction];
        cover.updateHitbox();
        cover.centerOrigin();

        cover.centerOffsets();
        cover.offset.add(cover.skinData.offset[0] ?? 0.0, cover.skinData.offset[1] ?? 0.0);
        
        cover.setPosition(strum.x - ((cover.width - strum.width) * 0.5), strum.y - ((cover.height - strum.height) * 0.5));
    }

    public function processNote(note:Note):Void {
        final strum:Strum = strums.members[note.direction];
        final gradient:HoldGradient = holdGradients.members[note.direction];
        final attachedConductor:Conductor = playField?.attachedConductor ?? Conductor.instance;
        
        final absSpeed:Float = Math.abs(scrollSpeed / FlxG.timeScale);
        final scrollMult:Float = ((downscroll) ? -1 : 1) * ((scrollSpeed < 0) ? -1 : 1);

        note.x = strum.x + note.offsetX;
        note.holdTrail.x = note.x + note.holdTrail.offsetX + ((note.width - note.holdTrail.width) * 0.5);
        
        note.holdTrail.strip.x = note.holdTrail.x;
        note.holdTrail.tail.x = note.holdTrail.x;
        
        note.holdTrail.strip.flipY = (absSpeed * scrollMult) < 0;
        
        if(note.wasHit && !note.wasMissed) {
            note.y = strum.y + note.offsetY;
            final sexo:Float = Constants.PIXELS_PER_MS * (attachedConductor.playhead - note.time) * absSpeed;
            final calcHeight:Float = Math.max((Constants.PIXELS_PER_MS * note.length * absSpeed) - sexo, 0);
            
            note.holdTrail.y = strum.y + note.holdTrail.offsetY + (strum.height * 0.5);
            note.holdTrail.height = calcHeight;
            
            gradient.holding = (note.holdTrail.strip.height > gradient.height * 0.85);
            
            if(playField != null && note.scoreSteps.length != 0) {
                while(note.curScoreStep < note.scoreSteps.length && attachedConductor.time >= note.scoreSteps[note.curScoreStep].time) {
                    if(playField.playerStrumLine == this) {
                        if(note.hitEvent.gainHealthFromHolds)
                            playField.stats.health += note.hitEvent.healthGain;
    
                        if(note.hitEvent.gainScoreFromHolds)
                            playField.stats.score += note.scoreSteps[note.curScoreStep].score;
    
                        if(playField.hud != null) {
                            playField.hud.updateHealthBar();
                            playField.hud.updatePlayerStats(playField.stats);
                        }
                    }
                    if(note.hitEvent.playConfirmAnim && note.hitEvent.strumHoldJitter && playField.strumsPressed[note.direction]) {
                        if(botplay)
                            strum.holdTime = attachedConductor.stepLength * 2;
                        
                        strum.animation.play('${Constants.NOTE_DIRECTIONS[note.direction]} confirm', true);
                    }
                    if(note.hitEvent.playSingAnim && note.hitEvent.characterHoldJitter) {
                        for(character in note.hitEvent.characters)
                            character.playSingAnim(note.direction, note.hitEvent.singAnimSuffix, true);
                    }
                    note.curScoreStep++;
                }
            }
        } else {
            note.y = strum.y + note.offsetY + (Constants.PIXELS_PER_MS * (note.time - attachedConductor.playhead) * absSpeed * scrollMult);
            
            final calcHeight:Float = (Constants.PIXELS_PER_MS * note.length * absSpeed);
            note.holdTrail.y = note.y + note.holdTrail.offsetY + (strum.height * 0.5);
            
            note.holdTrail.height = calcHeight;
        }
        if(botplay) {
            // have to add 10ms to the hit window for the botplay otherwise
            // the notes will occasionally be hit slightly later than normal
            if(!note.wasHit && !note.wasMissed && note.time <= (attachedConductor.time + (10 * FlxG.timeScale)))
                playField.hitNote(note);
            
            if(note.wasHit && note.length > 0 && note.time <= attachedConductor.time - note.length) {
                // end the hold cover if it is a hold note and
                // it was held the entire way through
                note.strumLine.holdCovers.members[note.direction].kill();
                        
                // kill the note if it is a hold note and it was
                // held the entire way through
                playField.killNote(note);
            }
            if(note.time <= attachedConductor.time - ((350 / absSpeed) + note.length)) {
                // kill the note if it goes off-screen, regardless of if it was missed or not
                // nobody will know trust 🤫
                playField.killNote(note);
            }
        } else {
            if(!note.wasHit && !note.wasMissed && note.time <= attachedConductor.time - Options.hitWindow) {
                // miss the note if it's out of range to be hit
                playField.missNote(note);
            }
            if(note.wasHit && note.length > 0 && note.time <= attachedConductor.time - note.length) {
                // end the hold cover if it is a hold note and
                // it was held the entire way through
                if(note.hitEvent.showHoldCovers)
                    note.strumLine.holdCovers.members[note.direction].end();
                else
                    note.strumLine.holdCovers.members[note.direction].kill();

                // kill the note if it is a hold note and it was
                // held the entire way through
                playField.killNote(note);
            }
            if(note.wasMissed && note.time <= attachedConductor.time - ((350 / scrollSpeed) + note.length)) {
                // kill the note if it goes off-screen (only if it was missed)
                playField.killNote(note);
            }
        }
    }

    override function update(elapsed:Float) {
        if(!_initializedPlayFieldShit) {
            if(playField != null)
                playField.attachedConductor.onBeatHit.add(sortVisualNotes);

            _initializedPlayFieldShit = true;
        }
        notes.forEachAlive(processNote);
        super.update(elapsed);
    }

    private var _initializedPlayFieldShit:Bool = false;

    @:noCompletion
    private function _splashFactory():NoteSplash {
        return new NoteSplash();
    }

    @:noCompletion
    private function set_botplay(newValue:Bool):Bool {
        botplay = newValue;
        onBotplayToggle.dispatch(botplay);
        return botplay;
    }

    @:noCompletion
    private function set_skin(newSkin:String):String {
        skin = newSkin;

        for(strum in strums)
            strum.loadSkin(newSkin);

        for(note in notes)
            note.loadSkin(newSkin);

        for(splash in splashes)
            splash.loadSkin(newSkin);

        for(cover in holdCovers)
            cover.loadSkin(newSkin);

        for(gradient in holdGradients)
            gradient.loadSkin(newSkin);

        return skin;
    }

    override function destroy():Void {
        if(playField != null)
            playField.attachedConductor.onBeatHit.remove(sortVisualNotes);

        super.destroy();
    }
}