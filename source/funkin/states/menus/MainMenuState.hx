package funkin.states.menus;

import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.effects.FlxFlicker;

import funkin.backend.macros.GitCommitMacro;
import funkin.substates.EditorPickerSubState;

import funkin.utilities.InputFormatter;
import funkin.mobile.input.ControlsHandler;

class MainMenuState extends FunkinState {
    public var options:Array<MainMenuOption>;

    public var bg:FlxSprite;
    public var magenta:FlxSprite;
    
    public var menuItems:FlxTypedContainer<FlxSprite>;
    public var camFollow:FlxObject;

    public var transitioning:Bool = false;
    public var versionText:FlxText;

    #if mobile
    public var gyroPan:Null<FlxPoint>;
    #end
    public static var curSelected:Int = 0;

    public function initOptions():Void {
        options = [
            {
                name: "storymode",
                rpcName: "Story Mode",
                callback: () -> FlxG.switchState(StoryMenuState.new),
            },
            {
                name: "freeplay",
                rpcName: "Freeplay",
                callback: () -> FlxG.switchState(FreeplayState.new),
            },
            {
                name: "credits",
                rpcName: "Credits",
                callback: () -> FlxG.switchState(CreditsState.new),
            },
            {
                name: "options",
                rpcName: "Options",
                callback: () -> FlxG.switchState(OptionsState.new.bind({exitState: null})),
            },
        ];
        call("onInitOptions", [options]);
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
        #if mobile
        bg.scrollFactor.set(0.17, 0.17);
        bg.scale.set(1.2, 1.2);
        #else
        bg.scrollFactor.set(0, Math.max(0.1, 0.25 - (0.05 * (options.length - 4))));
        bg.scale.set(1.175, 1.175);
        #end
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

        #if mobile
        gyroPan = new FlxPoint();
        #end
        final offset:Float = 108 - (Math.max(options.length, 4) - 4) * 80;
		final scr:Float = (options.length < 6) ? 0 : (options.length - 4) * 0.135;
        
        for(i => option in options) {
            final menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			
			menuItem.frames = Paths.getSparrowAtlas('menus/main/${option.name}');
			menuItem.animation.addByPrefix("idle", '${option.name} idle', 24);
			menuItem.animation.addByPrefix("selected", '${option.name} selected', 24);
			menuItem.animation.play("idle");

            #if mobile
			menuItem.scrollFactor.set(0.4, (scr > 0) ? 0.4 + scr : 0.4);
            #else
			menuItem.scrollFactor.set(0, scr);
            #end
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
            menuItem.ID = i;

			menuItems.add(menuItem);
            
            if(i == 1)
                camFollow.setPosition(menuItem.getGraphicMidpoint().x, menuItem.getGraphicMidpoint().y);
        }
        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);

        var versionString:String = 'Garfie Engine v${FlxG.stage.application.meta.get("version")}';
        #if DEV_BUILD
        versionString += ' (${GitCommitMacro.getBranch()}/${GitCommitMacro.getCommitHash()})';
        #end
        versionString += "\nFriday Night Funkin' v0.7.0";
        
        #if mobile
        versionString += '\nTap anywhere with 2 fingers to manage content packs';
        #else
        versionString += '\nPress ${InputFormatter.formatFlixel(Controls.getKeyFromInputType(controls.getCurrentMappings().get(Control.MANAGE_CONTENT)[0])).toUpperCase()} to manage content packs';
        #end
        versionText = new FlxText(5, FlxG.height - 2, 0, versionString);
		versionText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionText.scrollFactor.set();
        versionText.y -= versionText.height;
		add(versionText);
        
        FlxG.camera.follow(camFollow, LOCKON, 0.06);
        changeSelection(0, true);

