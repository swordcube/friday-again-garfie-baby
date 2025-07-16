package funkin.ui.charter;

class CharterPreviewWindow extends Window {
    public static final NOTE_SPACING:Float = 160; 
    public static final NOTE_SCALE:Float = 0.2;

    public var opponentStrumLine:FlxTypedSpriteContainer<FunkinSprite>;
    public var playerStrumLine:FlxTypedSpriteContainer<FunkinSprite>;

    public function new() {
        super(FlxG.width - 20, 40, "Chart Preview", false, 330, 270);
        x -= bg.width;
    }

    override function initContents():Void {
        opponentStrumLine = new FlxTypedSpriteContainer<FunkinSprite>(10, 10);
        addToContents(opponentStrumLine);
        
        playerStrumLine = new FlxTypedSpriteContainer<FunkinSprite>(330 - (NOTE_SPACING * NOTE_SCALE * Constants.KEY_COUNT) - 20, 10);
        addToContents(playerStrumLine);

        for(i in 0...Constants.KEY_COUNT) {
            final strum:FunkinSprite = new FunkinSprite(i * (NOTE_SPACING * NOTE_SCALE));
            strum.loadSparrowFrames('editors/charter/images/strums');
            strum.animation.addByPrefix("static", '${Constants.NOTE_DIRECTIONS[i]} static', 24, false);
            strum.animation.play("static");
            strum.scale.set(NOTE_SCALE, NOTE_SCALE);
            strum.updateHitbox();
            opponentStrumLine.add(strum);
            
            final strum:FunkinSprite = new FunkinSprite(i * (NOTE_SPACING * NOTE_SCALE));
            strum.loadSparrowFrames('editors/charter/images/strums');
            strum.animation.addByPrefix("static", '${Constants.NOTE_DIRECTIONS[i]} static', 24, false);
            strum.animation.play("static");
            strum.scale.set(NOTE_SCALE, NOTE_SCALE);
            strum.updateHitbox();
            playerStrumLine.add(strum);
        }
    }
}