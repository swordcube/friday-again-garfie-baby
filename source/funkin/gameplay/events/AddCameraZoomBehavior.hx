package funkin.gameplay.events;

import funkin.backend.events.GameplayEvents;

class AddCameraZoomBehavior extends EventBehavior {
    public function new() {
        super("Add Camera Zoom");
    }

    override function execute(e:SongEvent) {
        final params:AddCameraZoomParams = cast e.params;
        final cam:String = params.camera.toLowerCase();
        
        if(cam == "hud" || cam == "camhud")
            game.camHUD.extraZoom += params.zoom;
        else
            game.camGame.extraZoom += params.zoom;
    }
}

typedef AddCameraZoomParams = {
    var zoom:Float; // 0 = opponent, 1 = player, 2 = spectator
    var camera:String; // game/camGame, hud/camHUD
}