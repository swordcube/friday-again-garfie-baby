package funkin.gameplay.stage;

import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;

import funkin.gameplay.stage.props.*;
import funkin.gameplay.character.Character;

#if SCRIPTING_ALLOWED
import funkin.scripting.FunkinScript;
#end

typedef CharacterSet = {
    var spectator:Character;
    var opponent:Character;
    var player:Character;
}

class Stage extends FlxContainer {
    public static final DEFAULT_SPECTATOR_X:Float = 430;
    public static final DEFAULT_SPECTATOR_Y:Float = 578;

    public static final DEFAULT_OPPONENT_X:Float = -30;
    public static final DEFAULT_OPPONENT_Y:Float = 642;

    public static final DEFAULT_PLAYER_X:Float = 630;
    public static final DEFAULT_PLAYER_Y:Float = 642;

    public var id:String;

    #if SCRIPTING_ALLOWED
    public var script:FunkinScript;
    #end
    
    public var data:StageData;
    public var characters:CharacterSet;

    public var cameraOffsets:Map<String, FlxPoint> = [
        "spectator" => new FlxPoint(),
        "opponent" => new FlxPoint(),
        "player" => new FlxPoint()
    ];
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
            final contentMetadata = Paths.contentMetadata.get(Paths.getContentPackFromPath(scriptPath));
            script = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
            script.setParent(this);

            script.execute();
            script.call("new");
            script.call("onLoad", [data]);
        }
        #end

        var spectatorAdded:Bool = false;
        var opponentAdded:Bool = false;
        var playerAdded:Bool = false;
        var comboAdded:Bool = false;

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
                            characters.spectator.x = propData.properties?.position[0] ?? DEFAULT_SPECTATOR_X;
                            characters.spectator.y = propData.properties?.position[1] ?? DEFAULT_SPECTATOR_Y;
                            cameraOffsets.get("spectator").set(propData.properties?.camera[0] ?? 0.0, propData.properties?.camera[1] ?? 0.0);

                            var scroll:Array<Float> = cast propData.properties?.scroll;
                            if(scroll == null)
                                scroll = [1, 1];
                            
                            characters.spectator.scrollFactor.set(scroll[0] ?? 1.0, scroll[1] ?? scroll[0] ?? 1.0);
                            
                            layer.add(characters.spectator);
                            spectatorAdded = true;
                        }
                            
                    case OPPONENT:
                        if(!opponentAdded) {
                            characters.opponent.x = propData.properties?.position[0] ?? DEFAULT_OPPONENT_X;
                            characters.opponent.y = propData.properties?.position[1] ?? DEFAULT_OPPONENT_Y;
                            cameraOffsets.get("opponent").set(propData.properties?.camera[0] ?? 0.0, propData.properties?.camera[1] ?? 0.0);

                            var scroll:Array<Float> = cast propData.properties?.scroll;
                            if(scroll == null)
                                scroll = [1, 1];
                            
                            characters.opponent.scrollFactor.set(scroll[0] ?? 1.0, scroll[1] ?? scroll[0] ?? 1.0);
                            
                            layer.add(characters.opponent);
                            opponentAdded = true;
                        }
                        
                    case PLAYER:
                        if(!playerAdded) {
                            characters.player.x = propData.properties?.position[0] ?? DEFAULT_PLAYER_X;
                            characters.player.y = propData.properties?.position[1] ?? DEFAULT_PLAYER_Y;
                            cameraOffsets.get("player").set(propData.properties?.camera[0] ?? 0.0, propData.properties?.camera[1] ?? 0.0);

                            var scroll:Array<Float> = cast propData.properties?.scroll;
                            if(scroll == null)
                                scroll = [1, 1];
                            
                            characters.player.scrollFactor.set(scroll[0] ?? 1.0, scroll[1] ?? scroll[0] ?? 1.0);
                            
                            layer.add(characters.player);
                            playerAdded = true;
                        }
                        
                    case COMBO:
                        if(!comboAdded) {
                            prop = new ComboProp(FlxG.width * 0.55, (FlxG.height * 0.5) - 60, this, layer);
                            prop.applyProperties(propData.properties);
                            layer.add(cast prop);
                            props.set("combo", prop);
                            comboAdded = true;
                        }
                }
            }
        }
        if(characters.spectator != null && !spectatorAdded) {
            characters.spectator.setPosition(DEFAULT_SPECTATOR_X, DEFAULT_SPECTATOR_Y);
            addOnLastLayer(characters.spectator);
            spectatorAdded = true;
        }
        if(characters.opponent != null && !opponentAdded) {
            characters.opponent.setPosition(DEFAULT_OPPONENT_X, DEFAULT_OPPONENT_Y);
            addOnLastLayer(characters.opponent);
            opponentAdded = true;
        }
        if(characters.player != null && !playerAdded) {
            characters.player.setPosition(DEFAULT_PLAYER_X, DEFAULT_PLAYER_Y);
            addOnLastLayer(characters.player);
            playerAdded = true;
        }
        if(!comboAdded) {
            final prop:ComboProp = new ComboProp(FlxG.width * 0.55, (FlxG.height * 0.5) - 60, this, layers.last());
            addOnLastLayer(cast prop);
            props.set("combo", prop);
            comboAdded = true;
        }
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onLoadPost", [data]);
        #end
    }

    public function getStageImage(id:String):String {
        return Paths.image('${data.getImageFolder()}/${id}');
    }

    public function getStageAtlas(id:String):FlxAtlasFrames {
        return Paths.getSparrowAtlas('${data.getImageFolder()}/${id}');
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