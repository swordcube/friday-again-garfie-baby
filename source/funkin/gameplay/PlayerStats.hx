package funkin.gameplay;

/**
 * A class representing data for the player's
 * statistics, such as score, accuracy, combo, etc.
 */
@:build(funkin.backend.macros.ResettableClassMacro.build())
class PlayerStats {
    /**
     * The player's current score.
     */
    public var score:Int = 0;

    /**
     * The current accuracy score of the player.
     * 
     * This is only really used to calculate accuracy,
     * but you can get a rough score with it by doing this:
     * 
     * ```haxe
     * trace(accuracyScore * 350);
     * ```
     */
    public var accuracyScore:Float = 0;

    /**
     * The total amount of notes the player has missed.
     */
    public var misses(default, set):Int = 0;

    /**
     * The amount of times the player's combo was broken.
     */
    public var comboBreaks(default, set):Int = 0;

    /**
     * The current combo of the player.
     * 
     * Resets when the player misses a note.
     */
    public var combo:Int = 0;

    /**
     * The current miss combo of the player.
     * 
     * Resets when the player hits a note.
     */
    public var missCombo:Int = 0;

    /**
     * The total amount of notes the player has hit.
     * 
     * This value is unaffected by misses.
     */
    public var totalNotesHit:Int = 0;
    
    /**
     * A map containing the amount of times every
     * judgement has been hit.
     */
    @:ignoreReset
    public var judgements:Map<String, Int> = [
        "killer" => 0,
        "sick"   => 0,
        "good"   => 0,
        "bad"    => 0,
        "shit"   => 0,
        "miss"   => 0,
        "cb"     => 0
    ];

    /**
     * The player's current accuracy. (from 0 to 1)
     */
    @:ignoreReset
    public var accuracy(get, never):Float;

    /**
     * The minimum health value for the player.
     */
    public var minHealth(default, set):Float = 0;

    /**
     * The maximum health value for the player.
     */
    public var maxHealth(default, set):Float = 1;

    /**
     * The current health value for the player.
     */
    public var health(default, set):Float = 0.5;

    /**
     * Constructs a new `PlayerStats`.
     */
    public function new() {}

    // --------------- //
    // [ Private API ] //
    // --------------- //

    // Used for resetting stuff that the macro
    // has trouble with
    private function resetBase():Void {
        for(judge in judgements.keys())
            judgements.set(judge, 0);
    }

    @:noCompletion
    private function get_accuracy():Float {
        if(accuracyScore == 0 || (totalNotesHit + misses) == 0)
            return 0;

        return accuracyScore / (totalNotesHit + misses);
    }

    @:noCompletion
    private inline function set_misses(newValue:Int):Int {
        misses = newValue;
        judgements.set("miss", misses);
        return misses;
    }

    @:noCompletion
    private inline function set_comboBreaks(newValue:Int):Int {
        comboBreaks = newValue;
        judgements.set("cb", comboBreaks);
        return comboBreaks;
    }

    @:noCompletion
    private inline function set_minHealth(newValue:Float):Float {
        minHealth = newValue;
        health = FlxMath.bound(health, minHealth, maxHealth);
        return minHealth;
    }

    @:noCompletion
    private inline function set_maxHealth(newValue:Float):Float {
        maxHealth = newValue;
        health = FlxMath.bound(health, minHealth, maxHealth);
        return maxHealth;
    }

    @:noCompletion
    private inline function set_health(newValue:Float):Float {
        health = FlxMath.bound(newValue, minHealth, maxHealth);
        return health;
    }
}