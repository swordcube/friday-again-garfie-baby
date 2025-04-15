package funkin.gameplay.song;

/**
 * Data for a note object, as a class.
 */
@:structInit
class NoteData {
	@:alias("t")
    public var time:Float;

	@:alias("d")
    public var direction:Int;

	@:alias("l")
    public var length:Float;

	@:alias("k")
    public var type:String;

	public function new(time:Float, direction:Int, length:Float, type:String) {
		this.time = time;
		this.direction = direction;
		this.length = length;
		this.type = type;
	}

    public function toString():String {
        return 'NoteData(time: ${time}, direction: ${direction}, length: ${length}, type: ${type})';
    }
}