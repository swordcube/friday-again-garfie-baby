package funkin.substates;

import funkin.ui.UIUtil;
import funkin.ui.IUIComponent;

class UISubState extends FunkinSubState {
    override function update(elapsed:Float):Void {
        super.update(elapsed);

        var newCursor:CursorType = DEFAULT;
        for(i in 0...UIUtil.allComponents.length) {
            final c:IUIComponent = UIUtil.allComponents[UIUtil.allComponents.length - i - 1];
            if(c.cursorType == DEFAULT)
                continue;
            
            if(c is FlxBasic) {
                final b:FlxBasic = cast c;
                
                // find the parent of the component
                var container:FlxContainer = b.container;
                while(container?.container != null)
                    container = container.container;
                
                // if the parent is not a state, continue
                if(!(container is FlxState))
                    continue;

                // if the parent is a state, continue if it has a substate open
                final s:FlxState = cast container;
                if(!persistentUpdate && s.subState != null)
                    continue;
            }
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