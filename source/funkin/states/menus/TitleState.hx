package funkin.states.menus;

import flixel.util.FlxTimer;
import flixel.util.FlxDirectionFlags;

import funkin.ui.AtlasText;
import funkin.utilities.CustomShader;

class TitleState extends FunkinState {
    public static var initialized:Bool = false;

    public var curQuotes:Array<String>;

    public var introSequence:Map<Int, IntroStep>;
    public var introLength:Int;

    public var quoteText:AtlasText;
    public var ngSpr:FlxSprite;

    public var logoBl:FlxSprite;
    public var gfDance:FlxSprite;
    public var titleText:FlxSprite;

    public var titleGroup:FlxContainer;
    
    public var skippedIntro:Bool = false;
    public var transitioning:Bool = false;

    public var swagShader:CustomShader;

    public var curCheatPos:Int = 0;
    public var cheatActivated:Bool = false;
    public var cheatArray:Array<Int> = [0x0001, 0x0010, 0x0001, 0x0010, 0x0100, 0x1000, 0x0100, 0x1000];

    public function initQuotes():Void {
        curQuotes = CoolUtil.parseCSV(FlxG.assets.getText(Paths.csv("menus/title/quotes"))).pickRandom();
        introSequence = [
            1  => {lines: ["The", "Funkin Crew Inc"]},
            3  => {lines: ["The", "Funkin Crew Inc", "Presents"]},
            4  => {lines: []},
            5  => {lines: ["In association", "with"]},
            7  => {lines: ["In association", "with", "Newgrounds"], callback: showNewgrounds},
            8  => {lines: [], callback: hideNewgrounds},
            9  => {lines: [curQuotes.first()]},
            11 => {lines: curQuotes},
            12 => {lines: []},
            13 => {lines: ["Friday"]},
            14 => {lines: ["Friday", "Night"]},
            15 => {lines: ["Friday", "Night", "Funkin"]}
        ];
        introLength = 16;
    }

    public function showNewgrounds():Void {
        ngSpr.revive();
    }

    public function hideNewgrounds():Void {
        ngSpr.kill();
    }

    public function skipIntro():Void {
        hideNewgrounds();

        quoteText.kill();
        titleGroup.revive();

        skippedIntro = true;
        FlxG.camera.flash(FlxColor.WHITE, (initialized) ? 1 : 4);
    }
    
