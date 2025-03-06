package funkin.states;

import funkin.ui.UIUtil;
import funkin.ui.IUIComponent;

class UIState extends FunkinState {
    override function update(elapsed:Float):Void {
        super.update(elapsed);

        var newCursor:CursorType = DEFAULT;
        for(i in 0...UIUtil.allComponents.length) {
            final c:IUIComponent = UIUtil.allComponents[UIUtil.allComponents.length - i - 1];
            if(c.cursorType == DEFAULT)
                continue;
            
            if(c.checkMouseOverlap()) {
                newCursor = c.cursorType;
                break;
            }
        }
        if(Cursor.type != newCursor)
            Cursor.type = newCursor;
    }

    override function destroy():Void {
        Cursor.type = DEFAULT; // reset to default, since the state we're heading to may not be another UIState!
        super.destroy();
    }
}