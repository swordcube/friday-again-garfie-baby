package funkin.gameplay.modchart.modifiers;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.NoteSplash;
import funkin.gameplay.notes.HoldGradient;
import funkin.gameplay.notes.HoldCover;

import funkin.gameplay.modchart.math.Vector3;

class Scale extends Modifier {
    public function new(manager:Manager) {
        super(manager);
        setValue(1);
        
        setSubmodValue("scalex", 1);
        setSubmodValue("scaley", 1);

        for(i in 0...4) {
            setSubmodValue("scalex" + i, 1);
            setSubmodValue("scaley" + i, 1);
        }
    }

    override function getName():String {
        return "scale";
    }

    override function getSubmods():Array<String> {
        return [
            "scalex",

            "scalex0",
            "scalex1",
            "scalex2",
            "scalex3",

            "scaley",

            "scaley0",
            "scaley1",
            "scaley2",
            "scaley3"
        ];
    }

    public function updateSplash(beat:Float, targetDirection:Int, splash:NoteSplash, pos:Vector3, player:Int) {
        if(splash.direction != targetDirection)
            return;

        splash.scale.set(
            splash.defScale.x * getValue(player) * getSubmodValue("scalex", player) * getSubmodValue('scalex${splash.direction}', player),
            splash.defScale.y * getValue(player) * getSubmodValue("scaley", player) * getSubmodValue('scaley${splash.direction}', player)
        );
        splash.updateOffset();
    }

    public function updateHoldGradient(beat:Float, targetDirection:Int, gradient:HoldGradient, pos:Vector3, player:Int) {
        if(gradient.direction != targetDirection)
            return;

        gradient.scale.set(
            gradient.defScale.x * getValue(player) * getSubmodValue("scalex", player) * getSubmodValue('scalex${gradient.direction}', player),
            gradient.defScale.y * getValue(player) * getSubmodValue("scaley", player) * getSubmodValue('scaley${gradient.direction}', player)
        );
        gradient.updateOffset();
    }

    public function updateHoldCover(beat:Float, targetDirection:Int, cover:HoldCover, pos:Vector3, player:Int) {
        if(cover.direction != targetDirection)
            return;

        cover.scale.set(
            cover.defScale.x * getValue(player) * getSubmodValue("scalex", player) * getSubmodValue('scalex${cover.direction}', player),
            cover.defScale.y * getValue(player) * getSubmodValue("scaley", player) * getSubmodValue('scaley${cover.direction}', player)
        );
        cover.updateOffset();
    }

    override function updateStrum(beat:Float, strum:Strum, pos:Vector3, player:Int) {
        final scaleX:Float = getValue(player) * getSubmodValue("scalex", player) * getSubmodValue('scalex${strum.direction}', player);
        final scaleY:Float = getValue(player) * getSubmodValue("scaley", player) * getSubmodValue('scaley${strum.direction}', player);
        strum.scale.set(
            strum.defScale.x * scaleX,
            strum.defScale.y * scaleY
        );
        strum.updateOffset();
        
        for(splash in strum.strumLine.splashes)
            updateSplash(beat, strum.direction, splash, pos, player);

        for(gradient in strum.strumLine.holdGradients)
            updateHoldGradient(beat, strum.direction, gradient, pos, player);

        for(cover in strum.strumLine.holdCovers)
            updateHoldCover(beat, strum.direction, cover, pos, player);
    }

    override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {
        final scaleX:Float = getValue(player) * getSubmodValue("scalex", player) * getSubmodValue('scalex${note.direction}', player);
        final scaleY:Float = getValue(player) * getSubmodValue("scaley", player) * getSubmodValue('scaley${note.direction}', player);
        note.scale.set(
            note.defScale.x * scaleX,
            note.defScale.y * scaleY
        );
        note.holdTrail.strip.scale.set(
            note.holdTrail.strip.defScale.x * scaleX,
            note.holdTrail.strip.defScale.y * scaleY
        );
        note.holdTrail.tail.scale.set(
            note.holdTrail.tail.defScale.x * scaleX,
            note.holdTrail.tail.defScale.y * scaleY
        );
    }
}