package funkin.ui.options.pages;

import funkin.states.menus.OffsetCalibrationState;

class GameplayPage extends OptionPage {
    public function new() {
        super("Gameplay");
    }

    override function initOptions():Void {
        addOption({
            name: "Downscroll",
            description: "Scrolls the notes downwards instead of upwards.",

            id: "downscroll",
            type: TCheckbox
        });
        addOption({
            name: "Centered Notes",
            description: "Puts the player notes in the center of the screen\nand hides the opponent notes.",

            id: "centeredNotes",
            type: TCheckbox
        });
        addOption({
            name: "Use Killers",
            description: "Changes whether or not killers are used\nfor judging notes during gameplay.",

            id: "useKillers",
            type: TCheckbox
        });
        addOption({
            name: "Miss Sounds",
            description: "Changes whether or not miss sounds are played during gameplay.",

            id: "missSounds",
            type: TCheckbox
        });
        final songOffsetOption:Option = addOption({
            name: "Song Offset",
            description: "Changes how offset the music is from notes (in MS).\nMainly useful for headphones with lots of latency.\n\nPress ACCEPT to start calibrating offsets\ninstead of manually inputting them.",

            id: "songOffset",
            type: TInt(-5000, 5000, 5)
        });
        songOffsetOption.acceptCallback = () -> {
            if(FlxG.sound.music != null && FlxG.sound.music.playing) {
                FlxG.sound.music.fadeOut(0.16, 0, (_) -> {
                    FlxG.sound.music.pause();
                });
            }
            FlxG.switchState(OffsetCalibrationState.new);
        };
        addOption({
            name: "Hit Window",
            description: "Changes how early and late you can hit notes (in MS).",

            id: "hitWindow",
            type: TInt(5, 180, 5)
        });
        #if mobile
        addOption({
            name: "Control Scheme",
            description: "Change the control scheme you prefer to use during gameplay.\nThese will get disabled if a keyboard or gamepad are detected.",

            id: "controlScheme",
            type: TList(["Arrows", "Hitbox", "Invisible Hitbox"])
        });
        #end
        final hitsoundTypeOption:ListOption = cast addOption({
            name: "Hitsound Type",
            description: "Change the kind of hitsounds to use during gameplay.",

            id: "hitsoundType",
            type: TList(["osu!", "tump"])
        });
        hitsoundTypeOption.updateValue = (value:Dynamic) -> {
            hitsoundTypeOption.valueText.text = Std.string(value);
            FlxG.sound.play(Options.getHitsoundPath());
        };
        addOption({
            name: "Hitsound Behavior",
            description: "Changes how the hitsounds behave during gameplay.",

            id: "hitsoundBehavior",
            type: TList(["Note Hit", "Key Press"])
        });
        final hitsoundVolumeOption:PercentOption = cast addOption({
            name: "Hitsound Volume",
            description: "Changes how loud the hitsounds are during gameplay.",

            id: "hitsoundVolume",
            type: TPercent
        });
        hitsoundVolumeOption.updateValue = (value:Dynamic) -> {
            hitsoundVolumeOption.valueText.text = '${Math.floor(value * 100)}%';
            FlxG.sound.play(Options.getHitsoundPath(), cast value);
        };
        super.initOptions();
    }
}