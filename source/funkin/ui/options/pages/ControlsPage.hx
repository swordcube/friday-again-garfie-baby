package funkin.ui.options.pages;

import flixel.util.FlxTimer;
import flixel.effects.FlxFlicker;

import flixel.addons.input.FlxControls;
import flixel.input.gamepad.FlxGamepadInputID;

import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;

import funkin.ui.Prompt;
import funkin.ui.AtlasText;
import funkin.utilities.InputFormatter;

import funkin.states.FunkinState;
import funkin.mobile.input.ControlsHandler;

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
                    name: "Debug Overlay",
                    control: Control.DEBUG_OVERLAY
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

    public var deviceListBG:FlxSprite;
    public var deviceList:AtlasTextList;

    public var deviceListSelected:Bool = false;
    public var gamepadSelected:Bool = false;

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

        if(FlxG.gamepads.numActiveGamepads != 0) {
            deviceListBG = new FlxSprite().makeSolid(FlxG.width, 100, 0xFFFAFD6D);
            add(deviceListBG);

            deviceList = new AtlasTextList(HORIZONTAL);
            add(deviceList);
            
            var item:AtlasText = null;
            item = deviceList.addItem("Keyboard", {
                onSelect: (_, _) -> {
                    gamepadSelected = false;
                    refreshKeyboardBinds();
                },
                onAccept: (_, _) -> {
                    FlxTimer.wait(0.001, () -> {
                        deviceListSelected = deviceList.enabled = false;
                    });
                }
            });
            item.setPosition((FlxG.width * 0.5) - (item.width + 30), (deviceListBG.height - item.height) * 0.5);

            item = deviceList.addItem("Gamepad", {
                onSelect: (_, _) -> {
                    gamepadSelected = true;
                    refreshGamepadBinds();
                },
                onAccept: (_, _) -> {
                    FlxTimer.wait(0.001, () -> {
                        deviceListSelected = deviceList.enabled = false;
                    });
                }
            });
            item.setPosition((FlxG.width * 0.5) + 30, (deviceListBG.height - item.height) * 0.5);

            deviceListSelected = true;
            deviceList.changeSelection(0, true);
        }
        bindCategories[bindCategories.length - 1].binds.push({
            name: "Reset to Default Keys",
            control: null
        });
        var y:Int = 0;
        var yOffset:Float = (deviceListBG != null) ? 120 : 30;

        for(category in bindCategories) {
            final categoryName:AtlasText = new AtlasText(0, (70 * y++) + yOffset, "bold", LEFT, category.name);
            categoryName.screenCenter(X);
            grpText.add(categoryName);

            for(bind in category.binds) {
                if(bind.control != null) {
                    final bindName:AtlasText = new AtlasText(50, (70 * y) + yOffset, "bold", LEFT, bind.name);
                    bindNames.push(bindName);  
                    grpText.add(bindName);
    
                    final firstBind:AtlasText = new AtlasText(FlxG.width - 530, ((70 * y) + yOffset) - 40, "default", LEFT, InputFormatter.formatFlixelKey(Controls.getKeyFromInputType(curMappings.get(bind.control)[0])));
                    firstBind.color = FlxColor.BLACK;
                    grpText.add(firstBind);
    
                    final secondBind:AtlasText = new AtlasText(firstBind.x + 300, ((70 * y) + yOffset) - 40, "default", LEFT, InputFormatter.formatFlixelKey(Controls.getKeyFromInputType(curMappings.get(bind.control)[1])));
                    secondBind.color = FlxColor.BLACK;
                    grpText.add(secondBind);
    
                    controlItems.push(bind.control);
                    bindTexts.push([firstBind, secondBind]);
                } else {
                    y++;
                    final bindName:AtlasText = new AtlasText(50, (70 * y) + yOffset, "bold", LEFT, bind.name);
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
        
        #if MOBILE_UI
        final state:FunkinState = cast FlxG.state;
        state.addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, goBack, 1, true);
        #end
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if(deviceListBG != null) {
            if(!deviceListSelected && controls.justPressed.BACK)
                deviceListSelected = deviceList.enabled = true;
    
            if(deviceListSelected && controls.justPressed.BACK) {
                goBack();
                FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            }
        }
        if(deviceListSelected || openedPrompt)
            return;

        if(!changingBind) {
            final wheel:Float = TouchUtil.wheel;
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
            
            if(controls.justPressed.BACK && deviceListBG == null) {
                goBack();
                FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            }
        } else {
            var pressedKey:Bool = (gamepadSelected) ? ((FlxG.gamepads.lastActive != null) ? FlxG.gamepads.lastActive.justPressed.ANY : false) : FlxG.keys.justPressed.ANY;
            var pressedAnyEscapeKey:Bool = FlxG.keys.justPressed.BACKSPACE || FlxG.keys.justPressed.ESCAPE;

            if(changingBind && !pressedKeyYet && (pressedKey || pressedAnyEscapeKey)) {
                pressedKeyYet = true;

                bindPrompt.exists = false;
                stopChangingBind();
            }
        }
    }

    public function goBack():Void {
        controls.flush();
        menu.loadPage(new MainPage());
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
                    if(gamepadSelected) {
                        final newGamepadInput:FlxGamepadInputID = Controls.getGamepadInputFromInputType(defaultMappings.get(controlItems[i])[j + 2]);
                        bindTexts[i][j].text = InputFormatter.formatFlixelGamepadInput(newGamepadInput);
                    } else {
                        final newKey:FlxKey = Controls.getKeyFromInputType(defaultMappings.get(controlItems[i])[j]);
                        bindTexts[i][j].text = InputFormatter.formatFlixelKey(newKey);
                    }
                }
            }
            FlxTimer.wait(0.15, () -> {
                final defaultMappings:ActionMap<Control> = controls.getDefaultMappings();
                openedPrompt = false;
                for(c in controlItems) {
                    if(c == null)
                        continue;
    
                    for(i in 0...2) {
                        final newKey:FlxKey = Controls.getKeyFromInputType(defaultMappings.get(c)[i]);
                        final newGamepadInput:FlxGamepadInputID = Controls.getGamepadInputFromInputType(defaultMappings.get(c)[i + 2]);
                        
                        controls.bindKey(c, i, newKey);
                        controls.bindGamepadInput(c, i, newGamepadInput);

                        controls.apply();
                    }
                }
            });
            curMappings = controls.getCurrentMappings();
    
            resetPrompt.closePrompt();
            FlxG.sound.play(Paths.sound("menus/sfx/select"));
        };
        resetPrompt.onNo = () -> {
            FlxTimer.wait(0.15, () -> {
                openedPrompt = false;
            });
            resetPrompt.closePrompt();
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
            final newGamepadInput:FlxGamepadInputID = Controls.getGamepadInputFromInputType(defaultMappings.get(controlItems[curSelected])[curBindIndex + 2]);
            
            final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
            bindText.text = (gamepadSelected) ? InputFormatter.formatFlixelGamepadInput(newGamepadInput) : InputFormatter.formatFlixelKey(newKey);
            
            FlxTimer.wait(0.15, () -> {
                openedPrompt = false;

                if(gamepadSelected)
                    controls.bindGamepadInput(controlItems[curSelected], curBindIndex, newGamepadInput);
                else
                    controls.bindKey(controlItems[curSelected], curBindIndex, newKey);
                
                controls.apply();
            });
            final offset:Int = (gamepadSelected) ? 2 : 0;
            curMappings.get(controlItems[curSelected])[curBindIndex + offset] = (gamepadSelected) ? newGamepadInput : newKey;

            resetPrompt.closePrompt();
            FlxG.sound.play(Paths.sound("menus/sfx/select"));
        };
        resetPrompt.onNo = () -> {
            FlxTimer.wait(0.15, () -> {
                openedPrompt = false;
            });
            resetPrompt.closePrompt();
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
        var newKey:FlxKey = FlxG.keys.firstJustPressed();
        var newGamepadInput:FlxGamepadInputID = FlxG.gamepads.lastActive?.firstJustPressedID() ?? NONE;
        
        switch(newKey) {
            case NONE:
                if(newGamepadInput == NONE)
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
        final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
        FlxFlicker.stopFlickering(bindText);

        bindText.text = (gamepadSelected) ? InputFormatter.formatFlixelGamepadInput(newGamepadInput) : InputFormatter.formatFlixelKey(newKey);
        bindText.visible = true;

        if(gamepadSelected)
            controls.bindGamepadInput(controlItems[curSelected], curBindIndex, newGamepadInput);
        else
            controls.bindKey(controlItems[curSelected], curBindIndex, newKey);
        
        controls.apply();

        final offset:Int = (gamepadSelected) ? 2 : 0;
        curMappings.get(controlItems[curSelected])[curBindIndex + offset] = (gamepadSelected) ? newGamepadInput : newKey;

        FlxTimer.wait(0.15, () -> {
            changingBind = false;
            pressedKeyYet = false;
        });
    }

    public function refreshKeyboardBinds():Void {
        final currentMappings:ActionMap<Control> = controls.getCurrentMappings();
        for(i => fuck in bindTexts) {
            if(fuck == null)
                continue;
            
            for(j in 0...fuck.length) {
                final newKey:FlxKey = Controls.getKeyFromInputType(currentMappings.get(controlItems[i])[j]);
                bindTexts[i][j].text = InputFormatter.formatFlixelKey(newKey);
            }
        }
    }

    public function refreshGamepadBinds():Void {
        final currentMappings:ActionMap<Control> = controls.getCurrentMappings();
        for(i => fuck in bindTexts) {
            if(fuck == null)
                continue;
            
            for(j in 0...fuck.length) {
                final newInputID:FlxGamepadInputID = Controls.getGamepadInputFromInputType(currentMappings.get(controlItems[i])[j + 2]);
                bindTexts[i][j].text = InputFormatter.formatFlixelGamepadInput(newInputID);
            }
        }
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