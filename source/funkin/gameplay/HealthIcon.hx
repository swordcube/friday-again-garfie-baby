package funkin.gameplay;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

import funkin.gameplay.character.Character;
import funkin.gameplay.character.CharacterData;

import funkin.graphics.TrackingSprite;

/**
 * The current icon type of this health icon.
 */
enum abstract HealthIconType(Int) from Int to Int {
    final OPPONENT = 0;
    final PLAYER = 1;
}

/**
 * The current state of the health icon.
 */
enum abstract HealthIconState(String) to String from String {
	/**
	 * Indicates the health icon is in the default animation.
	 * Plays as long as health is between 20% and 80%.
	 */
	final IDLE = 'idle';

	/**
	 * Indicates the health icon is playing the Winning animation.
	 * Plays as long as health is above 80%.
	 */
	final WINNING = 'winning';

	/**
	 * Indicates the health icon is playing the Losing animation.
	 * Plays as long as health is below 20%.
	 */
	final LOSING = 'losing';

	/**
	 * Indicates that the health icon is transitioning between `idle` and `winning`.
	 * The next animation will play once the current animation finishes.
	 */
	final TO_WINNING = 'toWinning';

	/**
	 * Indicates that the health icon is transitioning between `idle` and `losing`.
	 * The next animation will play once the current animation finishes.
	 */
	final TO_LOSING = 'toLosing';

	/**
	 * Indicates that the health icon is transitioning between `winning` and `idle`.
	 * The next animation will play once the current animation finishes.
	 */
	final FROM_WINNING = 'fromWinning';

	/**
	 * Indicates that the health icon is transitioning between `losing` and `idle`.
	 * The next animation will play once the current animation finishes.
	 */
	final FROM_LOSING = 'fromLosing';
}

enum abstract HealthIconBump(String) from String to String {
    /**
     * The default icon bumping style.
     * 
     * This icon will be centered onto the health bar
     * and will move at a normal pace.
     */
    final DEFAULT = 'default';

    /**
     * The Week 6 and older icon bumping style.
     * 
     * This icon will bump downwards on the health bar
     * and will move at a fast pace.
     */
    final LEGACY = 'legacy';

    /**
     * The Week 7 bumping style.
     * 
     * This icon will bump downwards on the health bar
     * and will move at a normal pace.
     */
    final WEEK7 = 'week7';
}

class HealthIcon extends TrackingSprite {
    /**
     * At this amount of health, play the Winning animation instead of the idle.
     */
    public static final WINNING_THRESHOLD:Float = 0.8;

    /**
     * At this amount of health, play the Losing animation instead of the idle.
     */
    public static final LOSING_THRESHOLD:Float = 0.2;

    /**
     * The speed that the health icon zooms back out at.
     */
    public static final ICON_SPEED:Float = 0.25;

    /**
     * Hack for icon postionial spacing
     */
    public static final POSITION_OFFSET:Float = 26;

    /**
     * The size of a non-pixel icon when using the legacy format.
     * Remember, modern icons can be any size.
     */
    public static final HEALTH_ICON_SIZE:Int = 150;

    /**
     * The size of a pixel icon when using the legacy format.
     * Remember, modern icons can be any size.
     */
    public static final PIXEL_ICON_SIZE:Int = 32;

    /**
     * The scale that the icons increase by each beat.
     */
    public static final BOP_AMOUNT:Float = 0.2;

    /**
     * The ID of the character that this icon represents.
     */
    public var characterID(default, set):String = null;

    /**
     * Controls whether or not this health icon
     * should automatically lerp back to initial scale.
     * 
     * This is useful for icon bopping.
     */
    public var canLerp:Bool = false;

    /**
     * The icon type of this health icon.
     */
    public var iconType:HealthIconType = OPPONENT;

    /**
     * Whether or not this is a legacy icon.
     */
    public var isLegacyStyle:Bool = false;

    /**
     * Whether or not the sprite is pixel art.
     */
    public var isPixel:Bool = false;

    /**
     * The initial X and Y scale of this health icon.
     */
    public var size:FlxPoint = FlxPoint.get(1, 1);

    /**
     * Whether or not the icon should scale from it's center
     * instead of the top left corner.
     */
    public var centered:Bool = false;

    public var health:Float = 0.5;

    public var bopTween:FlxTween;

    /**
     * Makes a new `HealthIcon` instance.
     */
    public function new(character:String = "bf", iconType:HealthIconType = OPPONENT) {
        super(0, 0);
        this.characterID = character;
        this.iconType = iconType;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if(canLerp) {
            if(width > height)
                setGraphicSize(FlxMath.lerp(width, HEALTH_ICON_SIZE * size.x, elapsed * 60 * ICON_SPEED), 0);
            else
                setGraphicSize(0, FlxMath.lerp(height, HEALTH_ICON_SIZE * size.y, elapsed * 60 * ICON_SPEED));

            updateHitbox();
        }
        _updateHealthIcon(health);
    }

    override function updateHitbox():Void {
        super.updateHitbox();
        if(centered)
            offset.set(-0.5 * ((frameWidth * size.x) - frameWidth), -0.5 * ((frameHeight * size.y) - frameHeight));
    }

    public function bop():Void {
        if(bopTween != null)
            bopTween.cancel();

        if(width > height)
            setGraphicSize(HEALTH_ICON_SIZE * size.x * (1 + BOP_AMOUNT), 0);
        else
            setGraphicSize(0, HEALTH_ICON_SIZE * size.y * (1 + BOP_AMOUNT));
        
        bopTween = FlxTween.tween(this.scale, {x: (HEALTH_ICON_SIZE * size.x) / frameWidth, y: (HEALTH_ICON_SIZE * size.y) / frameHeight}, 0.15, {
            ease: FlxEase.sineOut,
            onUpdate: (_) -> {
                updateHitbox();
            }
        });
        updateHitbox();
    }

