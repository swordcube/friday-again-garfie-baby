package funkin.backend.assets.loaders;

class DefaultAssetLoader extends AssetLoader {
    public function new() {
        final liveReload:Bool = #if TEST_BUILD true #else Sys.args().contains("-livereload") #end;
        final root:String = (liveReload) ? "../../../../" : "";
        super('${root}assets');
    }
}