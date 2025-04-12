package funkin.gameplay;

import funkin.gameplay.UISkin;
import funkin.graphics.SkinnableUISprite;

import funkin.gameplay.scoring.Scoring;

class ComboDisplay extends FlxSpriteGroup {
    public var skin:String;
    public var legacyStyle:Bool = false;

    public function new(x:Float = 0, y:Float = 0, skin:String) {
        super(x, y);
        this.skin = skin;

        for(i in 0...20) {
            final rating:RatingSprite = new RatingSprite().setup(x, y, Scoring.getJudgements().first(), skin ?? (this.skin ?? "funkin"));
            rating.kill();
            add(rating);
            
            final digit:ComboDigitSprite = new ComboDigitSprite().setup(x, y, "0", skin ?? (this.skin ?? "funkin"));
            digit.kill();
            add(digit);
        }
    }

    public function getRatingSprite():RatingSprite {
        final sprite:RatingSprite = cast recycle(RatingSprite);
        members.remove(sprite);
        members.push(sprite);
        return sprite;
    }

    public function getComboDigitSprite():ComboDigitSprite {
        final sprite:ComboDigitSprite = cast recycle(ComboDigitSprite);
        members.remove(sprite);
        members.push(sprite);
        return sprite;
    }

    public function displayRating(rating:String, ?skin:String):RatingSprite {
        final sprite:RatingSprite = getRatingSprite().setup((legacyStyle) ? x - 40 : x, (legacyStyle) ? y - 60 : y, rating, skin ?? (this.skin ?? "funkin"));
        sprite.antialiasing = sprite.skinData.antialiasing ?? FlxSprite.defaultAntialiasing;

        sprite.acceleration.y = 550;
		sprite.velocity.x -= FlxG.random.int(0, 10);
		sprite.velocity.y -= FlxG.random.int(140, 175);
		
        final scale:Float = sprite.skinData.scale * ((legacyStyle) ? 1 : 0.95);
        sprite.scale.set(scale, scale);
		sprite.updateHitbox();

        sprite.scale.set(scale * 0.95, scale * 0.95);
        FlxTween.tween(sprite.scale, {x: scale, y: scale}, 0.2);

        sprite.scrollFactor.set(scrollFactor?.x ?? 1.0, scrollFactor?.y ?? 1.0);

        if(!legacyStyle) {
            sprite.x -= sprite.width * 0.5;
            sprite.y -= sprite.height * 0.5;   
        }
		FlxTween.tween(sprite, {alpha: 0}, 0.2, {
			startDelay: Conductor.instance.beatLength * 0.001,
			onComplete: (_) -> sprite.kill()
		});
        return sprite;
    }

    public function displayCombo(combo:Int, ?skin:String):Array<ComboDigitSprite> {
        var strCombo:String = Std.string(Math.abs(combo));
        while(strCombo.length < 3)
            strCombo = "0" + strCombo;

        if(combo < 0)
            strCombo = "-" + strCombo;

        final digitSprites:Array<ComboDigitSprite> = [];
        for(i in 0...strCombo.length) {
            final sprite:ComboDigitSprite = getComboDigitSprite().setup((legacyStyle) ? x + ((i - ((combo < 0) ? 1 : 0)) * 43) - 90 : x - (36 * i) - 65, (legacyStyle) ? y + 80 : y + 40, strCombo.charAt((legacyStyle) ? i : strCombo.length - i - 1), skin ?? (this.skin ?? "funkin"));    
            sprite.antialiasing = sprite.skinData.antialiasing ?? FlxSprite.defaultAntialiasing;

            final scale:Float = sprite.skinData.scale * ((legacyStyle) ? 1 : 0.95);
            sprite.scale.set(scale, scale);
            sprite.updateHitbox();

            sprite.scale.set(scale * 0.95, scale * 0.95);
            FlxTween.tween(sprite.scale, {x: scale, y: scale}, 0.2);
            
            sprite.acceleration.y = FlxG.random.int(200, 300);
            sprite.velocity.x = FlxG.random.float(-5, 5);
            sprite.velocity.y -= FlxG.random.int(140, 160);

            sprite.color = (combo < 0) ? 0xFFc84040 : FlxColor.WHITE;
            sprite.scrollFactor.set(scrollFactor?.x ?? 1.0, scrollFactor?.y ?? 1.0);

            FlxTween.tween(sprite, {alpha: 0}, 0.2, {
                startDelay: Conductor.instance.beatLength * 0.002,
                onComplete: (_) -> sprite.kill()
            });
            digitSprites.push(sprite);
        }
        return digitSprites;
    }
}

class RatingSprite extends SkinnableUISprite {
    public var rating(default, set):String;

    public function setup(x:Float, y:Float, rating:String, skin:String):RatingSprite {
        loadSkin(skin);
        CoolUtil.resetSprite(this, x, y);
        
        this.rating = rating;
        return this;
    }

    override function loadSkin(newSkin:String) {
        if(_skin == newSkin)
            return;

        final json:UISkinData = UISkin.get(newSkin);
        loadSkinComplex(newSkin, json.rating, 'gameplay/uiskins/${newSkin}');
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_rating(newRating:String):String {
        rating = newRating;
        
        if(animation.exists(rating))
            animation.play(rating);
        
        updateHitbox();
        return rating;
    }
}

class ComboDigitSprite extends SkinnableUISprite {
    public var digit(default, set):String;

    public function setup(x:Float, y:Float, digit:String, skin:String):ComboDigitSprite {
        loadSkin(skin);
        CoolUtil.resetSprite(this, x, y);
        
        this.digit = digit;
        return this;
    }

    override function loadSkin(newSkin:String) {
        if(_skin == newSkin)
            return;

        final json:UISkinData = UISkin.get(newSkin);
        loadSkinComplex(newSkin, json.combo, 'gameplay/uiskins/${newSkin}');
    }

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_digit(newDigit:String):String {
        digit = newDigit;
        if(digit == "-" && !animation.exists(digit))
            digit = "minus";

        if(animation.exists(digit))
            animation.play(digit);
        
        updateHitbox();
        return digit;
    }
}