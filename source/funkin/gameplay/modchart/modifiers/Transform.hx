package funkin.gameplay.modchart.modifiers;

import funkin.gameplay.notes.Strum;
import funkin.gameplay.notes.Note;

import funkin.gameplay.modchart.math.Vector3;

class Transform extends Modifier {
    override function getName():String {
        return "transform";
    }

    override function getSubmods():Array<String> {
        return [
            "transformx",

            "transformx0",
            "transformx1",
            "transformx2",
            "transformx3",
            
            "transformy",

            "transformy0",
            "transformy1",
            "transformy2",
            "transformy3",
            
            "transformz", // TODO: z depth shit??? maybe???
            
            "transformz0", // TODO: z depth shit??? maybe???
            "transformz1", // TODO: z depth shit??? maybe???
            "transformz2", // TODO: z depth shit??? maybe???
            "transformz3", // TODO: z depth shit??? maybe???
        ];
    }

    override function updateStrum(beat:Float, strum:Strum, pos:Vector3, player:Int) {
        pos.x += getSubmodValue("transformx", player) + getSubmodValue('transformx${strum.direction}', player);
        pos.y += getSubmodValue("transformy", player) + getSubmodValue('transformy${strum.direction}', player);
        pos.z += getSubmodValue("transformz", player) + getSubmodValue('transformz${strum.direction}', player);
    }
}