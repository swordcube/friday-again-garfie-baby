package funkin.gameplay.modchart;

import flixel.util.FlxAxes;
import flixel.math.FlxPoint;

import funkin.states.PlayState;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;

import funkin.gameplay.notes.StrumLine;
import funkin.gameplay.modchart.Modifier;

import funkin.gameplay.modchart.events.*;
import funkin.gameplay.modchart.modifiers.*;

class Manager extends FlxBasic {
    public static final MODIFIER_MAP:Map<String, Class<Modifier>> = [
        "transform" => Transform,
        "scale" => Scale
    ];
    public var conductor:Conductor;
    public var timeline:EventTimeline = new EventTimeline();
    public var registeredStrumLines:Array<RegisteredStrumLine> = [];

    public function new(?conductor:Conductor) {
        super();
        this.conductor = conductor ?? Conductor.instance;

        // default strumlines
        final game:PlayState = PlayState.instance;
        if(game != null) {
            for(s in game.playField.strumLines)
                registerStrumLine(s);
        }
    }

    public function registerStrumLine(strumLine:StrumLine):Void {
        registeredStrumLines.push({
            strumLine: strumLine,
            defaultStrumPositions: strumLine.strums.members.map((s) -> {
                return new FlxPoint(s.x, s.y);
            })
        });
    }

    public function registerModifier(name:String):Void {
        if(!MODIFIER_MAP.exists(name)) {
            Logs.warn('Modifier doesn\'t exist: ${name}');
            return;
        }
        final mod:Modifier = Type.createInstance(MODIFIER_MAP.get(name), [this]);
        _modifierList.push(mod);
        _modifierCache.set(name, mod);

        for(name in mod.getSubmods()) {
            final submod:SubModifier = mod.submods.get(name);
            _modifierList.push(submod);
            _modifierCache.set(name, submod);
        }
    }

    public function getModifier(name:String):Modifier {
        return _modifierCache.get(name.toLowerCase());
    }

    public function getDefaultPos(strum:Int, axis:FlxAxes, player:Int):Float {
        final s:Strum = registeredStrumLines[player].strumLine.strums.members.unsafeGet(strum);
        switch(axis) {
            case X:  return registeredStrumLines[player].defaultStrumPositions.unsafeGet(strum).x + s.offsetX;
            case Y:  return registeredStrumLines[player].defaultStrumPositions.unsafeGet(strum).y + s.offsetY;
            default: return 0;
        }
    }

    public function getDefaultScale(object:ModifierObject):FlxPoint {
        @:privateAccess
        switch(object.objectType) {
            case STRUM: return _cachedPoint.set(object.toStrum()._skinData.scale, object.toStrum()._skinData.scale);
            case NOTE:  return _cachedPoint.set(object.toNote()._skinData.scale, object.toNote()._skinData.scale);
            default:    return _cachedPoint.set(1, 1);
        }
    }

    public function getValue(name:String, player:Int):Float {
        name = name.toLowerCase();
        for(mod in _modifierList) {
            if(mod.getName() == name)
                return mod.getValue(player);

            for(sName => submod in mod.submods) {
                if(sName == name)
                    return submod.getValue(player);
            }
        }
        return 0;
    }

    public function setValue(name:String, value:Float, player:Int = -1):Void {
        name = name.toLowerCase();
        for(mod in _modifierList) {
            if(mod.getName() == name)
                mod.setValue(value, player);

            for(sName => submod in mod.submods) {
                if(sName == name)
                    submod.setValue(value, player);
            }
        }
    }

    public function getPercent(name:String, player:Int):Float {
        name = name.toLowerCase();
        for(mod in _modifierList) {
            if(mod.getName() == name)
                return mod.getPercent(player);

            for(sName => submod in mod.submods) {
                if(sName == name)
                    return submod.getPercent(player);
            }
        }
        return 0;
    }

    public function setPercent(name:String, value:Float, player:Int = -1):Void {
        name = name.toLowerCase();
        for(mod in _modifierList) {
            if(mod.getName() == name)
                mod.setPercent(value, player);

            for(sName => submod in mod.submods) {
                if(sName == name)
                    submod.setPercent(value, player);
            }
        }
    }