    override function create():Void {
        persistentUpdate = true;
        initQuotes();

        if(FlxG.sound.music == null || !FlxG.sound.music.playing)
            CoolUtil.playMenuMusic();

        Conductor.instance.music = FlxG.sound.music;
        
        quoteText = new AtlasText(0, 200, "bold", CENTER, "");
        add(quoteText);

        ngSpr = new FlxSprite(0, FlxG.height * 0.52);

        if(FlxG.random.bool(1))
            ngSpr.loadGraphic(Paths.image('menus/title/newgrounds_classic'));
        
        else if(FlxG.random.bool(30)) {
            ngSpr.loadGraphic(Paths.image('menus/title/newgrounds_animated'), true, 600);
            ngSpr.animation.add('idle', [0, 1], 4);
            ngSpr.animation.play('idle');
            ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.55));
            ngSpr.y += 25;
        }
        else {
            ngSpr.loadGraphic(Paths.image('menus/title/newgrounds'));
            ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
        }
        ngSpr.updateHitbox();
        ngSpr.screenCenter(X);
        ngSpr.kill();
        add(ngSpr);
        
        titleGroup = new FlxContainer();
        titleGroup.kill();
        add(titleGroup);

        swagShader = new CustomShader("hue_offset");
        swagShader.setFloat("OFFSET", 0);

        logoBl = new FlxSprite(-150, -100);
        logoBl.frames = Paths.getSparrowAtlas('menus/title/logo');
        logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
        logoBl.animation.play('bump');
        logoBl.shader = swagShader;
        titleGroup.add(logoBl);

        gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
        gfDance.frames = Paths.getSparrowAtlas('menus/title/gf');
        gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
        gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
        gfDance.animation.play('danceRight');
        gfDance.shader = swagShader;
        titleGroup.add(gfDance);

        titleText = new FlxSprite(100, FlxG.height * 0.8);
        titleText.frames = Paths.getSparrowAtlas('menus/title/enter');
        titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
        titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
        titleText.animation.play('idle');
        titleText.shader = swagShader;
        titleGroup.add(titleText);

        if(initialized)
            skipIntro();
        
        initialized = true;
        super.create();
    }
    
    override function update(elapsed:Float):Void {
        if(controls.pressed.UI_LEFT)
            swagShader.setFloat("OFFSET", swagShader.getFloat("OFFSET") + (elapsed * -0.1));

        if(controls.pressed.UI_RIGHT)
            swagShader.setFloat("OFFSET", swagShader.getFloat("OFFSET") + (elapsed * 0.1));

        if(controls.justPressed.ACCEPT) {
            if(!skippedIntro)
                skipIntro();
            
            else if(!transitioning) {
                transitioning = true;

                FlxG.camera.flash(FlxColor.WHITE, 1);
                FlxG.sound.play(Paths.sound("menus/sfx/select"));

                titleText.animation.play('press');
                FlxTimer.wait(2, () -> FlxG.switchState(new MainMenuState()));
            }
            else if(subState == null)
                FlxG.switchState(new MainMenuState());
        }
        if(!cheatActivated && FlxG.keys.justPressed.ANY) {
            if (controls.justPressed.NOTE_UP || controls.justPressed.UI_UP) cheatCodePress(FlxDirectionFlags.UP);
            if (controls.justPressed.NOTE_DOWN || controls.justPressed.UI_DOWN) cheatCodePress(FlxDirectionFlags.DOWN);
            if (controls.justPressed.NOTE_LEFT || controls.justPressed.UI_LEFT) cheatCodePress(FlxDirectionFlags.LEFT);
            if (controls.justPressed.NOTE_RIGHT || controls.justPressed.UI_RIGHT) cheatCodePress(FlxDirectionFlags.RIGHT);
        }
        super.update(elapsed);
    }

    override function beatHit(beat:Int) {
        if(!skippedIntro) {
            if(beat >= introLength)
                skipIntro();
            else {
                final step:IntroStep = introSequence.get(beat);
                if(step != null) {
                    quoteText.text = step.lines.join("\n");
                    quoteText.screenCenter(X);
    
                    if(step.callback != null)
                        step.callback();
                }
            }
        }
        logoBl.animation.play('bump', true);
        gfDance.animation.play((beat % 2 == 0) ? 'danceLeft' : 'danceRight', true);

        if(cheatActivated && beat % 2 == 0)
            swagShader.setFloat("OFFSET", swagShader.getFloat("OFFSET") + 0.125);
    }

    private function cheatCodePress(input:Int):Void {
        if(input == cheatArray[curCheatPos]) {
            curCheatPos++;
            if(curCheatPos >= cheatArray.length)
                startCheat();
        }
        else
            curCheatPos = 0;
    }

    private function startCheat():Void {
        if(cheatActivated)
            return;

        if(!FlxG.keys.pressed.SHIFT) {
            // hold shift to keep currently playing music, incase
            // you exit from freeplay and wanna listen to the (hopefully) fire music!!
            CoolUtil.playMusic("menus/music/girlfriendsRingtone");
            FlxG.signals.postStateSwitch.addOnce(() -> {
                CoolUtil.playMenuMusic();
                FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
            });
            FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
        }
        FlxG.sound.play(Paths.sound("menus/sfx/select"));
        FlxG.camera.flash(FlxColor.WHITE, 1);

        cheatActivated = true;
    }
}

@:structInit
class IntroStep {
    public var lines:Array<String>;

    @:optional
    public var callback:Void->Void;
}