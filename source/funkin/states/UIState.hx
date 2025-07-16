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

            if(c is FlxBasic) {
                final b:FlxBasic = cast c;
                if(!b.exists || !b.alive)
                    continue;
                
                // find the parent of the component
                var isInState:Bool = false;
                var container:FlxBasic = b;

                while(container != null) {
                    if(container is FlxState) {
                        isInState = true;
                        break;
                    }
                    container = container.container;
                }
                // if the parent is not a state, or the container is dead, continue
                if(!isInState || !container.exists || !container.alive)
                    continue;

                // if the parent is a state, continue if it has a substate open
                final s:FlxState = cast container;
                if(!persistentUpdate && s.subState != null)
                    continue;
            }
            if(c.checkMouseOverlap())
                newCursor = c.cursorType;
        }
        if(Cursor.type != newCursor)
            Cursor.type = newCursor;
    }

    override function destroy():Void {
        Cursor.type = DEFAULT; // reset to default, since the state we're heading to may not be another UIState!
        WindowUtil.resetTitleAffixes(); // reset window prefix & suffix to default
        
        super.destroy();
    }
}