package funkin.ui.options.pages;

import flixel.util.FlxTimer;
import flixel.effects.FlxFlicker;
import flixel.addons.input.FlxControls;

import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;

import funkin.ui.Prompt;
import funkin.ui.AtlasText;
import funkin.utilities.InputFormatter;

class ControlsPage extends Page {
    public var bindCategories:Array<BindCategory> = [
        {
            name: "Notes",
            binds: [
                {
                    name: "Left",
                    control: Control.NOTE_LEFT
                },
                {
                    name: "Down",
                    control: Control.NOTE_DOWN
                },
                {
                    name: "Up",
                    control: Control.NOTE_UP
                },
                {
                    name: "Right",
                    control: Control.NOTE_RIGHT
                }
            ]
        },
        {
            name: "UI",
            binds: [
                {
                    name: "Left",
                    control: Control.UI_LEFT
                },
                {
                    name: "Down",
                    control: Control.UI_DOWN
                },
                {
                    name: "Up",
                    control: Control.UI_UP
                },
                {
                    name: "Right",
                    control: Control.UI_RIGHT
                },
                {
                    name: "Reset",
                    control: Control.RESET
                },
                {
                    name: "Accept",
                    control: Control.ACCEPT
                },
                {
                    name: "Back",
                    control: Control.BACK
                },
                {
                    name: "Pause",
                    control: Control.PAUSE
                }
            ]
        },
        {
            name: "Window",
            binds: [
                {
                    name: "Screenshot",
                    control: Control.SCREENSHOT
                },
                {
                    name: "Fullscreen",
                    control: Control.FULLSCREEN
                }
            ]
        },
        {
            name: "Volume",
            binds: [
                {
                    name: "Up",
                    control: Control.VOLUME_UP
                },
                {
                    name: "Down",
                    control: Control.VOLUME_DOWN
                },
                {
                    name: "Mute",
                    control: Control.VOLUME_MUTE
                }
            ]
        },
        {
            name: "Debug",
            binds: [
                {
                    name: "Reload State",
                    control: Control.DEBUG_RELOAD
                },
                {
                    name: "Debug Menu",
                    control: Control.DEBUG
                },
                {
                    name: "Emergency",
                    control: Control.EMERGENCY
                },
                {
                    name: "Manage Content",
                    control: Control.MANAGE_CONTENT
                }
            ]
        }
    ];
    public var curBindIndex:Int = 0;
    public var curMappings:ActionMap<Control>;
    
    public var curSelected:Int = 0;
    public var grpText:FlxTypedContainer<AtlasText>;

    public var bindNames:Array<AtlasText> = [];
    public var bindTexts:Array<Array<AtlasText>> = [];

    public var promptCam:FlxCamera;
    public var camFollow:FlxObject;

    public var controlItems:Array<Control> = [];
    public var changingBind:Bool = false;
    
    public var bindPrompt:Prompt;
    public var openedPrompt:Bool = false;

    public var pressedKeyYet:Bool = false;

    override function create():Void {
        super.create();
        curMappings = controls.getCurrentMappings();

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        promptCam = new FlxCamera();
        promptCam.bgColor = 0;
        FlxG.cameras.add(promptCam, false);

        grpText = new FlxTypedContainer<AtlasText>();
        add(grpText);

        bindCategories[bindCategories.length - 1].binds.push({
            name: "Reset to Default Keys",
            control: null
        });
        var y:Int = 0;
        for(category in bindCategories) {
            final categoryName:AtlasText = new AtlasText(0, (70 * y++) + 30, "bold", LEFT, category.name);
            categoryName.screenCenter(X);
            grpText.add(categoryName);

            for(bind in category.binds) {
                if(bind.control != null) {
                    final bindName:AtlasText = new AtlasText(50, (70 * y) + 30, "bold", LEFT, bind.name);
                    bindNames.push(bindName);  
                    grpText.add(bindName);
    
                    final firstBind:AtlasText = new AtlasText(FlxG.width - 530, ((70 * y) + 30) - 40, "default", LEFT, InputFormatter.formatFlixel(Controls.getKeyFromInputType(curMappings.get(bind.control)[0])));
                    firstBind.color = FlxColor.BLACK;
                    grpText.add(firstBind);
    
                    final secondBind:AtlasText = new AtlasText(firstBind.x + 300, ((70 * y) + 30) - 40, "default", LEFT, InputFormatter.formatFlixel(Controls.getKeyFromInputType(curMappings.get(bind.control)[1])));
                    secondBind.color = FlxColor.BLACK;
                    grpText.add(secondBind);
    
                    controlItems.push(bind.control);
                    bindTexts.push([firstBind, secondBind]);
                } else {
                    y++;
                    final bindName:AtlasText = new AtlasText(50, (70 * y) + 30, "bold", LEFT, bind.name);
                    bindNames.push(bindName);  
                    grpText.add(bindName);

                    controlItems.push(null);
                    bindTexts.push(null);
                }
                y++;
            }
        }
        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);

        bindPrompt = new Prompt("\nPress any key to rebind\n\n\nBackspace to unbind\nEscape to cancel", None);
        bindPrompt.create();
        bindPrompt.createBGFromMargin(100, 0xFFfafd6d);
        bindPrompt.cameras = [promptCam];
        bindPrompt.exists = false;
        add(bindPrompt);
        
        final margin:Float = 100;
        camera.follow(camFollow, LOCKON, 0.16);
        camera.deadzone.set(0, margin, camera.width, camera.height - margin * 2);
        camera.minScrollY = 0;
        
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if(openedPrompt)
            return;

