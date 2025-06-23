package funkin.gameplay.hud;

import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxStringUtil;

import funkin.states.PlayState;

// TODO: add the song time stuff

class ClassicPlusHUD extends BaseHUD {
    public function new(playField:PlayField) {
        this.name = "Classic+";
        super(playField);
    }

    public var healthBarBG:FlxSprite;
    public var healthBar:FlxBar;

    public var infoContainer:FlxSpriteContainer;
    public var scoreInfo:StatDisplay;
    public var missesInfo:StatDisplay;
    public var accuracyInfo:StatDisplay;

    public function repositionMainInfos():Void {
        scoreInfo.x = infoContainer.x;
        missesInfo.x = scoreInfo.x + scoreInfo.width + 10;
        accuracyInfo.x = missesInfo.x + missesInfo.width + 10;
        infoContainer.screenCenter(X);
    }

    override function generateHealthBar():Void {
        final game:PlayState = PlayState.instance;
        final barY:Float = (Options.downscroll) ? 72 : FlxG.height * 0.89;

        healthBarBG = new FlxSprite(0, barY);
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
        iconP1.flipX = !iconP1.flipX;
        add(iconP1);

        infoContainer = new FlxSpriteContainer(healthBarBG.x, healthBarBG.y + 35);
        add(infoContainer);

        scoreInfo = new StatDisplay(0, 0, this, "score", "0");
        missesInfo = new StatDisplay(scoreInfo.x + scoreInfo.width + 20, 0, this, "misses", "0");
        accuracyInfo = new StatDisplay(missesInfo.x + missesInfo.width + 20, 0, this, "accuracy", "0.00%", false);
        
        infoContainer.add(scoreInfo);
        infoContainer.add(missesInfo);
        infoContainer.add(accuracyInfo);

        repositionMainInfos();
    }

    override function updateHealthBar() {
        final percent:Float = healthBar.value / healthBar.max;
        iconP2.health = 1 - percent;
        iconP1.health = percent;
        positionIcons();
    }

    override function updatePlayerStats(stats:PlayerStats):Void {
        scoreInfo.updateText(FlxStringUtil.formatMoney(stats.score, false, true));
        missesInfo.updateText(FlxStringUtil.formatMoney(stats.misses, false, true));
        
        final roundedAccuracy:Float = FlxMath.roundDecimal(stats.accuracy * 100, 2);
        switch(FlxMath.getDecimals(roundedAccuracy)) {
            case 0: accuracyInfo.updateText('${roundedAccuracy}.00%');
            case 1: accuracyInfo.updateText('${roundedAccuracy}0%');
            default: accuracyInfo.updateText('${roundedAccuracy}%');
        }
        repositionMainInfos();
    }
    
    override function positionIcons():Void {
        final percent:Float = healthBar.value / healthBar.max;
        iconP1.x = healthBar.x + (healthBar.width * (1 - percent)) - 26;
        iconP1.y = healthBar.y + (healthBar.height * 0.5) - (iconP1.height * 0.5);
    
        iconP2.x = healthBar.x + (healthBar.width * (1 - percent)) - (iconP2.width - 26);
        iconP2.y = healthBar.y + (healthBar.height * 0.5) - (iconP2.height * 0.5);
    }
    
    override function update(elapsed:Float):Void {
        healthBar.setRange(playField.stats.minHealth, playField.stats.maxHealth);
        healthBar.value = FlxMath.lerp(healthBar.value, playField.stats.health, FlxMath.getElapsedLerp(0.25, elapsed));

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
}

class StatDisplay extends FlxSpriteContainer {
    public var hud:ClassicPlusHUD;

    public var textDisplay:FlxText;
    public var separatorSprite:FunkinSprite;

    public function new(x:Float = 0, y:Float = 0, hud:ClassicPlusHUD, icon:String, text:String, ?hasSeparator:Bool = true) {
        super(x, y);
        this.hud = hud;

        final iconSprite:FunkinSprite = new FunkinSprite();
        iconSprite.loadGraphic(hud.getHUDImage(icon));
        iconSprite.setGraphicSize(34, 34);
        iconSprite.updateHitbox();
        
        final colonSprite:FunkinSprite = new FunkinSprite(iconSprite.x + iconSprite.width, 5);
        colonSprite.loadGraphic(hud.getHUDImage("colon"));
        colonSprite.setScale(iconSprite.scale.x * 0.88, XY);
        
        textDisplay = new FlxText(colonSprite.x + colonSprite.width + 3, 3, 0, text);
        textDisplay.setFormat(Paths.font("fonts/vcr"), 24, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        textDisplay.borderSize = 1.25;

        if(hasSeparator) {
            separatorSprite = new FunkinSprite(textDisplay.x + textDisplay.width + 20, 10);
            separatorSprite.loadGraphic(hud.getHUDImage("separator"));
            separatorSprite.setGraphicSize(15, 15);
            separatorSprite.updateHitbox();
        }
        add(iconSprite);
        add(colonSprite);
        add(textDisplay);
        
        if(hasSeparator)
            add(separatorSprite);
    }

    public function updateText(value:String):Void {
        textDisplay.text = value;
        if(separatorSprite != null)
            separatorSprite.x = textDisplay.x + textDisplay.width + 10;
    }
}