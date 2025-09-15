package funkin.scripting;

#if SCRIPTING_ALLOWED
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.states.PlayState;
import haxe.io.Path;

class FunkinScript {
    public static var staticVariables(default, null):Map<String, Dynamic> = [];

    public var code(default, null):String = null;
    public var filePath(default, null):String = null;
    public var fileName(default, null):String = null;
    public var unsafe(default, null):Bool = false;

    public var closed(default, null):Bool = false;
    public var onClose(default, null):FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public function new(code:String, unsafe:Bool = false) {
        this.code = code; // I'M A DUMBASS HOW DID I FORGET THIS PART?!!?!
        this.unsafe = unsafe;
        preset();
    }

    public static function fromFile(filePath:String, unsafe:Bool = false):FunkinScript {
        switch(Path.extension(filePath).toLowerCase()) {
            case "hx", "hxs", "hsc", "hscript":
                return new FunkinHScript(filePath, unsafe);

            case "lua":
                return new FunkinLua(filePath, unsafe);
        }
        return new FunkinScript(filePath, unsafe);
    }

    public function preset():Void {
        set("Json", {
            parse: Json.parse,
            stringify: Json.stringify
        });
        setClass(Type);
        setClass(FlxG);

        setClass(FlxBasic);
        setClass(FlxObject);

        setClass(FlxSprite);
        setClass(FlxCamera);
        
        setClass(flixel.text.FlxText);
        setClass(flixel.text.FlxText.FlxTextFormat);

        setClass(FlxState);
        setClass(FlxSubState);

        setClass(FlxTypedGroup);
        set("FlxGroup", FlxTypedGroup);
        setClass(FlxTypedSpriteGroup);
        set("FlxSpriteGroup", FlxTypedSpriteGroup);

        setClass(FlxMath);
        setClass(FlxEase);
        setClass(FlxTween);
        set("FlxPoint", flixel.math.FlxPoint.FlxBasePoint);
        setClass(flixel.math.FlxRect);
        setClass(flixel.util.FlxTimer);
        setClass(flixel.util.FlxStringUtil);

        setClass(flixel.ui.FlxBar);
        setClass(flixel.addons.display.FlxBackdrop);
        setClass(flixel.addons.display.FlxTiledSprite);

        setClass(flixel.effects.FlxFlicker);
        setClass(flixel.graphics.atlas.FlxAtlas);

        setClass(Paths);
        setClass(Cache);
        setClass(Logs);
        setClass(Options);
        
        setClass(Controls);
        set("Control", funkin.backend.Controls.Control);

        setClass(CoolUtil);
        setClass(Conductor);
        setClass(GlobalScript);
        setClass(Constants);
        setClass(DiscordRPC);
        setClass(WindowUtil); // this util only lets you change the title

        setClass(FunkinHScript);
        setClass(FunkinLua);

        setClass(funkin.gameplay.HealthIcon);
        setClass(funkin.gameplay.PlayerStats);
        setClass(funkin.gameplay.PlayField);
        setClass(funkin.gameplay.UISkin);
        
        setClass(funkin.graphics.FunkinSprite);
        setClass(funkin.graphics.SkinnableSprite);
        setClass(funkin.graphics.TiledSprite);
        
        setClass(funkin.gameplay.hud.BaseHUD);
        
        setClass(funkin.gameplay.notes.Strum);
        setClass(funkin.gameplay.notes.StrumLine);
        
        setClass(funkin.gameplay.notes.Note);
        setClass(funkin.gameplay.notes.NoteSkin);
        setClass(funkin.gameplay.notes.NoteSpawner);
        
        setClass(funkin.gameplay.notes.HoldTail);
        setClass(funkin.gameplay.notes.HoldTrail);
        setClass(funkin.gameplay.notes.HoldTiledSprite);
        
        setClass(funkin.gameplay.song.ChartData);
        setClass(funkin.gameplay.song.NoteData);
        setClass(funkin.gameplay.song.EventData);
        setClass(funkin.gameplay.song.Highscore);
        setClass(funkin.gameplay.song.SongMetadata);
        setClass(funkin.gameplay.song.VocalGroup);

        setClass(funkin.gameplay.character.Character);
        setClass(funkin.gameplay.character.CharacterData);

        setClass(funkin.gameplay.scoring.Scoring);
        setClass(funkin.gameplay.scoring.ScoringSystem);

        setClass(funkin.gameplay.scoring.system.PBotSystem, "PBotScoringSystem");
        setClass(funkin.gameplay.scoring.system.Judge4System, "Judge4ScoringSystem");
        setClass(funkin.gameplay.scoring.system.PsychSystem, "PsychScoringSystem");

        setClass(funkin.gameplay.cutscenes.Cutscene);
        setClass(funkin.gameplay.cutscenes.ScriptedCutscene);
        setClass(funkin.gameplay.cutscenes.ScriptedSongCutscene);
        #if VIDEOS_ALLOWED
        setClass(funkin.gameplay.cutscenes.VideoCutscene);
        #end
        setClass(funkin.gameplay.cutscenes.Timeline);
        setClass(funkin.gameplay.cutscenes.Timeline.TimelineAction);
        setClass(funkin.gameplay.cutscenes.Timeline.CallbackAction);

        setClass(funkin.graphics.TiledSprite);
        setClass(funkin.graphics.GraphicCacheSprite);

        setClass(funkin.graphics.SkinnableSprite);
        setClass(funkin.graphics.SkinnableUISprite);

        setClass(funkin.graphics.TrackingSprite);
        #if VIDEOS_ALLOWED
        setClass(funkin.graphics.VideoSprite);
        #end
        set("FlxRuntimeShader", funkin.graphics.shader.RuntimeShader);
        setClass(funkin.graphics.shader.RuntimeShader);
        setClass(funkin.graphics.shader.CustomShader);

        setClass(funkin.states.PlayState);
        setClass(funkin.states.FunkinState);
        setClass(funkin.states.LoadingState);

        setClass(funkin.states.ScriptedState);
        setClass(funkin.states.ScriptedUIState);
        setClass(funkin.states.TransitionableState);

        setClass(funkin.states.menus.TitleState);
        setClass(funkin.states.menus.MainMenuState);
        setClass(funkin.states.menus.StoryMenuState);
        setClass(funkin.states.menus.FreeplayState);
        setClass(funkin.states.menus.CreditsState);
        setClass(funkin.states.menus.OptionsState);
        setClass(funkin.states.menus.ContentPackState);
        setClass(funkin.states.menus.OffsetCalibrationState);
        
        setClass(funkin.substates.FunkinSubState);
        setClass(funkin.substates.GameOverSubState);
        setClass(funkin.substates.PauseSubState);
        setClass(funkin.substates.ResetScoreSubState);
        
        setClass(funkin.substates.ScriptedSubState);
        setClass(funkin.substates.ScriptedUISubState);
        
        setClass(funkin.substates.GameplayModifiersMenu);
        setClass(funkin.substates.UnsavedWarningSubState);

        setClass(funkin.substates.transition.FadeTransition);
        setClass(funkin.substates.transition.ScriptedTransition);
        setClass(funkin.substates.transition.TransitionSubState);

        setClass(funkin.ui.ImageBar);
        setClass(funkin.ui.AtlasFont);
        setClass(funkin.ui.AtlasText);
        setClass(funkin.ui.AtlasTextList);

        set("UIButton", funkin.ui.Button);
        set("UICheckbox", funkin.ui.Checkbox);
        set("UICursor", funkin.ui.Cursor);
        setClass(funkin.ui.ImageBar);
        set("UILabel", funkin.ui.Label);
        set("UISliceSprite", funkin.ui.SliceSprite);
        set("UITextbox", funkin.ui.Textbox);
        setClass(funkin.ui.UIComponent);
        setClass(funkin.ui.UISprite);
        setClass(funkin.ui.UIUtil);
        set("UIWindow", funkin.ui.Window);

        set("SoundTray", funkin.ui.SoundTray);
        set("CustomSoundTray", funkin.ui.CustomSoundTray);

        setClass(funkin.utilities.UndoList);
        setClass(funkin.utilities.TouchUtil);
        setClass(funkin.utilities.SwipeUtil);
        setClass(funkin.utilities.ArrayUtil);
        setClass(funkin.utilities.StringUtil);
        setClass(funkin.utilities.CustomEmitter);
        setClass(funkin.utilities.InputFormatter);

        set("UIPrompt", funkin.ui.Prompt);
        set("UIPromptButtonStyle", funkin.ui.Prompt.ButtonStyle);

        set("BlendMode", funkin.scripting.helpers.BlendModeHelper);
        set("FlxAxes", funkin.scripting.helpers.FlxAxesHelper);
        set("FlxCameraFollowStyle", funkin.scripting.helpers.FlxCameraFollowStyleHelper);
        set("FlxColor", funkin.scripting.helpers.FlxColorHelper);
        set("FlxKey", funkin.scripting.helpers.FlxKeyHelper);
        set("FlxTextAlign", funkin.scripting.helpers.FlxTextAlignHelper);
        set("FlxTextBorderStyle", funkin.scripting.helpers.FlxTextBorderStyleHelper);
        set("FlxTweenType", funkin.scripting.helpers.FlxTweenTypeHelper);
        set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection); // using a helper doesn't work, but using the enum directly does???
        set("Thread", funkin.scripting.helpers.ThreadHelper); // haxe.

        set("platform", Constants.CURRENT_OS);
        set("osName", Constants.CURRENT_OS);

        set("isDebugBuild", #if debug true #else false #end);
        set("isReleaseBuild", #if !debug true #else false #end);

        set("game", PlayState.instance);
        set("closeScript", close);

        if(unsafe)
            set("__script__", this);
    }

    public function execute():Void {}

    public function get(name:String):Dynamic {
        return null;
    }

    public function set(name:String, value:Dynamic):Void {}

    public function setClass(value:Class<Dynamic>, ?as:String):Void {}

    public function call(method:String, ?args:Array<Dynamic>):Dynamic {
        return null;
    }

    public function setParent(parent:Dynamic):Void {}

    public function setPublicMap(map:Map<String, Dynamic>):Void {}

    public function close():Void {
        if(closed) return;
        onClose.dispatch();
        call("onClose");
        closed = true;
    }
}
#end