package funkin.backend.scripting.events;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

enum abstract ScriptEventType(String) from String to String {
	final UNKNOWN = "UNKNOWN";
    final HUD_GENERATION = "HUD_GENERATION";
	final NOTE_HIT = "NOTE_HIT";
	final NOTE_MISS = "NOTE_MISS";
	final CAMERA_MOVE = "CAMERA_MOVE";
	final SONG_EVENT = "SONG_EVENT";
	final DISPLAY_RATING = "DISPLAY_RATING";
	final DISPLAY_COMBO = "DISPLAY_COMBO";
}

@:autoBuild(funkin.backend.macros.EventMacro.build())
class ScriptEvent implements IFlxDestroyable {
	/**
	 * The type of this event, represented as a string.
	 */
	public var type:ScriptEventType;

	/**
	 * Additional data if used in scripts
	 */
	public var data:Dynamic = {};
	
	/**
	 * Determines whether or not this event cannot
	 * continue performing it's action any further.
	 */
	public var cancelled:Bool = false;

    /**
	 * Determines whether or not this event is a post event.
	 */
	public var post:Bool = false;

	/**
	 * Prevents the action associated with this event from occurring.
	 */
	public function cancel():Void {
		cancelled = true;
	}

	/**
	 * Prevents this event from being propagated to anymore scripts.
	 */
	public function stopPropagation():Void {
		_canPropagate = false;
	}

	public function flagAsPre():ScriptEvent {
        post = false;
		return this;
	}

	public function flagAsPost():ScriptEvent {
		post = true;
		return this;
	}

	/**
	 * Returns a string representation of the event.
	 */
	public function toString():String {
		var claName = Type.getClassName(Type.getClass(this)).split(".");
		var rep = '${claName[claName.length - 1]}${cancelled ? " (Cancelled)" : ""}';
		return rep;
	}

	//----------- [ Private API ] -----------//

	@:noDoc
	@:noCompletion
	private var _canPropagate:Bool = true;

	@:noDoc
	@:noCompletion
	public function recycleBase():Void {
		data = {};
		cancelled = false;

		_canPropagate = true;
		flagAsPre();
	}

	public function new(type:ScriptEventType) {
		this.type = type;
	}

	public function destroy():Void {
		data = null;
	}
}