package funkin.ui.panel;

class Panel extends CustomPanel {
    public function new(x:Float = 0, y:Float = 0, width:Float, height:Float) {
        super(x, y, Paths.image("ui/images/panel"), width, height);
    }
}