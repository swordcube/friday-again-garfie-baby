package funkin.substates;

import funkin.utilities.FileUtil;

#if desktop
import cpp.RawPointer;
import cpp.RawConstPointer;

import hxnativefiledialog.NFD;
import hxnativefiledialog.Types;
#end

import sys.io.File;
import sys.FileSystem;

import flixel.util.FlxTimer;
import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.ui.*;
import funkin.ui.panel.*;

enum DialogType {
    Open;
    OpenMultiple;
    Save;
}

// have to use an external file dialog library because
// lime is stupid and keeps hanging on the save file dialog

class FileDialogMenu extends UISubState {
    public var lastMouseVisible:Bool = false;
    public var lastMouseSystemCursor:Bool = false;
    
    public var dialogType:DialogType;
    public var title:String;

    public var data:String;
    public var dialogOptions:FileDialogOptions;

    public var onSelect:FlxTypedSignal<Array<String>->Void> = new FlxTypedSignal<Array<String>->Void>();
    public var onCancel:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    public function new(dialogType:DialogType, ?title:String, ?data:String, ?dialogOptions:FileDialogOptions) {
        super();
        this.dialogType = dialogType;
        this.title = title;
        this.data = data;
        this.dialogOptions = dialogOptions;
    }

    override function create():Void {
        super.create();
        
        #if FLX_MOUSE
        lastMouseVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;

        lastMouseSystemCursor = FlxG.mouse.useSystemCursor;
        FlxG.mouse.useSystemCursor = true;
        #end
        camera = new FlxCamera();
        camera.bgColor = 0x80000000;
        FlxG.cameras.add(camera, false);

        #if desktop
        FlxTimer.wait(0.25, () -> {
            final defaultSaveFile:String = dialogOptions?.defaultSaveFile;
            final filters:Array<String> = dialogOptions?.filters ?? new Array<String>();
            final filtersStr:String = filters.join(";");
            NFD.SetDialogTitle(cast title);
    
            switch(dialogType) {
                case Open:
                    final filePath:NFDCharStar_T = null;
                    final result:NFDResult_T = NFD.OpenDialog(cast filtersStr, cast defaultSaveFile, RawPointer.addressOf(filePath));
                    switch(result) {
                        case NFD_ERROR:
                            Logs.error('Error opening file: ${NFD.GetError()}');
                            onCancel.dispatch();
    
                        case NFD_OKAY:
                            onSelect.dispatch([cast(filePath, String)]);
                            cpp.Stdlib.nativeFree(untyped filePath);
    
                        case NFD_CANCEL:
                            onCancel.dispatch();
                    }
                    Sys.sleep(0.25);
                    close();
    
                case OpenMultiple:
                    final pathSet:NFDPathSet_T = new NFDPathSet_T();
                    final result:NFDResult_T = NFD.OpenDialogMultiple(cast filtersStr, cast defaultSaveFile, RawPointer.addressOf(pathSet));
                    switch(result) {
                        case NFD_ERROR:
                            Logs.error('Error opening file: ${NFD.GetError()}');
                            onCancel.dispatch();
    
                        case NFD_OKAY:
                            final files:Array<String> = [];
                            final count:cpp.SizeT = NFD.PathSet_GetCount(RawConstPointer.addressOf(pathSet));
                            for(i in 0...count) {
                                final path:NFDCharStar_T = NFD.PathSet_GetPath(RawConstPointer.addressOf(pathSet), i);
                                if(path != null)
                                    files.push(cast(path, String));
                            }
                            onSelect.dispatch(files);
                            NFD.PathSet_Free(RawPointer.addressOf(pathSet));
    
                        case NFD_CANCEL:
                            onCancel.dispatch();
                    }
                    Sys.sleep(0.25);
                    close();
    
                case Save:
                    final filePath:NFDCharStar_T = null;
                    final result:NFDResult_T = NFD.SaveDialog(cast filtersStr, cast defaultSaveFile, RawPointer.addressOf(filePath));
                    switch(result) {
                        case NFD_ERROR:
                            Logs.error('Error opening file: ${NFD.GetError()}');
                            onCancel.dispatch();
    
                        case NFD_OKAY:
                            final filePathStr:String = cast filePath;
                            FileUtil.safeSaveFile(filePathStr, data);
                            onSelect.dispatch([filePathStr]);
                            cpp.Stdlib.nativeFree(untyped filePath);
    
                        case NFD_CANCEL:
                            onCancel.dispatch();
                    }
                    Sys.sleep(0.25);
                    close();
            }
        });
        #end
    }

    override function destroy():Void {
        #if FLX_MOUSE
        FlxG.mouse.useSystemCursor = lastMouseSystemCursor;
        FlxG.mouse.visible = lastMouseVisible;
        #end
        FlxG.cameras.remove(camera);
        super.destroy();
    }
}

typedef FileDialogOptions = {
    var ?defaultSaveFile:String;
    var ?filters:Array<String>;
}