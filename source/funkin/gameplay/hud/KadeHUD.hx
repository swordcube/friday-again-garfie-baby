package funkin.gameplay.hud;

import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxStringUtil;

import funkin.states.PlayState;

class KadeHUD extends BaseHUD {
    public function new(playField:PlayField) {
        super(playField);
    }

    public var timeBarBG:FlxSprite;
    public var timeBar:FlxBar;

    public var healthBarBG:FlxSprite;
    public var healthBar:FlxBar;

    public var scoreText:FlxText;

    override function generateHealthBar():Void {
        final game:PlayState = PlayState.instance;

        final timeBarY:Float = (Options.downscroll) ? FlxG.height * 0.9 : 10;
        final healthBarY:Float = (Options.downscroll) ? 72 : FlxG.height * 0.9;

        timeBarBG = new FlxSprite(0, timeBarY);
        timeBarBG.loadGraphic(Paths.image("gameplay/healthBar"));
        timeBarBG.screenCenter(X);
        add(timeBarBG);

        timeBar = new FlxBar(
            timeBarBG.x + 4, timeBarBG.y + 4,
            FlxBarFillDirection.LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8),
            null, null
        );
        timeBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
        timeBar.numDivisions = 0;
        add(timeBar);

        var timeText = new FlxText(0, timeBar.y - 5, FlxG.width, game.currentChart.meta.song.title);
        timeText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        add(timeText);

        healthBarBG = new FlxSprite(0, healthBarY);
        healthBarBG.loadGraphic(Paths.image("gameplay/healthBar"));
        healthBarBG.screenCenter(X);
        add(healthBarBG);

        healthBar = new FlxBar(
            healthBarBG.x + 4, healthBarBG.y + 4,
            FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8),
            null, null, playField.stats.minHealth, playField.stats.maxHealth
        );
        healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33); // using direct 0xFF codes doesn't work in lua, must use FlxColor.fromString there instead
        healthBar.value = playField.stats.health;
        healthBar.numDivisions = 0;
        add(healthBar);

        var opponentIcon = "face";

        if(game != null)
            opponentIcon = game.currentChart.meta.game.getCharacter("opponent");
        
        var playerIcon = "face";
        if(game != null)
            playerIcon = game.currentChart.meta.game.getCharacter("player");
        
        iconP2 = new HealthIcon(opponentIcon, 0);
        add(iconP2);

        iconP1 = new HealthIcon(playerIcon, 1);
        iconP1.flipX = true;
        add(iconP1);

        var garfieWatermark = new FlxText(10, FlxG.height * 0.97, 0, game.currentChart.meta.song.title + " - " + game.currentDifficulty + " | Garfie Engine " + FlxG.stage.application.meta.get("version"));
        garfieWatermark.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        add(garfieWatermark);

        scoreText = new FlxText(0, healthBarBG.y + 50, FlxG.width, "Score:N/A");
        scoreText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        add(scoreText);
    }

    override function updateHealthBar() {
        final percent:Float = healthBar.value / healthBar.max;
        iconP2.health = 1 - percent;
        iconP1.health = percent;
        positionIcons();
    }

    override function updatePlayerStats(stats:PlayerStats):Void {
        scoreText.text = "Score:" + stats.score + " | Combo Breaks:" + stats.misses + " | Accuracy:" + FlxMath.roundDecimal(stats.accuracy * 100, 2) + "% | " + GenerateLetterRank(stats);
    }
    
    override function positionIcons():Void {
        final percent:Float = healthBar.value / healthBar.max;
        iconP1.x = healthBar.x + (healthBar.width * (1 - percent)) - 26;
        iconP1.y = healthBar.y + (healthBar.height * 0.5) - (iconP1.height * 0.5);
    
        iconP2.x = healthBar.x + (healthBar.width * (1 - percent)) - (iconP2.width - 26);
        iconP2.y = healthBar.y + (healthBar.height * 0.5) - (iconP2.height * 0.5);
    }
    
    override function update(elapsed:Float):Void {
        if (PlayState.instance.inst != null) {
            timeBar.setRange(0, PlayState.instance.inst.length);
            timeBar.value = PlayState.instance.inst.time;
        }

        healthBar.value = playField.stats.health;
        healthBar.setRange(playField.stats.minHealth, playField.stats.maxHealth);

        positionIcons();
        super.update(elapsed);
    }

    override function bopIcons():Void {
        iconP2.bop();
        iconP1.bop();
        iconP1.bopTween.onUpdate = (_) -> {
            iconP1.updateHitbox();
            positionIcons();
        };
        positionIcons();
    }
    
    override function beatHit(beat:Int):Void {
        if(beat < 0)
            return;
        
        bopIcons();
    }

    /**
     * Straight From Kade! (but slightly tweaked lol)
     */
    public static function GenerateLetterRank(stats:PlayerStats) // generate a letter ranking
	{
		var ranking:String = "N/A";

		if (stats.misses == 0 && stats.judgements.get("bad") == 0 && stats.judgements.get("shit") == 0 && stats.judgements.get("good") == 0) // Marvelous (SICK) Full Combo
			ranking = "(MFC)";
		else if (stats.misses == 0 && stats.judgements.get("bad") == 0 && stats.judgements.get("shit") == 0 && stats.judgements.get("good") >= 1) // Good Full Combo (Nothing but Goods & Sicks)
			ranking = "(GFC)";
		else if (stats.misses == 0) // Regular FC
			ranking = "(FC)";
		else if (stats.misses < 10) // Single Digit Combo Breaks
			ranking = "(SDCB)";
		else
			ranking = "(Clear)";

		var wifeConditions:Array<Bool> = [
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.9935, // AAAAA
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.980, // AAAA:
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.970, // AAAA.
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.955, // AAAA
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.90, // AAA:
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.80, // AAA.
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99.70, // AAA
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 99, // AA:
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 96.50, // AA.
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 93, // AA
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 90, // A:
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 85, // A.
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 80, // A
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 70, // B
			FlxMath.roundDecimal(stats.accuracy * 100, 2) >= 60, // C
			FlxMath.roundDecimal(stats.accuracy * 100, 2) < 60 // D
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];
			if (b)
			{
				switch (i)
				{
					case 0:
						ranking += " AAAAA";
					case 1:
						ranking += " AAAA:";
					case 2:
						ranking += " AAAA.";
					case 3:
						ranking += " AAAA";
					case 4:
						ranking += " AAA:";
					case 5:
						ranking += " AAA.";
					case 6:
						ranking += " AAA";
					case 7:
						ranking += " AA:";
					case 8:
						ranking += " AA.";
					case 9:
						ranking += " AA";
					case 10:
						ranking += " A:";
					case 11:
						ranking += " A.";
					case 12:
						ranking += " A";
					case 13:
						ranking += " B";
					case 14:
						ranking += " C";
					case 15:
						ranking += " D";
				}
				break;
			}
		}

		if (FlxMath.roundDecimal(stats.accuracy * 100, 2) == 0)
			ranking = "N/A";
 
		return ranking;
	}
}