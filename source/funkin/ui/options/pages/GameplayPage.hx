package funkin.ui.options.pages;

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
        addOption({
            name: "Song Offset",
            description: "Changes how offset the music is from notes (in MS).\nMainly useful for headphones with lots of latency.",

            id: "songOffset",
            type: TInt(-5000, 5000, 5)
        });
        addOption({
            name: "Hit Window",
            description: "Changes how early and late you can hit notes (in MS).",

            id: "hitWindow",
            type: TInt(5, 180, 5)
        });
    }
}