package funkin.backend.events;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

enum abstract ActionEventType(String) from String to String {
	final UNKNOWN = "UNKNOWN";
    final HUD_GENERATION = "HUD_GENERATION";
	final NOTE_SPAWN = "NOTE_SPAWN";
	final NOTE_HIT = "NOTE_HIT";
	final NOTE_MISS = "NOTE_MISS";
	final CAMERA_MOVE = "CAMERA_MOVE";
	final SONG_EVENT = "SONG_EVENT";
	final DISPLAY_RATING = "DISPLAY_RATING";
	final DISPLAY_COMBO = "DISPLAY_COMBO";
	final COUNTDOWN_START = "COUNTDOWN_START";
	final COUNTDOWN_STEP = "COUNTDOWN_STEP";
	final GAME_OVER = "GAME_OVER";
	final GAME_OVER_CREATE = "GAME_OVER_CREATE";
	final PAUSE_MENU_CREATE = "PAUSE_MENU_CREATE";
	final FREEPLAY_SONG_ACCEPT = "FREEPLAY_SONG_ACCEPT";
}

/**
 * An event for actions to be modified/cancelled with.
 * 
 * Action events are mainly used for gameplay events, but
 * can be used in other places as well.
 */
@:autoBuild(funkin.backend.macros.EventMacro.build())
class ActionEvent implements IFlxDestroyable {
	/**
	 * The type of this event, represented as a string.
	 */
	public var type:ActionEventType;

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

	public function flagAsPre():ActionEvent {
        post = false;
		return this;
	}

	public function flagAsPost():ActionEvent {
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
	public function recycleBase():ActionEvent {
		data = {};
		cancelled = false;

		_canPropagate = true;
		flagAsPre();

		return this;
	}

	public function new(type:ActionEventType) {
		this.type = type;
	}

	public function destroy():Void {
		data = null;
	}
}