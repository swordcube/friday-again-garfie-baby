package funkin.backend.assets.loaders;

class DefaultAssetLoader extends AssetLoader {
    public function new() {
        final liveReload:Bool = #if NO_LIVE_RELOAD false #else #if (TEST_BUILD && desktop) true #else Sys.args().contains("-livereload") #end #end;
        final root:String = (liveReload) ? "../../../../" : "";
        super('${root}assets');
    }
    
    override function toString():String {
        final liveReload:Bool = #if NO_LIVE_RELOAD false #else #if (TEST_BUILD && desktop) true #else Sys.args().contains("-livereload") #end #end;
        final root:String = (liveReload) ? "../../../../" : "";
        return 'DefaultAssetLoader(${id} - ${root}assets)';
    }
}