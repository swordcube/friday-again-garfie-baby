package funkin.assets.loaders;

class ContentAssetLoader extends AssetLoader {
    public var folder:String;

    public function new(folder:String) {
        this.folder = folder;

        final root:String = Sys.args().contains("-livereload") ? "../../../../" : "";
        super('${root}${Paths.CONTENT_DIRECTORY}/${folder}');
    }
}