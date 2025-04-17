package funkin.backend.events;

import flixel.math.FlxPoint;

import funkin.gameplay.ComboDisplay;
import funkin.gameplay.character.Character;

@:dce(full)
class GameplayEvents {} // needs to be here otherwise haxe will shit it's pants

class HUDGenerationEvent extends ActionEvent {
    /**
     * The HUD type to generate, this will usually be
     * the name of the HUD type chosen in the Options menu.
     */
    public var hudType:String;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(HUD_GENERATION);
    }
}

class CameraMoveEvent extends ActionEvent {
    /**
     * The position to move the camera to.
     */
    public var position:FlxPoint;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(CAMERA_MOVE);
    }
}

class DisplayRatingEvent extends ActionEvent {
    /**
     * The rating to display.
     */
    public var rating:String;

    /**
     * The sprite to display the rating on (only available on post).
     */
    public var sprite:RatingSprite;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(DISPLAY_RATING);
    }
}

class DisplayComboEvent extends ActionEvent {
    /**
     * The combo to display.
     */
    public var combo:Int;

    /**
     * The sprites to display the combo on (only available on post).
     */
    public var sprites:Array<ComboDigitSprite>;
    
    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(DISPLAY_COMBO);
    }
}

class SongEvent extends ActionEvent {
    /**
     * The time of the event in the chart.
     */
    public var time:Float;

    /**
     * The parameters of the event.
     */
    public var params:Dynamic;

    /**
     * The type of the event.
     */
    public var eventType:String;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(SONG_EVENT);
    }
}

class GameOverEvent extends ActionEvent {
    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(GAME_OVER);
    }
}

class GameOverCreateEvent extends ActionEvent {
    /**
     * The ID of the character to show up on
     * the game over screen.
     */
    public var characterID:String;

    /**
     * The character showing up on the game over
     * screen (only available on post).
     */
    public var character:Character;

    /**
     * A path to the sound to play on
     * the game over screen when dying.
     */
    public var deathSFX:String;

    /**
     * A path to the music to play on
     * the game over screen.
     */
    public var music:String;

    /**
     * A path to the sound to play on
     * the game over screen when retrying.
     */
    public var retrySFX:String;

    /**
     * This is the constructor for this event, mainly
     * used just to specify it's type.
     */
    public function new() {
        super(GAME_OVER_CREATE);
    }
}