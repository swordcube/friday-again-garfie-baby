package funkin.states.menus;

import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.effects.FlxFlicker;

import funkin.backend.macros.GitCommitMacro;
import funkin.substates.EditorPickerSubState;

class MainMenuState extends FunkinState {
    public var options:Array<MainMenuOption>;

    public var bg:FlxSprite;
    public var magenta:FlxSprite;
    
    public var menuItems:FlxTypedContainer<FlxSprite>;
    public var camFollow:FlxObject;

    public var transitioning:Bool = false;
    public var versionText:FlxText;

    public static var curSelected:Int = 0;

    public function initOptions():Void {
        options = [
            {
                name: "storymode",
                callback: () -> trace("story menu TODO"),
            },
            {
                name: "freeplay",
                callback: () -> FlxG.switchState(new FreeplayState()),
            },
            {
                name: "credits",
                callback: () -> trace("credits menu TODO"),
            },
            {
                name: "options",
                callback: () -> FlxG.switchState(new OptionsState()),
            },
        ];
    }

    override function create():Void {
        super.create();

        persistentUpdate = true;
        initOptions();

        if(FlxG.sound.music == null || !FlxG.sound.music.playing)
            CoolUtil.playMenuMusic();

        FlxG.sound.music.looped = true;
        Conductor.instance.music = FlxG.sound.music;

        bg = new FlxSprite().loadGraphic(Paths.image("menus/bg"));
        bg.scrollFactor.set(0, Math.max(0.1, 0.25 - (0.05 * (options.length - 4))));
        bg.scale.set(1.175, 1.175);
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        magenta = new FlxSprite().loadGraphic(Paths.image("menus/bg_desat"));
        magenta.scrollFactor.set(bg.scrollFactor.x, bg.scrollFactor.y);
        magenta.scale.set(bg.scale.x, bg.scale.y);
        magenta.updateHitbox();
        magenta.screenCenter();
        magenta.color = 0xFFFD719B;
        magenta.visible = false;
        add(magenta);

        menuItems = new FlxTypedContainer<FlxSprite>();
        add(menuItems);

        final offset:Float = 108 - (Math.max(options.length, 4) - 4) * 80;
		final scr:Float = (options.length < 6) ? 0 : (options.length - 4) * 0.135;
        
        for(i => option in options) {
            final menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			
			menuItem.frames = Paths.getSparrowAtlas('menus/main/${option.name}');
			menuItem.animation.addByPrefix("idle", '${option.name} idle', 24);
			menuItem.animation.addByPrefix("selected", '${option.name} selected', 24);
			menuItem.animation.play("idle");

			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);

			menuItems.add(menuItem);   
        }
        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);

        var versionString:String = 'Garfie Engine v${FlxG.stage.application.meta.get("version")}';
        #if TEST_BUILD
        versionString += ' (${GitCommitMacro.getBranch()}/${GitCommitMacro.getCommitHash()})';
        #end
        versionString += "\nFriday Night Funkin' v0.6.0";
        
        versionText = new FlxText(5, FlxG.height - 2, 0, versionString);
		versionText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionText.scrollFactor.set();
        versionText.y -= versionText.height;
		add(versionText);
        
        FlxG.camera.follow(camFollow, LOCKON, 0.06);
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if(!transitioning) {
            final wheel:Float = -FlxG.mouse.wheel;
            if(controls.justPressed.UI_UP || wheel < 0)
                changeSelection(-1);
    
            if(controls.justPressed.UI_DOWN || wheel > 0)
                changeSelection(1);
    
            if(controls.justPressed.ACCEPT)
                onSelect();

            if(controls.justPressed.DEBUG) {
                persistentUpdate = false;
                openSubState(new EditorPickerSubState());
            }
        }
        if(controls.justPressed.BACK) {
            persistentUpdate = false;
            FlxG.switchState(new TitleState());
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        curSelected = FlxMath.wrap(curSelected + by, 0, options.length - 1);

        for(i => item in menuItems) {
            if(curSelected == i) {
                item.animation.play("selected");
                item.centerOffsets();

                final add:Float = (menuItems.length > 4) ? (menuItems.length * 8) : 0;
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y - add);
            }
            else {
                item.animation.play("idle");
                item.centerOffsets();
            }
        }
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }
    
    public function onSelect():Void {
        if(transitioning)
            return;

        final option:MainMenuOption = options[curSelected];
        if(option.fireImmediately) {
            if(option.callback != null)
                option.callback();
            
            return;
        }
        var bgScale = bg.scale.x;
		var bgTargetScale = FlxG.height / bg.frameHeight;
		var bgScroll = bg.scrollFactor.y;

		FlxTween.num(0.0, 1.0, 0.25, {ease: FlxEase.backOut}, (progress:Float) -> {
			progress /= 1.175;

			var scale = FlxMath.lerp(bgScale, bgTargetScale, progress);
			magenta.scale.x = magenta.scale.y = bg.scale.x = bg.scale.y = scale;

			var scroll = FlxMath.lerp(bgScroll, 0.0, progress);
			bg.scrollFactor.y = magenta.scrollFactor.y = scroll;
		});
        _bgFlicker();

        for(i => item in menuItems) {
            if(curSelected == i) {
                FlxFlicker.flicker(item, 1.1, 0.06, false, false, (_) -> {
                    if(option.callback != null)
                        option.callback();
                });
            }
            else {
                FlxTween.tween(item, {alpha: 0.0}, 0.25, {
                    ease: FlxEase.quadOut,
					onComplete: (_) -> {
                        item.kill();
					}
				});
            }
        }
        transitioning = true;
        FlxG.sound.play(Paths.sound("menus/sfx/select"));
    }

    //----------- [ Private API ] -----------//

    private var magTwn:FlxTween = null;

	private function _magentaFlicker(?tmr:FlxTimer):Void {
		if(magTwn != null)
            magTwn.cancel();
		
		magenta.alpha = 1.0;
		magTwn = FlxTween.tween(magenta, {alpha: 0}, 0.12, {ease: FlxEase.circIn});
	}
	
	private function _bgFlicker():Void {
		magenta.visible = true;
		
		if(Options.flashingLights) {
			_magentaFlicker();
			new FlxTimer().start(0.24, _magentaFlicker, Math.floor(1 / 0.24));
		}
        else {
			magenta.alpha = 0.0;
			FlxTween.tween(magenta, {alpha: 1.0}, 0.96, {ease: FlxEase.quintOut});
		}
	}
}

@:structInit
class MainMenuOption {
    public var name:String;
    public var callback:Void->Void;

    @:optional
    public var fireImmediately:Bool = false;
}