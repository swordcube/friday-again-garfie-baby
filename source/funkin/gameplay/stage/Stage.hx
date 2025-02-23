package funkin.gameplay.stage;

import funkin.gameplay.character.Character;
import funkin.gameplay.stage.props.*;

typedef CharacterSet = {
    var spectator:Character;
    var opponent:Character;
    var player:Character;
}

class Stage extends FlxGroup {
    public var id:String;
    public var data:StageData;
    public var characters:CharacterSet;

    public var props:Map<String, StageProp> = [];
    public var layers:Array<FlxGroup> = [];

    public function new(?id:String, characters:CharacterSet) {
        super();
        if(id == null || id.length == 0)
            id = "stage";

        this.id = id;
        this.characters = characters;
        Logs.verbose('Loading stage: ${id}');

        data = StageData.load(id);

        for(layerData in data.layers) {
            final layer:FlxGroup = new FlxGroup();
            layers.push(layer);
            add(layer);

            for(propData in layerData) {
                var prop:StageProp = null;
                switch(propData.type) {
                    case SPRITE:
                        prop = new SpriteProp(0, 0, this, layer);
                        prop.applyProperties(propData.properties);
                        layer.add(cast prop);

                    case BOX:
                        prop = new BoxProp(0, 0, this, layer);
                        prop.applyProperties(propData.properties);
                        layer.add(cast prop);

                    case SPECTATOR:
                        characters.spectator.x = propData.properties.x ?? 656.0;
                        characters.spectator.y = propData.properties.y ?? 738.0;
                        characters.spectator.scrollFactor.set(propData.properties.scroll?.x ?? 1.0, propData.properties.scroll?.y ?? propData.properties.scroll?.x ?? 1.0);
                        layer.add(characters.spectator);
                            
                    case OPPONENT:
                        characters.opponent.x = propData.properties.x ?? 244.0;
                        characters.opponent.y = propData.properties.y ?? 812.0;
                        characters.opponent.scrollFactor.set(propData.properties.scroll?.x ?? 1.0, propData.properties.scroll?.y ?? propData.properties.scroll?.x ?? 1.0);
                        layer.add(characters.opponent);

                    case PLAYER:
                        characters.player.x = propData.properties.x ?? 938.0;
                        characters.player.y = propData.properties.y ?? 812.0;
                        characters.player.scrollFactor.set(propData.properties.scroll?.x ?? 1.0, propData.properties.scroll?.y ?? propData.properties.scroll?.x ?? 1.0);
                        layer.add(characters.player);
                }
            }
        }
        if(characters.spectator != null && !members.contains(characters.spectator))
            addOnLastLayer(characters.spectator);

        if(characters.opponent != null && !members.contains(characters.opponent))
            addOnLastLayer(characters.opponent);

        if(characters.player != null && !members.contains(characters.player))
            addOnLastLayer(characters.player);
    }

    public function addOnLastLayer<T:FlxBasic>(obj:T):T {
        if(layers.length > 0)
            layers.last().add(obj);
        else
            add(obj);

        return obj;
    }

    override function destroy() {
        props.clear();
        layers.clear();
        super.destroy();
    }
}