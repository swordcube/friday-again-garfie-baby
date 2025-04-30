package funkin.states.menus.options;

import flixel.effects.FlxFlicker;
import flixel.addons.input.FlxControls;

import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;

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

    public var camFollow:FlxObject;
    public var warningText:FlxText;

    public var controlItems:Array<Control> = [];
    public var changingBind:Bool = false;

    override function create():Void {
        super.create();
        curMappings = controls.getCurrentMappings();

        camera = new FlxCamera();
        camera.bgColor = 0;
        FlxG.cameras.add(camera, false);

        grpText = new FlxTypedContainer<AtlasText>();
        add(grpText);

        var y:Int = 0;
        for(category in bindCategories) {
            final categoryName:AtlasText = new AtlasText(0, (70 * y++) + 30, "bold", LEFT, category.name);
            categoryName.screenCenter(X);
            grpText.add(categoryName);

            for(bind in category.binds) {
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
                y++;
            }
        }
        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);

        warningText = new FlxText(0, FlxG.height - 10, 0, "Waiting for input...");
        warningText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        warningText.screenCenter(X);
        warningText.y -= warningText.height;
        warningText.visible = false;
        add(warningText);
        
        final margin:Float = 100;
        camera.follow(camFollow, LOCKON, 0.16);
        camera.deadzone.set(0, margin, camera.width, camera.height - margin * 2);
        camera.minScrollY = 0;
        
        changeSelection(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if(!changingBind) {
            if(controls.justPressed.UI_UP)
                changeSelection(-1);
    
            if(controls.justPressed.UI_DOWN)
                changeSelection(1);
    
            if(controls.justPressed.UI_LEFT || controls.justPressed.UI_RIGHT) {
                curBindIndex = (curBindIndex + 1) % 2;
                changeSelection(0, true);
            }
            if(controls.justPressed.ACCEPT)
                startChangingBind();
    
            if(controls.justPressed.BACK) {
                controls.flush();
                menu.loadPage(new MainPage());
                FlxG.sound.play(Paths.sound("menus/sfx/cancel"));
            }
        } else {
            if(FlxG.keys.justPressed.ANY)
                stopChangingBind();
        }
    }

    public function startChangingBind():Void {
        changingBind = true;
        FlxG.sound.play(Paths.sound("menus/sfx/select"));

        final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
        warningText.visible = true;
        warningText.text = "Waiting for input...";

        if(Options.flashingLights)
            FlxFlicker.flicker(bindText, 0, 0.06, true, false);
        else
            bindText.visible = false;
    }

    public function stopChangingBind():Void {
        final newKey:FlxKey = FlxG.keys.firstJustPressed();
        if(newKey == NONE)
            return;

        changingBind = false;

        final bindText:AtlasText = bindTexts[curSelected][curBindIndex];
        warningText.visible = false;

        FlxFlicker.stopFlickering(bindText);
        bindText.text = InputFormatter.formatFlixel(newKey);
        bindText.visible = true;

        curMappings.get(controlItems[curSelected])[curBindIndex] = newKey;

        controls.bind(controlItems[curSelected], curBindIndex, newKey);
        controls.apply();
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

            for(j => item2 in bindTexts[i]) {
                if(curSelected == i && curBindIndex == j)
                    item2.alpha = 1;
                else
                    item2.alpha = 0.6;
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