package funkin.gameplay.stage;

import funkin.gameplay.character.Character;
import funkin.gameplay.stage.props.*;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.FunkinScript;
#end

typedef CharacterSet = {
    var spectator:Character;
    var opponent:Character;
    var player:Character;
}

class Stage extends FlxContainer {
    public var id:String;

    #if SCRIPTING_ALLOWED
    public var script:FunkinScript;
    #end
    
    public var data:StageData;
    public var characters:CharacterSet;
    
    public var props:Map<String, StageProp> = [];
    public var layers:Array<FlxContainer> = [];
    
    public function new(?id:String, characters:CharacterSet) {
        super();
        if(id == null || id.length == 0)
            id = "stage";
        
        this.id = id;
        this.characters = characters;
        Logs.verbose('Loading stage: ${id}');
        
        data = StageData.load(id);

        #if SCRIPTING_ALLOWED
        final scriptPath:String = Paths.script('gameplay/stages/${id}/script');
        if(FlxG.assets.exists(scriptPath)) {
            script = FunkinScript.fromFile(scriptPath);
            script.setParent(this);
            script.execute();
            script.call("onLoad");
        }
        #end

        var spectatorAdded:Bool = false;
        var opponentAdded:Bool = false;
        var playerAdded:Bool = false;

        for(layerData in data.layers) {
            final layer:FlxContainer = new FlxContainer();
            layers.push(layer);
            add(layer);

            for(propData in layerData) {
                var prop:StageProp = null;
                switch(propData.type) {
                    case SPRITE:
                        prop = new SpriteProp(0, 0, this, layer);
                        prop.applyProperties(propData.properties);
                        layer.add(cast prop);
                        props.set(propData.id, prop);
                        
                    case BOX:
                        prop = new BoxProp(0, 0, this, layer);
                        prop.applyProperties(propData.properties);
                        layer.add(cast prop);
                        props.set(propData.id, prop);

                    case SPECTATOR:
                        if(!spectatorAdded) {
                            characters.spectator.x = propData.properties.x ?? 656.0;
                            characters.spectator.y = propData.properties.y ?? 738.0;
                            characters.spectator.scrollFactor.set(propData.properties.scroll?.x ?? 1.0, propData.properties.scroll?.y ?? propData.properties.scroll?.x ?? 1.0);
                            layer.add(characters.spectator);
                            spectatorAdded = true;
                        }
                            
                    case OPPONENT:
                        if(!opponentAdded) {
                            characters.opponent.x = propData.properties.x ?? 244.0;
                            characters.opponent.y = propData.properties.y ?? 812.0;
                            characters.opponent.scrollFactor.set(propData.properties.scroll?.x ?? 1.0, propData.properties.scroll?.y ?? propData.properties.scroll?.x ?? 1.0);
                            layer.add(characters.opponent);
                            opponentAdded = true;
                        }

                    case PLAYER:
                        if(!playerAdded) {
                            characters.player.x = propData.properties.x ?? 938.0;
                            characters.player.y = propData.properties.y ?? 812.0;
                            characters.player.scrollFactor.set(propData.properties.scroll?.x ?? 1.0, propData.properties.scroll?.y ?? propData.properties.scroll?.x ?? 1.0);
                            layer.add(characters.player);
                            playerAdded = true;
                        }
                }
            }
        }
        if(characters.spectator != null && !spectatorAdded) {
            characters.spectator.setPosition(656.0, 738.0);
            addOnLastLayer(characters.spectator);
            spectatorAdded = true;
        }
        if(characters.opponent != null && !opponentAdded) {
            characters.opponent.setPosition(244.0, 812.0);
            addOnLastLayer(characters.opponent);
            opponentAdded = true;
        }
        if(characters.player != null && !playerAdded) {
            characters.player.setPosition(938.0, 812.0);
            addOnLastLayer(characters.player);
            playerAdded = true;
        }
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onLoadPost");
        #end
    }

    public function getStageImage(id:String):String {
        return Paths.image('${data.getImageFolder()}/${id}');
    }

    public function getStageSFX(id:String):String {
        return Paths.sound('${data.getSFXFolder()}/${id}');
    }

    public function addOnLastLayer<T:FlxBasic>(obj:T):T {
        if(layers.length > 0)
            layers.last().add(obj);
        else
            add(obj);

        return obj;
    }

    override function destroy():Void {
        if(script != null) {
            if(!script.closed) {
                script.call("onDestroy");
                script.close();
            }
            script = null;
        }
        props.clear();
        layers.clear();
        super.destroy();
    }
}