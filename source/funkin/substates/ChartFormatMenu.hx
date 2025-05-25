package funkin.substates;

import flixel.text.FlxText;
import flixel.math.FlxPoint;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import haxe.io.Path;

import moonchart.formats.*;
import moonchart.formats.BasicFormat.BasicChart;

import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;

import openfl.events.Event;
import openfl.events.IOErrorEvent;

import openfl.net.FileFilter;
import openfl.filesystem.File as OpenFLFile;

import funkin.ui.AtlasText;
import funkin.graphics.TrackingSprite;

import funkin.substates.FileDialogMenu;

import funkin.gameplay.song.moonchart.GarfieFormat;

class ChartFormatMenu extends FunkinSubState {
    public static final validFormats:Array<ChartFormatMeta> = [
        {
            id: FNF_LEGACY,
            iconID: 0,
            title: "Funkin' Legacy",
            formatConstructor: FNFLegacy.new.bind(null)
        },
        {
            id: FNF_PSYCH,
            iconID: 0,
            title: "Psych Engine",
            formatConstructor: FNFPsych.new.bind(null)
        },
        {
            id: FNF_CODENAME,
            iconID: 0,
            title: "Codename Engine",
            formatConstructor: FNFCodename.new.bind(null, null)
        },
        {
            id: FNF_VSLICE,
            iconID: 0,
            title: "Funkin' V-Slice",
            formatConstructor: FNFVSlice.new.bind(null, null)
        },
        {
            id: FNF_GARFIE,
            iconID: 0,
            title: "Garfie Baby",
            formatConstructor: GarfieFormat.new.bind(null, null)
        },
        {
            id: GUITAR_HERO,
            iconID: 1,
            title: "Guitar Hero",
            formatConstructor: GuitarHero.new.bind(null)
        },
        {
            id: OSU_MANIA,
            iconID: 2,
            title: "osu!mania",
            formatConstructor: OsuMania.new.bind(null)
        },
        {
            id: QUAVER,
            iconID: 3,
            title: "Quaver",
            formatConstructor: Quaver.new.bind(null)
        },
        {
            id: STEPMANIA,
            iconID: 4,
            title: "StepMania",
            formatConstructor: StepMania.new.bind(null)
        },
        {
            id: STEPMANIA_SHARK,
            iconID: 4,
            title: "StepMania Shark",
            formatConstructor: StepManiaShark.new.bind(null)
        }
    ];
    public var title:String;
    public var animateIn:Bool;
    
    public var menuCam:FlxCamera;
    public var titleText:FlxText;

    public var curSelected:Int = 0;

    public var grpFormats:FlxTypedGroup<ChartFormatItem>;
    public var grpIcons:FlxTypedGroup<FlxSprite>;

    public var selectionArrow:AtlasText;

    public var onSelect:ChartFormatMeta->Void;
    public var onCancel:Void->Void;
    public var onSuccess:Void->Void;

    public var busy:Bool = false;

    public function new(title:String, ?animateIn:Bool = true) {
        super();
        this.title = title;
        this.animateIn = animateIn;
    }

    override function create():Void {
        super.create();

        // Setup the menu camera
        menuCam = new FlxCamera();
        menuCam.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(menuCam, false);

        cameras = [menuCam];

        // Setup the title text
        titleText = new FlxText(200, 100, 0, title);
        titleText.setFormat(Paths.font("fonts/vcr"), 16, FlxColor.WHITE, LEFT);
        titleText.setBorderStyle(OUTLINE, FlxColor.BLACK);
        add(titleText);

        // Setup the menu items
        grpFormats = new FlxTypedGroup<ChartFormatItem>();
        add(grpFormats);

        grpIcons = new FlxTypedGroup<FlxSprite>();
        add(grpIcons);

        final itemSpacing:Float = 10;
        for(i in 0...validFormats.length) {
            final meta:ChartFormatMeta = validFormats[i];

            final text:ChartFormatItem = new ChartFormatItem(titleText.x + 55, titleText.y + titleText.height + (i * (36 + itemSpacing)) + itemSpacing, "bold", LEFT, meta.title, 0.6);
            text.ID = i;
            text.alpha = 0.6;
            grpFormats.add(text);

            final icon:TrackingSprite = new TrackingSprite().loadGraphic(Paths.image("menus/chart_formats"), true, 64, 64);
            icon.tracked = text;
            icon.trackingMode = LEFT;
            icon.trackingOffset.set(-55, 0);
            icon.animation.add("idle", [meta.iconID], 24, false);
            icon.animation.play("idle");
            icon.setGraphicSize(45, 45);
            icon.updateHitbox();
            grpIcons.add(icon);

            text.icon = icon;
        }
        selectionArrow = new AtlasText(FlxG.width - 200, grpFormats.members[0].y, "bold", LEFT, "<");
        selectionArrow.x -= selectionArrow.width;
        add(selectionArrow);

        changeSelection(0, true);

        _mouseVisibility = FlxG.mouse.visible;
        FlxG.mouse.visible = true;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        if(!busy) {
            if(controls.justPressed.BACK) {
                if(onCancel != null)
                    onCancel();
            }
            if(controls.justPressed.UI_UP)
                changeSelection(-1);
    
            if(controls.justPressed.UI_DOWN)
                changeSelection(1);
    
            if(controls.justPressed.ACCEPT || FlxG.mouse.justPressed) {
                if(onSelect != null)
                    onSelect(validFormats[curSelected]);
            }
        }
        selectionArrow.y = FlxMath.lerp(selectionArrow.y, grpFormats.members[curSelected].y, elapsed * 15);
    }
    
