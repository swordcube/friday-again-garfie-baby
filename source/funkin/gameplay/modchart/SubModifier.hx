package funkin.gameplay.modchart;

class SubModifier extends Modifier {
    public var name:String;
    public var parent:Modifier;

    public function new(name:String, manager:Manager, parent:Modifier) {
        super(manager);
        this.name = name;
        this.parent = parent;
    }

    override function getName():String {
        return name;
    }
}