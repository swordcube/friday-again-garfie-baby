package funkin.gameplay.character;

import funkin.graphics.AtlasType;
import funkin.graphics.SkinnableSprite;

class Character extends FlxSprite {
    public var data(default, null):CharacterData;
    public var characterID(default, null):String;
    public var isPlayer(default, null):Bool = false;

    public function new(characterID:String, isPlayer:Bool = false) {
        super();
        if(characterID == null || characterID.length == 0)
            characterID = Constants.DEFAULT_CHARACTER;

        this.characterID = characterID;
        this.isPlayer = isPlayer;

        data = CharacterData.load(characterID);
    }
}