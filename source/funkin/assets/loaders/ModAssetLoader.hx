package funkin.assets.loaders;

class ModAssetLoader extends AssetLoader {
    public var modID:String;

    public function new(modID:String) {
        this.modID = modID;

        final root:String = Sys.args().contains("-livereload") ? "../../../../" : "";
        super('${root}mods/${ModManager.modFolders.get(modID)}');
    }
}