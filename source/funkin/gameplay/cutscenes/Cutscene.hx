package funkin.gameplay.cutscenes;

import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.states.PlayState;

class Cutscene extends FlxContainer {
    public var canRestart:Bool = false;

    /**
     * The signal that will be dispatched when the cutscene is finished.
     */
    public var onFinish:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    /**
     * Starts the cutscene.
     * 
     * This is mainly what initializes the cutscene, if you are
     * looking to restart the cutscene, look at `restart()` instead.
     */
    public function start():Void {
        final game:PlayState = PlayState.instance;
        game.inCutscene = true;
    }

    /**
     * Pauses the cutscene.
     * 
     * This is mainly useful if you're running things that
     * aren't necessarily attached to gameplay, but instead are always running,
     * such as video playback.
     */
    public function pause():Void {}

    /**
     * Resumes the cutscene.
     * 
     * This is mainly useful if you're running things that
     * aren't necessarily attached to gameplay, but instead are always running,
     * such as video playback.
     */
    public function resume():Void {}

    /**
     * Restarts the cutscene.
     * 
     * This IS different from simply starting the cutscene, as starting
     * is usually where initialization stuff goes, and we don't wanna
     * initialize the cutscene twice!
     * 
     * So we have to *restart* the cutscene instead, which usually
     * just rewinds it back to the beginning.
     * 
     * Restarting is disabled for scripted cutscenes by default, but can
     * be re-enabled by doing `canRestart = true;` within the `onStart` function.
     * Do be warned that you will have to handle restarting yourself for
     * scripted cutscenes!
     */
    public function restart():Void {
        final game:PlayState = PlayState.instance;
        game.inCutscene = true;
    }

    /**
     * Finishes the cutscene immediately.
     */
    public function finish():Void {
        final game:PlayState = PlayState.instance;
        game.inCutscene = false;

        if(onFinish != null)
            onFinish.dispatch();

        if(container != null)
            container.remove(this, true);

        destroy();
    }
}