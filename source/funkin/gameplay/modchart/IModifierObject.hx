package funkin.gameplay.modchart;

import funkin.gameplay.modchart.math.Vector3;

enum ModifierObjectType {
    STRUM;
    NOTE;
}

interface IModifierObject {
    public var objectType:ModifierObjectType;
    public var vec3Cache:Vector3;
}