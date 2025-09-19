package funkin.gameplay.modchart;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;

import funkin.gameplay.modchart.math.Vector3;

@:forward
enum abstract ModifierObject(IModifierObject) from IModifierObject to IModifierObject {
    @:to
    public function toStrum():Strum {
        return cast this;
    }

    @:to
    public function toNote():Note {
        return cast this;
    }

    @:to
    public function getSprite():FlxSprite {
        return cast this;
    }
}

@:allow(funkin.modchart.Manager)
class Modifier {
    public var active:Bool = true;
    public var manager(default, null):Manager;

    public var percents:Array<Float> = [0, 0];
    public var submods:Map<String, SubModifier> = [];

    public function new(manager:Manager) {
        this.manager = manager;
        for(name in getSubmods())
            submods.set(name, new SubModifier(name, manager, this));
    }

    public function getName():String {
        return "";
    }

    public function updateStrum(beat:Float, strum:Strum, pos:Vector3, player:Int):Void {}
    public function updateNote(beat:Float, note:Note, pos:Vector3, player:Int):Void {}

    public function updateObject(beat:Float, obj:ModifierObject, pos:Vector3, player:Int):Void {
        switch(obj.objectType) {
            case STRUM: updateStrum(beat, obj.toStrum(), pos, player);
            case NOTE:  updateNote(beat, obj.toNote(), pos, player);
        }
    }

    public function getValue(player:Int):Float {
        if(player < 0)
            return 0;

        while(player >= percents.length)
            percents.push(0);

        return percents.unsafeGet(player);
    }

    public function setValue(value:Float, player:Int = -1):Void {
        if(player < 0) {
            for(i in 0...percents.length)
                percents.unsafeSet(i, value);
        } else {
            while(player >= percents.length)
                percents.push(0);
            
            percents.unsafeSet(player, value);
        }
    }

    public function getPercent(player:Int):Float {
        return getValue(player) * 100;
    }

    public function setPercent(value:Float, player:Int = -1):Void {
        setValue(value * 0.01, player);
    }

    public function getSubmodValue(name:String, player:Int):Float {
        return submods.get(name).getValue(player);
    }

    public function setSubmodValue(name:String, value:Float, player:Int = -1):Void {
        submods.get(name).setValue(value, player);
    }

    public function getSubmodPercent(name:String, player:Int):Float {
        return submods.get(name).getPercent(player);
    }

    public function setSubmodPercent(name:String, value:Float, player:Int = -1):Void {
        submods.get(name).setPercent(value, player);
    }

    public function getSubmods():Array<String> {
        return [];
    }
}