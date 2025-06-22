package funkin.states;

import flixel.FlxState;
import flixel.FlxSubState;

import funkin.substates.transition.FadeTransition;
import funkin.substates.transition.TransitionSubState;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

// i did not feel like coding all of this entirely on my own
// so i stole code! (the original source is in the @see part of the documentation)

// might do it later for more flexability in scripts
// but this will do for now

enum abstract TransitionStatusString(String) from String to String {
	final IN = "in";
	final OUT = "out";
	final EMPTY = "empty";
	final FULL = "full";
	final NULL = "null";

	@:from
	public static function fromFlixelTransitionStatus(status:TransitionStatus):TransitionStatusString {
		switch(status) {
			case TransitionStatus.IN:    return IN;
			case TransitionStatus.OUT:   return OUT;
			case TransitionStatus.EMPTY: return EMPTY;
			case TransitionStatus.FULL:  return FULL;
			case TransitionStatus.NULL:  return NULL;
		}
		return NULL;
	}

	@:to
	public function toFlixelTransitionStatus():TransitionStatus {
		switch(this) {
			case IN:    return TransitionStatus.IN;
			case OUT:   return TransitionStatus.OUT;
			case EMPTY: return TransitionStatus.EMPTY;
			case FULL:  return TransitionStatus.FULL;
			case NULL:  return TransitionStatus.NULL;
		}
		return TransitionStatus.NULL;
	}
}

/**
 * A state that can be transitioned into and out of.
 * 
 * @see https://github.com/riconuts/FNF-Troll-Engine/blob/7acf9bf10e67c5d2fef13a9bbd9d64dbbc0d3da4/source/flixel/addons/transition/FlxTransitionableState.hx
 */
class TransitionableState extends FlxState {
	/**
     * Default intro transition. Used when `transIn` is null
     */
	public static var defaultTransIn:Class<TransitionSubState> = null;

	/**
     * Default outro transition. Used when `transOut` is null
     */
	public static var defaultTransOut:Class<TransitionSubState> = null;

	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;

	/**
     * Intro transition to use after switching to this state
     */
	public var transIn:Class<TransitionSubState>;

	/**
     * Outro transition to use before switching to another state
     */
	public var transOut:Class<TransitionSubState>;

	public var hasTransIn(get, never):Bool;
	public var hasTransOut(get, never):Bool;

	public static var overrideSubState:Bool = true; // this is here because fnf jank sovl.

	/**
	 * Create a state with the ability to do visual transitions
	 */
	public function new() {
		this.transIn = defaultTransIn;
		this.transOut = defaultTransOut;

		super();
	}

	public static function setDefaultTransitions(inClass:Class<TransitionSubState>, ?outClass:Class<TransitionSubState>):Void {
		defaultTransIn = inClass;
		defaultTransOut = outClass ?? inClass;
	}

	public static function resetDefaultTransitions():Void {
		setDefaultTransitions(FadeTransition);
	}

	override function createPost():Void {
		super.createPost();
		transitionIn();
	}

    override function startOutro(onOutroComplete:Void->Void):Void {
        _exiting = true;
        transitionOut(onOutroComplete);
    
        if(skipNextTransOut) {
            skipNextTransOut = false;
            _finishTransOut();
        }
    }

	/**
	 * Starts the in-transition. Can be called manually at any time.
	 */
	public function transitionIn(?OnEnter:Void->Void):Void {
		_onEnter = OnEnter;

		if(skipNextTransIn || !hasTransIn) {
			skipNextTransIn = false;
			_finishTransIn();
			return;
		}
		var trans:TransitionSubState = Type.createInstance(transIn, []);
		if(overrideSubState)
			openSubState(trans);
		else {
			var state:FlxState = this;
			while(state.subState != null)
				state = state.subState;
			
			state.openSubState(trans);
		}
		trans.finishCallback = _finishTransIn;
		trans.start(IN);

		overrideSubState = true;
	}

	/**
	 * Starts the out-transition. Can be called manually at any time.
	 */
	public function transitionOut(?OnExit:Void->Void):Void {
		_onExit = OnExit;

		if(hasTransOut) {
			var trans:TransitionSubState = Type.createInstance(transIn, []);
			if(overrideSubState)
				openSubState(trans);
			else {
				var state:FlxState = this;
				while(state.subState != null)
					state = state.subState;

				state.openSubState(trans);
			}
			trans.finishCallback = _finishTransOut;
			trans.start(OUT);
		} else
			_onExit();

		overrideSubState = true;
	}

    //----------- [ Private API ] -----------//

    private var _transOutFinished:Bool = false;

	private var _exiting:Bool = false;
	private var _onExit:Void->Void;
	private var _onEnter:Void->Void;

	private function get_hasTransIn():Bool {
		return transIn != null;
	}

	private function get_hasTransOut():Bool {
		return transOut != null;
	}

	private function _finishTransIn():Void {
		closeSubState();

		if(_onEnter != null)
			_onEnter();
	}

	private function _finishTransOut():Void {
		_transOutFinished = true;

		if(!_exiting)
			closeSubState();

		if(_onExit != null)
			_onExit();
	}

    override function destroy():Void {
		super.destroy();
		transIn = null;
		transOut = null;
		_onExit = null;
		_onEnter = null;
	}
}
