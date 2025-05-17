package funkin.gameplay.cutscenes;

#if SCRIPTING_ALLOWED
import funkin.states.PlayState;

class ScriptedSongCutscene extends ScriptedCutscene {
    public function new(?name:String, ?mix:String, ?loaderID:String) {
        final game:PlayState = PlayState.instance;
        final possiblePaths:Array<String> = [
            Paths.script('gameplay/songs/${game.currentSong}/cutscenes/${name ?? "cutscene"}', loaderID, loaderID == null),
            Paths.script('gameplay/songs/${game.currentSong}/${mix ?? "default"}/cutscenes/${name ?? "cutscene"}', loaderID, loaderID == null),
        ];
        for(path in possiblePaths) {
            if(FlxG.assets.exists(path)) {
                scriptPath = path;
                break;
            }
        }
        super(null);
    }
}
#end