package funkin.states.menus;

import flixel.util.FlxTimer;
import flixel.util.FlxDirectionFlags;

import funkin.backend.events.Events;
import funkin.backend.events.ActionEvent;

import funkin.ui.AtlasText;
import funkin.graphics.shader.CustomShader;

class TitleState extends FunkinState {
    public static var initialized:Bool = false;

    public var curQuotes:Array<String>;

    public var introSequence:Map<Int, IntroStep>;
    public var introLength:Int;

    public var quoteText:AtlasText;

    public var ngSpr:FlxSprite;
    public var allowNgEasterEggs:Bool = true;

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
    
    override function create():Void {
        super.create();
        DiscordRPC.changePresence("Title Screen", null);
        
        persistentUpdate = true;
        initQuotes();

        if(FlxG.sound.music == null || !FlxG.sound.music.playing)
            CoolUtil.playMenuMusic();

        FlxG.sound.music.looped = true;
        Conductor.instance.music = FlxG.sound.music;
        
        quoteText = new AtlasText(0, 200, "bold", CENTER, "");
        quoteText.fieldWidth = FlxG.width;
        add(quoteText);

        ngSpr = new FlxSprite(0, FlxG.height * 0.52);

        if(allowNgEasterEggs && FlxG.random.bool(1))
            ngSpr.loadGraphic(Paths.image('menus/title/newgrounds_classic'));
        
        else if(allowNgEasterEggs && FlxG.random.bool(30)) {
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

        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onTitleGroupCreation", [event]);

        if(!event.cancelled) {
            final cutoutSize:Float = #if mobile cast(FlxG.scaleMode, funkin.graphics.RatioScaleModeEx).width - Constants.GAME_WIDTH #else 0 #end;
    
            logoBl = new FlxSprite(-150 + (cutoutSize / 2.5), -100);
            logoBl.frames = Paths.getSparrowAtlas('menus/title/logo');
            logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
            logoBl.animation.play('bump');
            logoBl.shader = swagShader;
            titleGroup.add(logoBl);
    
            gfDance = new FlxSprite((FlxG.width * 0.4) + (cutoutSize / 2.5), FlxG.height * 0.07);
            gfDance.frames = Paths.getSparrowAtlas('menus/title/gf');
            gfDance.animation.addByIndices('danceLeft', 'gfDance', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
            gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30], "", 24, false);
            gfDance.animation.play('danceRight');
            gfDance.shader = swagShader;
            titleGroup.add(gfDance);
    
            titleText = new FlxSprite(#if MOBILE_UI 50 #else 100 #end + (cutoutSize / 2), FlxG.height * 0.8);
            titleText.frames = Paths.getSparrowAtlas(#if MOBILE_UI 'menus/title/enter_mobile' #else 'menus/title/enter' #end);
            titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
            titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
            titleText.animation.play('idle');
            titleText.shader = swagShader;
            titleGroup.add(titleText);

            if(FlxG.random.bool(10)) {
                titleText.frames = Paths.getSparrowAtlas(#if MOBILE_UI 'menus/title/enter_mobile_funny' #else 'menus/title/enter_funny' #end);
                titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
                titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
                titleText.animation.play('idle');
                titleText.scale.set(#if MOBILE_UI 1.32 #else 1.5 #end, 1.32);
                titleText.updateHitbox();
                titleText.y -= 40;
            }
            call("onTitleGroupCreationPost", [event.flagAsPost()]);
        }
        if(initialized)
            skipIntro();

        #if mobile
        FlxG.touches.swipeThreshold.x = 100;
        FlxG.touches.swipeThreshold.y = 100;
        #end
    }
    
    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if(controls.pressed.UI_LEFT)
            swagShader.setFloat("OFFSET", swagShader.getFloat("OFFSET") + (elapsed * -0.1));

        if(controls.pressed.UI_RIGHT)
            swagShader.setFloat("OFFSET", swagShader.getFloat("OFFSET") + (elapsed * 0.1));

        #if MOBILE_UI
        final accept:Bool = controls.justPressed.ACCEPT || TouchUtil.justPressed;
        #else
        final accept:Bool = controls.justPressed.ACCEPT;
        #end
        if(accept) {
            if(!skippedIntro)
                skipIntro();
            
            else if(!transitioning) {
                transitioning = true;

                final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
                call("onTransitionToMenu", [event]);
                
                if(!event.cancelled) {
                    FlxG.camera.flash(FlxColor.WHITE, 1);
                    FlxG.sound.play(Paths.sound("menus/sfx/select"));
                    
                    if(titleText != null)
                        titleText.animation.play('press');
                    
                    FlxTimer.wait(2, () -> switchToMenu());
                    call("onTransitionToMenuPost", [event.flagAsPost()]);
                }
            }
            else if(subState == null)
                switchToMenu();
        }
        if(!cheatActivated && FlxG.keys.justPressed.ANY) {
            if (controls.justPressed.NOTE_UP || controls.justPressed.UI_UP) cheatCodePress(FlxDirectionFlags.UP);
            if (controls.justPressed.NOTE_DOWN || controls.justPressed.UI_DOWN) cheatCodePress(FlxDirectionFlags.DOWN);
            if (controls.justPressed.NOTE_LEFT || controls.justPressed.UI_LEFT) cheatCodePress(FlxDirectionFlags.LEFT);
            if (controls.justPressed.NOTE_RIGHT || controls.justPressed.UI_RIGHT) cheatCodePress(FlxDirectionFlags.RIGHT);
        }
    }

    public function showNewgrounds():Void {
        ngSpr.revive();
    }

    public function hideNewgrounds():Void {
        ngSpr.kill();
    }

    public function skipIntro():Void {
        initialized = true;

        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onSkipIntro", [event]);
        
        if(event.cancelled)
            return;

        skippedIntro = true;
        hideNewgrounds();

        quoteText.kill();
        titleGroup.revive();
        
        FlxG.camera.flash(FlxColor.WHITE, (initialized) ? 1 : 4);
        call("onSkipIntroPost", [event.flagAsPost()]);
    }

    public function switchToMenu():Void {
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onSwitchToMenu", [event]);
        
        if(!event.cancelled) {
            FlxG.switchState(MainMenuState.new);
            call("onSwitchToMenuPost", [event.flagAsPost()]);
        }
    }

    override function beatHit(beat:Int):Void {
        if(!skippedIntro) {
            if(beat >= introLength)
                skipIntro();
            else {
                final step:IntroStep = introSequence.get(beat);
                if(step != null) {
                    quoteText.text = step.lines.join("\n");
                    if(step.callback != null)
                        step.callback();
                }
            }
        }
        if(logoBl != null)
            logoBl.animation.play('bump', true);
        
        if(gfDance != null)
            gfDance.animation.play((beat % 2 == 0) ? 'danceLeft' : 'danceRight', true);
        
        if(cheatActivated && beat % 2 == 0)
            swagShader.setFloat("OFFSET", swagShader.getFloat("OFFSET") + 0.125);

        super.beatHit(beat);
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
        
        final event:ActionEvent = Events.get(UNKNOWN).recycleBase();
        call("onStartCheat", [event]);
        
        if(event.cancelled)
            return;

        cheatActivated = true;

        if(!FlxG.keys.pressed.SHIFT) {
            // hold shift to keep currently playing music, incase
            // you exit from freeplay and wanna listen to the (hopefully) fire music!!
            CoolUtil.playMusic("menus/music/girlfriendsRingtone");

            if(Constants.PLAY_MENU_MUSIC_AFTER_EXIT) {
                FlxG.signals.postStateSwitch.addOnce(() -> {
                    CoolUtil.playMenuMusic(0.0);
                    FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
                });
                FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
            }
        }
        FlxG.sound.play(Paths.sound("menus/sfx/select"));
        FlxG.camera.flash(FlxColor.WHITE, 1);

        call("onStartCheatPost", [event.flagAsPost()]);
    }
}

@:structInit
class IntroStep {
    public var lines:Array<String>;

    @:optional
    public var callback:Void->Void;
}