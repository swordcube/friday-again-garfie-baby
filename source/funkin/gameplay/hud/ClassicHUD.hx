package funkin.gameplay.hud;

import flixel.ui.FlxBar;
import funkin.states.PlayState;

class ClassicHUD extends BaseHUD {
    public function new(playField:PlayField) {
        super(playField);
    }

    public var healthBarBG:FlxSprite;
    public var healthBar:FlxBar;

    override function generateHealthBar():Void {
        final game:PlayState = PlayState.instance;
        final barY:Float = (Options.downscroll) ? 72 : FlxG.height * 0.9;

        healthBarBG = new FlxSprite(0, barY);
        healthBarBG.loadGraphic(getHUDImage("healthBar"));
        healthBarBG.screenCenter(X);
        add(healthBarBG);

        healthBar = new FlxBar(
            healthBarBG.x + 4, healthBarBG.y + 4,
            FlxBarFillDirection.RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8),
            null, null, 0, 2
        );
        healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33); // using direct 0xFF codes doesn't work in lua, must use FlxColor.fromString there instead
        healthBar.value = 1;
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
    }

    override function updateHealthBar() {
        positionIcons();
    }
    
    override function positionIcons():Void {
        var percent = healthBar.value / healthBar.max;
        iconP1.x = healthBar.x + (healthBar.width * (1 - percent)) - 26;
        iconP1.y = healthBar.y + (healthBar.height * 0.5) - (iconP1.height * 0.5);
    
        iconP2.x = healthBar.x + (healthBar.width * percent) - (iconP2.width - 26);
        iconP2.y = healthBar.y + (healthBar.height * 0.5) - (iconP2.height * 0.5);
    }
    
    override function update(elapsed:Float):Void {
        positionIcons();
        super.update(elapsed);
    }
    
    override function beatHit(beat:Int):Void {
        iconP2.bop();
        iconP1.bop();
    }

    private function getHUDImage(name:String):String {
        return Paths.image('gameplay/hudskins/classic/images/${name}');
    }
}