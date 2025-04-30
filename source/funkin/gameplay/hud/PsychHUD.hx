package funkin.gameplay.hud;

import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxStringUtil;

import funkin.backend.events.NoteEvents;
import funkin.states.PlayState;

class PsychHUD extends BaseHUD {
    public function new(playField:PlayField) {
        super(playField);
    }

    public var ratingStuff:Array<Array<Dynamic>> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4],      // From 20% to 39%
		['Bad', 0.5],       // From 40% to 49%
		['Bruh', 0.6],      // From 50% to 59%
		['Meh', 0.69],      // From 60% to 68%
		['Nice', 0.7],      // 69%
		['Good', 0.8],      // From 70% to 79%
		['Great', 0.9],     // From 80% to 89%
		['Sick!', 1],       // From 90% to 99%
		['Perfect!!', 1]    // The value on this one isn't used actually, since Perfect is always "1"
	];
    public var ratingName:String = "?";
    public var ratingFC:String = "";
    public var botplaySine:Float = 0;

    public var healthBarBG:FlxSprite;
    public var healthBar:FlxBar;

    public var timeText:FlxText;
    public var timeBar:FlxBar;
    public var timeBarBG:FlxSprite;

    public var scoreText:FlxText;
    public var botplayText:FlxText;

    override function generateHealthBar():Void {
        final game:PlayState = PlayState.instance;
        final barY:Float = (Options.downscroll) ? 72 : FlxG.height * 0.9;

        healthBarBG = new FlxSprite(0, barY);
        healthBarBG.loadGraphic(Paths.image("gameplay/healthBar"));
        healthBarBG.screenCenter(X);
        add(healthBarBG);

        healthBar = new FlxBar(
            healthBarBG.x + 4, healthBarBG.y + 4,
            FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8),
            null, null, playField.stats.minHealth, playField.stats.maxHealth
        );
        healthBar.createFilledBar(
            (game.opponent?.healthColor != null) ? game.opponent.healthColor : 0xFFFF0000,
            (game.player?.healthColor != null) ? game.player.healthColor : 0xFF66FF33
        );
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

        scoreText = new FlxText(healthBarBG.x + (healthBarBG.width - 190), healthBarBG.y + 40, 0, "");
        scoreText.setFormat(Paths.font("fonts/vcr"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        scoreText.borderSize = 1.25;
        add(scoreText);

        botplayText = new FlxText(400, playField.playerStrumLine.y, 0, "BOTPLAY", 32);
        botplayText.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        botplayText.screenCenter(X);
        botplayText.borderSize = 1.25;
        botplayText.y += (playField.playerStrumLine.strums.height - botplayText.height) * 0.5;
        add(botplayText);

        var timeY:Float = 19;
        if(Options.downscroll)
            timeY = FlxG.height - 44;
        
        var timeX:Float = 45 + (FlxG.width / 2) - 245;
        timeBarBG = new FlxSprite(timeX, timeY + 4).loadGraphic(Paths.image("gameplay/hudskins/Psych/images/timeBar"));
        timeBarBG.alpha = 0;
        timeBarBG.color = FlxColor.BLACK;
        add(timeBarBG);

        timeBar = new FlxBar(
            timeBarBG.x + 4, timeBarBG.y + 4,
            FlxBarFillDirection.LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8),
            game, "songPercent", 0, 1
        );
        timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
        timeBar.numDivisions = 0; // btw shadowmario from psych 0.5.2h era this won't cause any lag it's just basic math
        timeBar.alpha = 0;
        add(timeBar);

        timeText = new FlxText(timeX, timeY - 4, 400, "0:00", 32);
        timeText.setFormat(Paths.font("fonts/vcr"), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        timeText.alpha = 0;
        timeText.borderSize = 2;
        add(timeText);

        playField.onNoteHit.add(onNoteHit);
    }

    private function onCreatePost():Void {
        playField.comboDisplay.legacyStyle = true;
    }

    private function onSongStart():Void {
        FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
        FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
        FlxTween.tween(timeText, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    }

    override function updateHealthBar():Void {
        final percent:Float = healthBar.value / healthBar.max;
        iconP2.health = 1 - percent;
        iconP1.health = percent;
        positionIcons();
    }

    override function updatePlayerStats(stats:PlayerStats):Void {
        if(stats.accuracy != 0) {
            ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
            if(stats.accuracy < 1) {
                for(i in 0...ratingStuff.length - 1) {
                    if(stats.accuracy < ratingStuff[i][1]) {
                        ratingName = ratingStuff[i][0];
                        break;
                    }
                }
            }
        }
        ratingFC = "";
        if(stats.judgements.get("killer") > 0)
            ratingFC = "KFC";  //heheg   kentucky fried chicken

        if(stats.judgements.get("sick") > 0)
            ratingFC = "SFC";

        if(stats.judgements.get("good") > 0)
            ratingFC = "GFC";

        if(stats.judgements.get("bad") > 0 || stats.judgements.get("shit") > 0)
            ratingFC = "FC";

        if(stats.misses > 0 && stats.misses < 10)
            ratingFC = "SDCB";

        else if(stats.misses >= 10)
            ratingFC = "Clear";

        var ratingStr:String = ratingName;
        if(stats.accuracy != 0)
            ratingStr += ' (${FlxMath.roundDecimal(stats.accuracy * 100, 2)}%) - ${ratingFC}';

        scoreText.text = (
            "Score: " + stats.score +
            " | Misses: " + stats.misses +
            " | Rating: " + ratingStr
        );
        scoreText.screenCenter(X);
    }

    override function positionIcons() {
        final percent:Float = healthBar.value / healthBar.max;
        iconP1.x = healthBar.x + (healthBar.width * (1 - percent)) - 26;
        iconP1.y = healthBar.y + (healthBar.height * 0.5) - (iconP1.height * 0.5);

        iconP2.x = healthBar.x + (healthBar.width * (1 - percent)) - (iconP2.width - 26);
        iconP2.y = healthBar.y + (healthBar.height * 0.5) - (iconP2.height * 0.5);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        final game:PlayState = PlayState.instance;
        if(!game.startingSong)
            timeText.text = FlxStringUtil.formatTime(game.inst.time * 0.001);

        botplayText.visible = playField.playerStrumLine.botplay;
        if(botplayText.visible) {
            botplaySine += 180 * elapsed;
            botplayText.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
        }
        healthBar.setRange(playField.stats.minHealth, playField.stats.maxHealth);
        healthBar.value = playField.stats.health;

        final iconSpeed:Float = Math.exp(-elapsed * 9);
        iconP2.scale.set(
            FlxMath.lerp((150 * iconP2.size.x) / iconP2.frameWidth, iconP2.scale.x, iconSpeed),
            FlxMath.lerp((150 * iconP2.size.y) / iconP2.frameHeight, iconP2.scale.y, iconSpeed)
        );
        iconP1.scale.set(
            FlxMath.lerp((150 * iconP1.size.x) / iconP1.frameWidth, iconP1.scale.x, iconSpeed),
            FlxMath.lerp((150 * iconP1.size.y) / iconP1.frameHeight, iconP1.scale.y, iconSpeed)
        );
        iconP2.updateHitbox();
        iconP1.updateHitbox();
        positionIcons();
    }

    override function bopIcons():Void {
        iconP2.bop();
        iconP1.bop();

        iconP2.bopTween.cancel();
        iconP1.bopTween.cancel();
    }

    override function beatHit(beat:Int):Void {
        if(beat < 0)
            return;
        
        bopIcons();
    }

    private function onNoteHit(e:NoteHitEvent):Void {
        if(e.note.strumLine != playField.playerStrumLine)
            return;

        scoreText.scale.set(1.075, 1.075);
        FlxTween.cancelTweensOf(scoreText.scale);
        FlxTween.tween(scoreText.scale, {x: 1, y: 1}, 0.2);
    }
}