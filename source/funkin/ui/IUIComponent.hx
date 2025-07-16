package funkin.ui;

interface IUIComponent {
    public var parent:IUIComponent;
    public var cursorType:CursorType;

    public function checkMouseOverlap():Bool;

    private var _checkingMouseOverlap:Bool;
}