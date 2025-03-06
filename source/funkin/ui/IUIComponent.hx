package funkin.ui;

interface IUIComponent {
    public var cursorType:CursorType;

    public function checkMouseOverlap():Bool;
}