package funkin.states;

import flixel.FlxState;
import flixel.FlxSubState;

import funkin.substates.transition.TransitionSubState;

// i did not feel like coding all of this entirely on my own
// so i stole code! (the original source is in the @see part of the documentation)

// might do it later for more flexability in scripts
// but this will do for now

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

	/**
	 * Create a state with the ability to do visual transitions
	 */
	public function new() {
		this.transIn = defaultTransIn;
		this.transOut = defaultTransOut;

		super();
	}

	override function create():Void {
		super.create();
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
		var trans = Type.createInstance(transIn, []);
		openSubState(trans);

		trans.finishCallback = _finishTransIn;
		trans.start(OUT);
	}

	/**
	 * Starts the out-transition. Can be called manually at any time.
	 */
	public function transitionOut(?OnExit:Void->Void):Void {
		_onExit = OnExit;

		if(hasTransOut) {
			var trans = Type.createInstance(transOut, []);
			openSubState(trans);

			trans.finishCallback = _finishTransOut;
			trans.start(IN);
		} else
			_onExit();
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
