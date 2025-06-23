package funkin.utilities;

import haxe.io.Bytes;
import haxe.io.Path;

import sys.io.File;
import sys.FileSystem;

import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.native.NativeAPI;

class FileUtil {
    /**
     * A utility function to open a folder in the file manager.
     * 
     * @param  pathFolder  The path of the folder to open.
     */
    @:noUsing
    public static function openFolder(pathFolder:String):Void {
        if(FileSystem.exists(pathFolder) && !FileSystem.isDirectory(pathFolder))
            throw 'Invalid folder: ${pathFolder}';

        #if windows
        // windows is dumb <3
        final oldCwd:String = Sys.getCwd();
        Sys.setCwd(pathFolder);
        Sys.command("explorer", ["."]);
        Sys.setCwd(oldCwd);
        #elseif mac
        Sys.command("open", [pathFolder]);
        #elseif linux
        Sys.command("/usr/bin/xdg-open", [pathFolder]);
        #end
    }

    /**
	 * Creates eventual missing folders to the specified `path`
	 *
	 * WARNING: Eventual files in `path` will be considered as folders! Just to make possible
	 * folders be named as `songs.json` for example.
	 *
	 * @param  path  Path to check.
	 * @return The initial file path.
	 */
	@:noUsing
    public static function addMissingFolders(path:String):String {
		#if sys
		var folders:Array<String> = path.split("/");
		var currentPath:String = "";

		for (folder in folders) {
			currentPath += folder + "/";
			if (!FileSystem.exists(currentPath))
				FileSystem.createDirectory(currentPath);
		}
		#end
		return path;
	}

    /**
	 * Safe saves a file (even adding eventual missing folders) and shows a warning box instead
	 * of making the program crash in the case of an error.
	 * 
	 * @param  path     Path to save the file at.
	 * @param  content  Content of the file to save (as String or Bytes).
	 */
	@:noUsing
    public static function safeSaveFile(path:String, content:OneOfTwo<String, Bytes>, showErrorBox:Bool = true) {
		#if sys
		try {
			addMissingFolders(Path.directory(path));
			if(content is Bytes)
                File.saveBytes(path, content);
			else
                File.saveContent(path, content);
		}
        catch(e) {
            final errMsg:String = 'Error while trying to save the file: ${Std.string(e).replace('\n', ' ')}';
			Logs.error(errMsg);

			if(showErrorBox)
                NativeAPI.showMessageBox("Garfie Baby Warning", errMsg, MessageBoxIcon.WARNING); // yes, i did take this from codename. yes, i did forget to remove the codename text. Fuck.
		}
		#end
	}
}