    public function updateModifier(modifier:Modifier):Void {
        var strum:Strum = null;
        var note:Note = null;

        var rs:RegisteredStrumLine = null;
        for(player in 0...registeredStrumLines.length) {
            rs = registeredStrumLines[player];

            for(strumID in 0...rs.strumLine.strums.length) {
                strum = rs.strumLine.strums.members[strumID];
                modifier.updateStrum(conductor.curDecBeat, strum, strum.vec3Cache, player);
                strum.setPosition(strum.vec3Cache.x, strum.vec3Cache.y);
            }
            for(noteID in 0...rs.strumLine.notes.length) {
                note = rs.strumLine.notes.members[noteID];
                modifier.updateNote(conductor.curDecBeat, note, note.vec3Cache, player);
                note.setPosition(note.vec3Cache.x, note.vec3Cache.y);
            }
        }
    }
	
	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, ease:String = 'linear', player:Int = -1, ?startVal:Float):Void {
		if(player == -1) {
			for(p in 0...registeredStrumLines.length)
				queueEase(step, endStep, modName, target, ease, p, startVal);
		} else {
			final easeFunc = CoolUtil.getEaseFromString(ease);
			timeline.addEvent(new EaseEvent(this, step, endStep, modName, target, easeFunc, player));
		}
	}

    public function queueEaseL(step:Float, lengthInSteps:Float, modName:String, target:Float, ease:String = 'linear', player:Int = -1, ?startVal:Float) {
        queueEase(step, step + lengthInSteps, modName, target, ease, player, startVal);
    }

    public function queueEaseB(beat:Float, endBeat:Float, modName:String, target:Float, ease:String = 'linear', player:Int = -1, ?startVal:Float):Void {
        final step:Float = conductor.getStepAtTime(conductor.getTimeAtBeat(beat));
        final endStep:Float = conductor.getStepAtTime(conductor.getTimeAtBeat(endBeat));
        queueEase(step, endStep, modName, target, ease, player, startVal);
    }

    public function queueEaseBL(beat:Float, lengthInBeats:Float, modName:String, target:Float, ease:String = 'linear', player:Int = -1, ?startVal:Float):Void {
        queueEaseB(beat, beat + lengthInBeats, modName, target, ease, player, startVal);
    }
	
	public function queueSet(step:Float, modName:String, target:Float, player:Int = -1):Void {
		if(player == -1) {
			for(p in 0...registeredStrumLines.length)
				queueSet(step, modName, target, p);
		} else
            timeline.addEvent(new SetEvent(this, step, modName, target, player));
	}

    public function queueSetB(beat:Float, modName:String, target:Float, player:Int = -1):Void {
        final step:Float = conductor.getStepAtTime(conductor.getTimeAtBeat(beat));
        queueSet(step, modName, target, player);
    }
	
	public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void):Void {
		timeline.addEvent(new StepCallbackEvent(this, step, endStep, callback));
	}
	
	public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void):Void {
        timeline.addEvent(new CallbackEvent(this, step, callback));
    }

    override function update(elapsed:Float) {
        timeline.update(conductor.curDecStep);

        // reset vec3 caches
        var strum:Strum = null;
        var note:Note = null;

        var rs:RegisteredStrumLine = null;
        for(player in 0...registeredStrumLines.length) {
            rs = registeredStrumLines[player];

            for(strumID in 0...rs.strumLine.strums.length) {
                strum = rs.strumLine.strums.members[strumID];
                strum.vec3Cache.setTo(getDefaultPos(strumID, X, player), getDefaultPos(strumID, Y, player), 0);
            }
            for(noteID in 0...rs.strumLine.notes.length) {
                note = rs.strumLine.notes.members[noteID];
                note.vec3Cache.setTo(note.x, note.y, 0);
            }
        }
        // actually update the modifiers
        var mod:Modifier = null;
        for(i in 0..._modifierList.length) {
            mod = _modifierList[i];
            if(mod.active)
                updateModifier(mod);
        }
    }

    private var _modifierList:Array<Modifier> = []; // includes ALL modifiers (normal & sub)
    private var _modifierCache:Map<String, Modifier> = [];

    private static var _cachedPoint:FlxPoint = new FlxPoint();
}

@:structInit
class RegisteredStrumLine {
    public var strumLine:StrumLine;
    public var defaultStrumPositions:Array<FlxPoint>;
}