        if(!changingBind) {
            final wheel:Float = -FlxG.mouse.wheel;
            if(controls.justPressed.UI_UP || wheel < 0)
                changeSelection(-1);
    
            if(controls.justPressed.UI_DOWN || wheel > 0)
                changeSelection(1);
    
            if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT) {
                curBindIndex = (curBindIndex + 1) % 2;
                changeSelection(0, true);
            }
            if(controls.justPressed.ACCEPT) {
                if(curSelected >= bindTexts.length - 1)
                    resetAllBinds();
                else {
                    bindPrompt.exists = true;
                    startChangingBind();
                }
            }
            if(controls.justPressed.RESET)
                resetSpecificBind();
            
            if(controls.justPressed.BACK) {
                controls.flush();
                menu.loadPage(new MainPage());
                FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            }
        } else {
            if(changingBind && !pressedKeyYet && FlxG.keys.justPressed.ANY)
                pressedKeyYet = true;
            
            if(changingBind && pressedKeyYet && FlxG.keys.justReleased.ANY) {
                bindPrompt.exists = false;
                stopChangingBind();
            }
        }
    }

    function resetAllBinds() {
        final resetPrompt:Prompt = new Prompt("\nAre you sure you want\nto reset all binds?", YesNo);
        resetPrompt.create();
        resetPrompt.createBGFromMargin(100, 0xFFfafd6d);
        resetPrompt.onYes = () -> {
            final defaultMappings:ActionMap<Control> = controls.getDefaultMappings();
            for(i => fuck in bindTexts) {
                if(fuck == null)
                    continue;
                
                for(j in 0...fuck.length) {
                    final newKey:FlxKey = Controls.getKeyFromInputType(defaultMappings.get(controlItems[i])[j]);
                    bindTexts[i][j].text = InputFormatter.formatFlixel(newKey);
                }
            }
            FlxTimer.wait(0.001, () -> {
                final defaultMappings:ActionMap<Control> = controls.getDefaultMappings();
                openedPrompt = false;
                for(c in controlItems) {
                    if(c == null)
                        continue;
    
                    for(i in 0...2) {
                        final newKey:FlxKey = Controls.getKeyFromInputType(defaultMappings.get(c)[i]);
                        controls.bindKey(c, i, newKey);
                        controls.apply();
                    }
                }
            });
            curMappings = controls.getCurrentMappings();
    
            resetPrompt.closePrompt();
            FlxG.sound.play(Paths.sound("menus/sfx/select"));
        };
        resetPrompt.onNo = () -> {
            FlxTimer.wait(0.001, () -> {
                openedPrompt = false;
                resetPrompt.closePrompt();
            });
        };
        resetPrompt.cameras = [promptCam];
        add(resetPrompt);
    
        openedPrompt = true;
    }

    public function resetSpecificBind():Void {
        final resetPrompt:Prompt = new Prompt("\nAre you sure you want\nto reset this bind?", YesNo);
        resetPrompt.create();
        resetPrompt.createBGFromMargin(100, 0xFFfafd6d);
        resetPrompt.onYes = () -> {
            final defaultMappings:ActionMap<Control> = controls.getDefaultMappings();
            final newKey:FlxKey = Controls.getKeyFromInputType(defaultMappings.get(controlItems[curSelected])[curBindIndex]);
            
            final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
            bindText.text = InputFormatter.formatFlixel(newKey);
            
            FlxTimer.wait(0.001, () -> {
                openedPrompt = false;
                controls.bindKey(controlItems[curSelected], curBindIndex, newKey);
                controls.apply();
            });
            curMappings.get(controlItems[curSelected])[curBindIndex] = newKey;

            resetPrompt.closePrompt();
            FlxG.sound.play(Paths.sound("menus/sfx/select"));
        };
        resetPrompt.onNo = () -> {
            FlxTimer.wait(0.001, () -> {
                openedPrompt = false;
                resetPrompt.closePrompt();
            });
        };
        resetPrompt.cameras = [promptCam];
        add(resetPrompt);

        openedPrompt = true;
    }

    public function startChangingBind():Void {
        changingBind = true;
        FlxG.sound.play(Paths.sound("menus/sfx/select"));

        final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
        if(Options.flashingLights)
            FlxFlicker.flicker(bindText, 0, 0.06, true, false);
        else
            bindText.visible = false;
    }

    public function stopChangingBind():Void {
        var newKey:FlxKey = FlxG.keys.firstJustReleased();
        switch(newKey) {
            case NONE:
                return;

            case BACKSPACE:
                newKey = NONE;

            case ESCAPE:
                changingBind = false;
                pressedKeyYet = false;

                final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
                bindText.visible = true;
                FlxFlicker.stopFlickering(bindText);

                return;

            default:
        }
        changingBind = false;
        pressedKeyYet = false;

        final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
        FlxFlicker.stopFlickering(bindText);

        bindText.text = InputFormatter.formatFlixel(newKey);
        bindText.visible = true;
        
        FlxTimer.wait(0.001, () -> {
            controls.bindKey(controlItems[curSelected], curBindIndex, newKey);
            controls.apply();
        });
        curMappings.get(controlItems[curSelected])[curBindIndex] = newKey;
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = FlxMath.wrap(curSelected + by, 0, bindNames.length - 1);

        for(i => item in bindNames) {
            if(curSelected == i)
                item.alpha = 1;
            else
                item.alpha = 0.6;

            if(bindTexts[i] != null) {
                for(j => item2 in bindTexts[i]) {
                    if(curSelected == i && curBindIndex == j)
                        item2.alpha = 1;
                    else
                        item2.alpha = 0.6;
                }
            }
        }
        camFollow.y = bindNames[curSelected].y;
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    override function destroy():Void {
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}

typedef BindCategory = {
    var name:String;
    var binds:Array<Bind>;
}

typedef Bind = {
    var name:String;
    var control:Control;
}