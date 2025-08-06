package funkin.mobile.utilities;

#if mobile
import lime.system.System;
import lime.app.Application;

#if android
import extension.androidtools.os.Build.VERSION;
import extension.androidtools.os.Environment;
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
#end
import sys.FileSystem;
import sys.io.File;

import funkin.backend.native.NativeAPI;

class MobileUtil {
    public static var currentDirectory:String = null;
    
    /**
     * Get the directory for the application. (External for Android Platform and Internal for iOS Platform.)
     */
    public static function getDirectory():String {
        #if android
        if (VERSION.SDK_INT >= 33) {
            currentDirectory = Environment.getExternalStorageDirectory() + '/.' + Application.current.meta.get('file');
        } else {
            currentDirectory = Environment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
        }
        #elseif ios
        currentDirectory = System.documentsDirectory;
        #end
        return currentDirectory;
    }
    
    #if android
    /**
     * Requests Storage Permissions on Android Platform.
     */
    public static function getPermissions():Void {
        // Doesn't work on Android 11+ because fuck you i guess
        // if (VERSION.SDK_INT >= 33) {
        //     if (!Environment.isExternalStorageManager())
        //         Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
        // } else
        //     Permissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
    
        try {
            if (!FileSystem.exists(MobileUtil.getDirectory()))
                FileSystem.createDirectory(MobileUtil.getDirectory());
        }
        catch (e:Dynamic) {
            trace(e);
            if (!FileSystem.exists(MobileUtil.getDirectory())) {
                NativeAPI.showMessageBox(
                    "Uncaught Error",
                    "Woops! Looks like you haven't enabled the permissions required to run the game\nor you haven't put the game assets folder onto your storage yet!\n\nPress OK to close the game.",
                    ERROR | MessageBoxOptions.OK
                );
                FileSystem.createDirectory(MobileUtil.getDirectory());
                System.exit(0);
            }
        }
    }
    
    /**
     * Saves a file to the external storage.
     */
    public static function saveFile(fileName:String = 'N/A', fileExt:String = '.json', fileData:String = 'N/A') {
        final savesDir:String = MobileUtil.getDirectory() + '/saved-content/';
        if(!FileSystem.exists(savesDir))
            FileSystem.createDirectory(savesDir);
    
        File.saveContent(savesDir + fileName + fileExt, fileData);
    }
    #end
}
#end