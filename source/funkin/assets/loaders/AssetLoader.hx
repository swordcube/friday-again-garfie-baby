package funkin.assets.loaders;

import haxe.ds.ReadOnlyArray;

class AssetLoader {
    /**
     * The ID of this asset loader instance.
     */
    public var id:String;

    /**
     * The root folder to obtain assets via this asset loader.
     */
    public var root:String;

    public function new(root:String) {
        this.root = root;
    }

    public function getPath(assetID:String):String {
        if(root == null || root.length == 0)
            return assetID;

        return '${root}/${assetID}';
    }
}