    override function destroy():Void {
        FlxG.mouse.visible = _mouseVisibility;
        super.destroy();
    }

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = FlxMath.wrap(curSelected + by, 0, grpFormats.length - 1);

        for(i in 0...grpFormats.length) {
            final text:ChartFormatItem = grpFormats.members[i];
            text.alpha = (i == curSelected) ? 1 : 0.6;
        }
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

    public function selectChart(fromFormat:Dynamic, toFormat:Dynamic) {
        var fullChartFilePath:String = null;
        var fullChartMetaFilePath:String = null;

        FlxTimer.wait(0.25, () -> {
            final file = new FileDialogMenu(Open, "Select a chart file to convert");
            file.onSelect.add((files:Array<String>) -> {
                // Select a chart file
                fullChartFilePath = files[0];
                
                FlxTimer.wait(0.25, () -> {
                    final file = new FileDialogMenu(Open, "Select a chart metadata file to convert");
                    file.onSelect.add((files:Array<String>) -> {
                        // Select a chart metadata file
                        fullChartMetaFilePath = files[0];
                        convertChart(fullChartFilePath, fullChartMetaFilePath, fromFormat, toFormat);
                    });
                    file.onCancel.add(() -> {
                        convertChart(fullChartFilePath, fullChartMetaFilePath, fromFormat, toFormat);
                    });
                    openSubState(file);
                });
            });
            file.onCancel.add(() -> {
                if(onCancel != null)
                    onCancel();
            });
            openSubState(file);
        });
    }

    public function convertChart(chartPath:String, chartMetaPath:String, fromFormat:Dynamic, toFormat:Dynamic) {
        trace(fromFormat, toFormat);
        fromFormat.fromFile(chartPath, chartMetaPath);

        final basic:BasicChart = fromFormat.toBasicFormat();
        toFormat.fromFormat(fromFormat);

        final stringifiedShit:Dynamic = toFormat.stringify();
        FlxTimer.wait(0.25, () -> {
            final file = new FileDialogMenu(Save, "Select a location to save the metadata", stringifiedShit.meta, {
                defaultSaveFile: (chartMetaPath != null) ? Path.withoutDirectory(chartMetaPath) : "meta.json",
                filters: ["json"]
            });
            openSubState(file);

            var diffsSaved:Int = 1;
            final ext:String = Path.extension(chartPath);
            for(key in basic.data.diffs.keys()) {
                diffsSaved++;
                toFormat.fromFormat(fromFormat, key);

                final stringifiedShit:Dynamic = toFormat.stringify();
                FlxTimer.wait(0.25 * diffsSaved, () -> {
                    final file = new FileDialogMenu(Save, "Select a location to save the chart", stringifiedShit.data, {
                        defaultSaveFile: '${Path.withoutExtension(Path.withoutDirectory(chartPath))}-${key}.${ext}',
                        filters: ["json"]
                    });
                    openSubState(file);
                });
            }
            FlxTimer.wait((0.25 * diffsSaved) + 0.5, () -> {
                Logs.success('Conversion successful! Going back to main menu in 2 seconds...');
                if(onSuccess != null)
                    onSuccess();
            });
        });
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private var _mouseVisibility:Bool;
}

class ChartFormatItem extends AtlasText {
    public var icon:FlxSprite;

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        var state = FlxG.state;
        while(state.subState != null)
            state = state.subState;

        if(FlxG.mouse.justMoved && state is ChartFormatMenu) {
            final menu:ChartFormatMenu = cast state;
            final mousePos:FlxPoint = FlxG.mouse.getScreenPosition(menu.menuCam, _cachedPoint);

            if(menu != null && !menu.busy && (this.overlapsPoint(mousePos, true, menu.menuCam) || icon.overlapsPoint(mousePos, true, menu.menuCam))) {
                if(menu.curSelected != ID) {
                    menu.curSelected = ID;
                    menu.changeSelection(0, true);
                }
            }
            mousePos.put();
        }
    }

    override function destroy():Void {
        _cachedPoint = FlxDestroyUtil.put(_cachedPoint);
        super.destroy();
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private var _cachedPoint:FlxPoint = FlxPoint.get();
}

enum abstract ChartFormat(String) from String to String {
    final FNF_LEGACY = "fnf-legacy";
    final FNF_PSYCH = "fnf-psych";
    final FNF_CODENAME = "fnf-codename";
    final FNF_VSLICE = "fnf-vslice";
    final FNF_GARFIE = "fnf-garfie";
    final GUITAR_HERO = "guitar-hero";
    final OSU_MANIA = "osu-mania";
    final QUAVER = "quaver";
    final STEPMANIA = "stepmania";
    final STEPMANIA_SHARK = "stepmania-shark";
}

typedef ChartFormatMeta = {
    var id:ChartFormat;
    var iconID:Int;
    var title:String;
    var formatConstructor:Void->Dynamic;
}