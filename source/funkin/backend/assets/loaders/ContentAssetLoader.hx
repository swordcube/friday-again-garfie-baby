package funkin.backend.assets.loaders;

class ContentAssetLoader extends AssetLoader {
    public var folder:String;

    public function new(folder:String) {
        this.folder = folder;

        final liveReload:Bool = #if TEST_BUILD true #else Sys.args().contains("-livereload") #end;
        final root:String = (liveReload) ? "../../../../" : "";
        
        super('${root}${Paths.CONTENT_DIRECTORY}/${folder}');
    }
}