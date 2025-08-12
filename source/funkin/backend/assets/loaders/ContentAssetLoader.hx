package funkin.backend.assets.loaders;

class ContentAssetLoader extends AssetLoader {
    public var folder:String;

    public function new(folder:String) {
        this.folder = folder;

        final liveReload:Bool = #if (TEST_BUILD && desktop) true #else Sys.args().contains("-livereload") #end;
        final root:String = (liveReload) ? "../../../../" : "";
        
        final p:String = '${root}${Paths.CONTENT_DIRECTORY}/${folder}';
        super((FlxG.assets.exists(p)) ? p : '${Paths.CONTENT_DIRECTORY}/${folder}');
    }

    override function toString():String {
        final liveReload:Bool = #if (TEST_BUILD && desktop) true #else Sys.args().contains("-livereload") #end;
        final root:String = (liveReload) ? "../../../../" : "";
        return 'ContentAssetLoader(${id} - ${root}${Paths.CONTENT_DIRECTORY}/${folder})';
    }
}