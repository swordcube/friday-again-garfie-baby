package funkin.assets.loaders;

class DefaultAssetLoader extends AssetLoader {
    public function new() {
        final root:String = Sys.args().contains("-livereload") ? "../../../../" : "";
        super('${root}assets');
    }
}