package funkin.assets.loaders;

class ModAssetLoader extends AssetLoader {
    public var modID:String;

    public function new(modID:String) {
        this.modID = modID;
        super('mods/${modID}');
    }
}