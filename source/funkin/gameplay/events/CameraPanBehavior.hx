package funkin.gameplay.events;

import funkin.backend.events.GameplayEvents;

class CameraPanBehavior extends EventBehavior {
    public function new() {
        super("Camera Pan");
    }

    override function execute(e:SongEvent) {
        super.execute(e);
        
        final params:CameraPanParams = cast e.params;
        game.curCameraTarget = params.char;

        #if SCRIPTING_ALLOWED
        scripts.call("onExecutePost", [e.flagAsPost()]);
        #end
    }
}

typedef CameraPanParams = {
    var char:Int; // 0 = opponent, 1 = player, 2 = spectator
}