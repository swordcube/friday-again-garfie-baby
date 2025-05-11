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
        setClass(funkin.gameplay.HoldTiledSprite);
        setClass(funkin.gameplay.PlayerStats);
        setClass(funkin.gameplay.PlayField);
        setClass(funkin.gameplay.UISkin);

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

        setClass(funkin.gameplay.song.ChartData);
        setClass(funkin.gameplay.song.NoteData);
        setClass(funkin.gameplay.song.EventData);
        setClass(funkin.gameplay.song.Highscore);
        setClass(funkin.gameplay.song.SongMetadata);
        setClass(funkin.gameplay.song.VocalGroup);

        setClass(funkin.gameplay.character.Character);

        setClass(funkin.gameplay.scoring.Scoring);
        setClass(funkin.gameplay.scoring.ScoringSystem);

        setClass(funkin.gameplay.scoring.system.PBotSystem);
        setClass(funkin.gameplay.scoring.system.Judge4System);

        set("FlxRuntimeShader", funkin.graphics.shader.RuntimeShader);
        setClass(funkin.graphics.shader.RuntimeShader);
        setClass(funkin.graphics.shader.CustomShader);

        setClass(funkin.states.PlayState);
        setClass(funkin.states.FunkinState);
        setClass(funkin.states.ScriptedState);

        setClass(funkin.states.menus.TitleState);
        setClass(funkin.states.menus.MainMenuState);
        setClass(funkin.states.menus.StoryMenuState);
        setClass(funkin.states.menus.FreeplayState);
        setClass(funkin.states.menus.OptionsState);
        setClass(funkin.states.menus.ContentPackState);
        
        setClass(funkin.substates.FunkinSubState);
        setClass(funkin.substates.ScriptedSubState);
        setClass(funkin.substates.GameplayModifiersMenu);

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

        setClass(funkin.utilities.UndoList);
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
        set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection); // using a helper doesn't work, but using the enum directly does

        set("platform", Constants.CURRENT_OS);
        set("osName", Constants.CURRENT_OS);

        set("isDebugBuild", #if debug true #else false #end);
        set("isReleaseBuild", #if !debug true #else false #end);

        set("game", PlayState.instance);
        set("closeScript", close);
    }

    public function execute():Void {}

    public function get(name:String):Dynamic {
        return null;
    }

    public function set(name:String, value:Dynamic):Void {}

    public function setClass(value:Class<Dynamic>):Void {}

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