package funkin.utilities;

class UndoList<T> {
	public var undoList(default, null):Array<T> = [];
	public var redoList(default, null):Array<T> = [];

	public var unsaved:Bool = false;

	public function new() {}

	public function add(c:T):Void {
		redoList.resize(0);
		undoList.insert(0, c);

		while(undoList.length > Constants.MAX_UNDOS)
			undoList.pop();
	}

	public function undo():T {
		var undo = undoList.shift();
		if(undo != null)
			redoList.insert(0, undo);
		
        return undo;
	}

	public function redo():T {
		var redo = redoList.shift();
		if(redo != null)
			undoList.insert(0, redo);
		
        return redo;
	}

	public inline function save():Void {
		unsaved = true;
    }
}