        #if MOBILE_UI
        addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, goBack, 1.0);
        #end
        #if (FLX_MOUSE && !mobile)
        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;
        #end
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        #if mobile
        if(gyroPan != null && bg != null && !ControlsHandler.usingExternalInputDevice) {
            gyroPan.add(FlxG.gyroscope.pitch * -1.25, FlxG.gyroscope.roll * -1.25);

            // our pseudo damping
            gyroPan.x = MathUtil.smoothLerpPrecision(gyroPan.x, 0, elapsed, 2.5);
            gyroPan.y = MathUtil.smoothLerpPrecision(gyroPan.y, 0, elapsed, 2.5);

            // how far away from bg mid do we want to pan via gyroPan
            final add:Float = (menuItems.length > 4) ? (menuItems.length * 8) : 0;
            camFollow.x = bg.getGraphicMidpoint().x - gyroPan.x;
            camFollow.y = bg.getGraphicMidpoint().y - gyroPan.y - add;
        }
        #end
        if(!transitioning) {
            final wheel:Float = TouchUtil.wheel;

            // traditional desktop controls
            if(controls.justPressed.UI_UP || wheel < 0)
                changeSelection(-1);
    
            if(controls.justPressed.UI_DOWN || wheel > 0)
                changeSelection(1);
    
            if(controls.justPressed.ACCEPT)
                onSelect();

            // mobile controls (available with mouse on desktop too cuz why not)
            menuItems.forEach(_checkMenuButtonPresses);

            if(controls.justPressed.DEBUG) {
                persistentUpdate = false;
                transitioning = true;
                openSubState(new EditorPickerSubState());
            }
            final doubleTapped:Bool = FlxG.touches.list.length > 1;
            if(controls.justPressed.MANAGE_CONTENT || doubleTapped) {
                persistentUpdate = false;
                transitioning = true;
                FlxG.switchState(ContentPackState.new);
            }
        }
        if(controls.justPressed.BACK) {
            goBack();
            FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
        }
    }

    public function goBack():Void {
        persistentUpdate = false;
        transitioning = true;
        FlxG.switchState(TitleState.new);
    }

    public function updateDiscordRPC():Void {
        final option:MainMenuOption = options[curSelected];
        DiscordRPC.changePresence("Main Menu", '${option.rpcName ?? option.name}');
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;
        
        curSelected = FlxMath.wrap(curSelected + by, 0, options.length - 1);

        for(i => item in menuItems) {
            if(curSelected == i) {
                item.animation.play("selected");
                item.centerOffsets();
                
                #if !mobile
                final add:Float = (menuItems.length > 4) ? (menuItems.length * 8) : 0;
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y - add);
                #end
            }
            else {
                item.animation.play("idle");
                item.centerOffsets();
            }
        }
        updateDiscordRPC();
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
        #if MOBILE_UI
        if(backButton != null) {
            backButton.active = false;
            FlxTween.tween(backButton, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
        }
        #end
        transitioning = true;
        FlxG.sound.play(Paths.sound("menus/sfx/select"));
    }

    //----------- [ Private API ] -----------//

    private var magTwn:FlxTween = null;
    private var lastMouseVisible:Bool = true;

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

    private function _checkMenuButtonPresses(button:FlxSprite):Void {
        final pointer = TouchUtil.touch;
        if(TouchUtil.justPressed && pointer.overlaps(button, getDefaultCamera())) {
            if(curSelected != button.ID) {
                curSelected = button.ID;
                
                button.scale.set(0.94, 0.94);
                FlxTween.cancelTweensOf(button.scale);
                FlxTween.tween(button.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

                changeSelection(0, true);
                return;
            }
            button.scale.set(1.1, 1.1);
            FlxTween.cancelTweensOf(button.scale);
            FlxTween.tween(button.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

            onSelect();
        }
    }

    #if (FLX_MOUSE && !mobile)
    override function destroy():Void {
        FlxG.mouse.visible = lastMouseVisible;
        super.destroy();
    }
    #end
}

@:structInit
class MainMenuOption {
    public var name:String;

    @:optional
    public var rpcName:String;
    
    public var callback:Void->Void;

    @:optional
    public var fireImmediately:Bool = false;
}