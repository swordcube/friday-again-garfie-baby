package funkin.substates;

import flixel.text.FlxText;
import flixel.math.FlxPoint;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import haxe.io.Path;

import moonchart.formats.*;
import moonchart.formats.BasicFormat.BasicChart;
import moonchart.formats.BasicFormat.DynamicFormat;
import moonchart.formats.BasicFormat.FormatStringify;

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

        #if (FLX_MOUSE && !mobile)
        _mouseVisibility = FlxG.mouse.visible;
        FlxG.mouse.visible = true;
        #end
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
    
            if(controls.justPressed.ACCEPT || TouchUtil.justPressed) {
                if(onSelect != null)
                    onSelect(validFormats[curSelected]);
            }
        }
        selectionArrow.y = FlxMath.lerp(selectionArrow.y, grpFormats.members[curSelected].y, elapsed * 15);
    }
    
    #if (FLX_MOUSE && !mobile)
    override function destroy():Void {
        FlxG.mouse.visible = _mouseVisibility;
        super.destroy();
    }
    #end

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

    public function selectChart(fromFormat:DynamicFormat, toFormat:DynamicFormat) {
        var fullMetaPath:String = null;
        function continueConverting() {
            final file = new FileDialogMenu(OpenMultiple, "Select chart files to convert");
            file.onSelect.add((files:Array<String>) -> {
                var i:Int = 0;
                var metaToSave:Dynamic = null;
                
                function doShit() {
                    if(i >= files.length) {
                        // Save the metadata
                        FlxTimer.wait(0.001, () -> {
                            if(metaToSave != null) {
                                final file = new FileDialogMenu(Save, "Select a location to save the metadata", metaToSave, {
                                    defaultSaveFile: (fullMetaPath != null) ? Path.withoutDirectory(fullMetaPath) : "meta.json",
                                    filters: ["json"]
                                });
                                function yaySuccessGood() {
                                    Logs.success('Conversion successful! Going back to main menu in 2 seconds...');
                                    if(onSuccess != null)
                                        onSuccess();
                                }
                                file.onSelect.add((_) -> yaySuccessGood());
                                file.onCancel.add(yaySuccessGood);
                                openSubState(file);
                            }
                        });
                        return;
                    }
                    
                    // Select chart files to convert
                    // These files will correspond to each difficulty
                    
                    // for most FNF charts, only a single chart is required for
                    // V-Slice and Garfie Baby formats though
                    
                    final filePath:String = files[i];
                    if(filePath == null)
                        return;

                    var curDiff:String = null;
                    var knownDiffs:Array<String> = ["easy", "normal", "hard"];
        
                    var fileName:String = Path.withoutExtension(Path.withoutDirectory(filePath));
                    if(!fileName.startsWith("chart")) {
                        var split:Array<String> = fileName.split("-");
                        for(diff in knownDiffs) {
                            var detectedDiff:String = split[1];
                            if(detectedDiff != null)
                                detectedDiff = detectedDiff.toLowerCase();
                            else
                                detectedDiff = fileName;

                            switch(diff.toLowerCase()) {
                                case "normal":
                                    // legacy fnf charts are weird
                                    // and save normal diffs as song only
                                    // instead of song-normal
                                    final split2:Array<String> = filePath.replace("\\", "/").split("/");
                                    final songName:String = split2[split2.length - 2];

                                    if(songName != null && detectedDiff == songName) {
                                        fileName = diff;
                                        curDiff = diff;
                                    }
                                    else if(detectedDiff == diff) {
                                        fileName = diff;
                                        curDiff = diff;
                                    }
                
                                default:
                                    if(detectedDiff == diff) {
                                        fileName = detectedDiff;
                                        curDiff = diff;
                                    }
                            }
                        }
                    }
                    trace('Converting ${filePath}');
                    fromFormat.fromFile(filePath, fullMetaPath);
                    toFormat.fromFormat(fromFormat, curDiff);
    
                    // Cache the metadata for later use
                    if(metaToSave == null) {
                        final stringifiedShit:FormatStringify = toFormat.stringify();
                        metaToSave = stringifiedShit.meta;
                    }
                    // Convert & save the chart
                    final dialog:FileDialogMenu = saveChart(filePath, fileName, toFormat);
                    dialog.closeCallback = doShit;
                    i++;
                }
                doShit();
            });
            file.onCancel.add(() -> {
                if(onCancel != null)
                    onCancel();
            });
            openSubState(file);
        }
        final file = new FileDialogMenu(Open, "Select a chart metadata file to convert");
        file.onSelect.add((files:Array<String>) -> {
            // Select a chart metadata file to convert
            fullMetaPath = files[0];
            continueConverting();
        });
        file.onCancel.add(continueConverting);
        openSubState(file);
    }

    public function saveChart(chartPath:String, fileName:String, toFormat:DynamicFormat):FileDialogMenu {
        final ext:String = Path.extension(chartPath);
        final stringifiedShit:FormatStringify = toFormat.stringify();

        final file = new FileDialogMenu(Save, "Select a location to save the chart", stringifiedShit.data, {
            defaultSaveFile: '${fileName}.${ext}',
            filters: [ext]
        });
        openSubState(file);
        return file;
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

        final pointer = TouchUtil.touch;
        if(TouchUtil.justMoved && state is ChartFormatMenu) {
            final menu:ChartFormatMenu = cast state;
            final mousePos:FlxPoint = pointer.getScreenPosition(menu.menuCam, _cachedPoint);

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