	/**
	 * Plays the animation with the given name.
     * 
	 * @param  name      The name of the animation to play.
	 * @param  fallback  The fallback animation to play if the given animation is not found.
	 * @param  restart   Whether to forcibly restart the animation if it is already playing.
	 */
	public function playIconAnim(name:String, fallback:String = null, restart = false):Void {
		if(animation.exists(name)) {
			animation.play(name, restart, false, 0);
			return;
		}
		if(fallback != null && animation.exists(fallback))
			animation.play(fallback, restart, false, 0);
	}

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private var _lastHealth:Float = Math.NEGATIVE_INFINITY;

    private function _isNewSpritesheet(charID:String):Bool {
        return FlxG.assets.exists(Paths.xml('gameplay/icons/${charID}'));
    }

    private function _correctCharacterID(charID:Null<String>):String {
        if(charID == null)
            return Constants.DEFAULT_HEALTH_ICON;
    
        if(charID.contains("-") && !FlxG.assets.exists(Paths.image('gameplay/icons/${charID}')))
            charID = charID.substr(0, charID.indexOf("-"));

        if(!FlxG.assets.exists(Paths.image('gameplay/icons/${charID}'))) {
            Logs.warn('No icon for character: ${charID} : using default icon instead!');
            return Constants.DEFAULT_HEALTH_ICON;
        }
        return charID;
    }

    /**
     * Load health icon animations from a Sparrow XML file (the kind used by characters)
     * Note that this is looking for SPECIFIC animation names, so you may need to modify the XML.
     */
    private function _loadAnimationNew():Void {
        animation.addByPrefix(IDLE, IDLE, 24, true);
        animation.addByPrefix(WINNING, WINNING, 24, true);
        animation.addByPrefix(LOSING, LOSING, 24, true);
        animation.addByPrefix(TO_WINNING, TO_WINNING, 24, false);
        animation.addByPrefix(TO_LOSING, TO_LOSING, 24, false);
        animation.addByPrefix(FROM_WINNING, FROM_WINNING, 24, false);
        animation.addByPrefix(FROM_LOSING, FROM_LOSING, 24, false);
    }
  
    /**
     * Load health icon animations using the legacy format.
     * Simply assumes two icons, the idle and losing icons.
     */
    private function _loadAnimationOld():Void {
        this.animation.add(IDLE, [0], 0, false, false);
        this.animation.add(LOSING, [1], 0, false, false);
        if(animation.numFrames >= 3)
            this.animation.add(WINNING, [2], 0, false, false);
    }

    private function _loadCharacter(charID:Null<String>):Void {
        charID = _correctCharacterID(charID);
        final charData:CharacterData = CharacterData.load(charID);

        isPixel = charData?.healthIcon?.isPixel ?? false;
        isLegacyStyle = !_isNewSpritesheet(charID);

        if(!isLegacyStyle) {
            frames = Paths.getSparrowAtlas('gameplay/icons/${charID}');
            _loadAnimationNew();
        } else {
            final size:Int = isPixel ? PIXEL_ICON_SIZE : HEALTH_ICON_SIZE;
            loadGraphic(Paths.image('gameplay/icons/${charID}'), true, size, size);
            _loadAnimationOld();
        }
        this.antialiasing = !isPixel;
        
        final leScale:Float = charData?.healthIcon?.scale ?? 1.0;
        size.set(leScale, leScale);
        
        if(width > height)
            setGraphicSize(HEALTH_ICON_SIZE * size.x, 0);
        else
            setGraphicSize(0, HEALTH_ICON_SIZE * size.y);
        
        updateHitbox();

        flipX = charData?.healthIcon?.flip?.x ?? false;
        flipY = charData?.healthIcon?.flip?.y ?? false;

        frameOffset.set(
            charData?.healthIcon?.offset?.x ?? 0,
            charData?.healthIcon?.offset?.y ?? 0
        );
        health = 0.5;
        _updateHealthIcon(health);
    }

	private function _updateHealthIcon(health:Float):Void {
        if(_lastHealth == health)
            return;

		switch(animation.name) {
			case IDLE:
                if(health < LOSING_THRESHOLD)
                    playIconAnim(TO_LOSING, LOSING);

                else if(health > WINNING_THRESHOLD)
                    playIconAnim(TO_WINNING, WINNING);

                else
                    playIconAnim(IDLE);
            
            case WINNING:
                if (health < WINNING_THRESHOLD)
                    playIconAnim(FROM_WINNING, IDLE);
                
                else
                    playIconAnim(WINNING, IDLE);

            case LOSING:
                if (health > LOSING_THRESHOLD)
                    playIconAnim(FROM_LOSING, IDLE);

                else
                    playIconAnim(LOSING, IDLE);
                
            case TO_LOSING:
                if(animation.finished)
                    playIconAnim(LOSING, IDLE);
            
            case TO_WINNING:
                if (animation.finished)
                    playIconAnim(WINNING, IDLE);
            
            case FROM_LOSING, FROM_WINNING:
                if(animation.finished)
                    playIconAnim(IDLE);
            
            default:
                playIconAnim(IDLE);
		}
        _lastHealth = health;
	}

    @:noCompletion
    private inline function set_characterID(value:String):String {
        if(characterID == value)
            return value;

        _loadCharacter(value);
        return characterID = value;
    }

    override function destroy():Void {
        size = FlxDestroyUtil.put(size);
        super.destroy();
    }
}