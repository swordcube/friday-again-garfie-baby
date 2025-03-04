package funkin.ui.charter;

import funkin.ui.topbar.*;
import funkin.ui.dropdown.DropDownItemType;

import funkin.states.editors.ChartEditor;

class CharterTopBar extends TopBar {
    public var charter(default, null):ChartEditor;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        charter = cast FlxG.state;
    }

    public function updateLeftSideItems():Void {
        final noteTypeItems:Array<DropDownItemType> = [];
        for(i in 0...charter.noteTypes.length)
            noteTypeItems.push(Button('(${i}) ${charter.noteTypes[i]}', null, () -> {trace('${charter.noteTypes[i]} NOT IMPLEMENTED!!');}));
        
        final vocalItems:Array<DropDownItemType> = [];
        if(charter.vocals.spectator != null)
            vocalItems.push(Checkbox("Mute spectator vocals", (value:Bool) -> charter.toggleSpectatorVocals(value), () -> return ChartEditor.editorSettings.muteSpectatorVocals));
        
        if(charter.vocals.opponent != null)
            vocalItems.push(Checkbox("Mute opponent vocals", (value:Bool) -> charter.toggleOpponentVocals(value), () -> return ChartEditor.editorSettings.muteOpponentVocals));
        
        if(charter.vocals.player != null)
            vocalItems.push(Checkbox("Mute player vocals", (value:Bool) -> charter.togglePlayerVocals(value), () -> return ChartEditor.editorSettings.mutePlayerVocals));

        if(vocalItems.length != 0)
            vocalItems.insert(0, Separator);

        leftItems = [
            DropDown("File", [
                Button("New", [CONTROL, N], () -> {trace("new NOT IMPLEMENTED!!");}),
                
                Separator,

                Button("Open", [CONTROL, O], () -> {trace("open NOT IMPLEMENTED!!");}),
                Button("Save", [CONTROL, S], () -> {trace("save NOT IMPLEMENTED!!");}),
                
                Separator,
                
                Button("Save Chart As", [CONTROL, SHIFT, S], () -> {trace("save chart as NOT IMPLEMENTED!!");}),
                Button("Save Meta As", [CONTROL, ALT, SHIFT, S], () -> {trace("save meta as NOT IMPLEMENTED!!");}),
                
                Separator,

                Button("Convert Chart", [CONTROL, SHIFT, C], () -> {trace("convert chart NOT IMPLEMENTED!!");}),

                Separator,

                Button("Exit", null, () -> {trace("exit NOT IMPLEMENTED!!");})
            ]),
            DropDown("Edit", [
                Button("Undo", [CONTROL, Z], () -> {trace("undo NOT IMPLEMENTED!!");}),
                Button("Redo", [CONTROL, Y], () -> {trace("redo NOT IMPLEMENTED!!");}),
                
                Separator,
                
                Button("Copy", [CONTROL, C], () -> {trace("copy NOT IMPLEMENTED!!");}),
                Button("Paste", [CONTROL, V], () -> {trace("paste NOT IMPLEMENTED!!");}),
                
                Separator,
                
                Button("Cut", [CONTROL, X], () -> {trace("cut NOT IMPLEMENTED!!");}),
                Button("Delete", [DELETE], () -> charter.deleteObjects(charter.selectedObjects))
            ]),
            DropDown("Chart", [
                Button("Playtest", [ENTER], () -> charter.playTest()),
                Button("Playtest here", [SHIFT, ENTER], () -> {trace("playtest here NOT IMPLEMENTED!!");}),

                Separator,

                Button("Edit chart metadata", null, () -> {trace("edit chart metadata NOT IMPLEMENTED!!");})
            ]),
            DropDown("View", [
                Button("Zoom In", [CONTROL, NUMPADPLUS], () -> charter.zoomIn()),
                Button("Zoom Out", [CONTROL, NUMPADMINUS], () -> charter.zoomOut()),
                Button("Reset Zoom", [CONTROL, NUMPADZERO], () -> charter.resetZoom())
            ]),
            DropDown("Song", [
                Button("Go back to the start", [HOME], () -> charter.goBackToStart()),
                Button("Go to the end", [END], () -> charter.goToEnd()),

                Separator,
                
                Checkbox("Mute instrumental", (value:Bool) -> charter.toggleInstrumental(value), () -> return ChartEditor.editorSettings.muteInstrumental),
                Checkbox("Mute all vocals", (value:Bool) -> charter.toggleAllVocals(value), () -> return ChartEditor.editorSettings.muteAllVocals),
            ].concat(vocalItems)),
            DropDown("Note", [
                Button("Add sustain length", [E], () -> charter.addSustainLength(charter.selectedObjects)),
                Button("Subtract sustain length", [Q], () -> charter.subtractSustainLength(charter.selectedObjects)),
                
                Separator,
                
                Button("Select all", [CONTROL, A], () -> {trace("select all NOT IMPLEMENTED!!");}),
                Button("Select measure", [CONTROL, SHIFT, A], () -> {trace("select measure NOT IMPLEMENTED!!");}),
                
                Separator,
            ].concat(noteTypeItems))
        ];
    }

    public function updateRightSideItems():Void {
        rightItems = [
            DropDown("Snap >", [
                Button("+ Grid Snap", [X], () -> charter.increaseGridSnap()),
                Button("Reset Grid Snap", null, () -> charter.setGridSnap(16)),
                Button("- Grid Snap", [Z], () -> charter.decreaseGridSnap()),

                Separator,

                Checkbox("4x Grid Snap", (value:Bool) -> charter.setGridSnap(4), () -> return ChartEditor.editorSettings.gridSnap == 4),
                Checkbox("8x Grid Snap", (value:Bool) -> charter.setGridSnap(8), () -> return ChartEditor.editorSettings.gridSnap == 8),
                Checkbox("12x Grid Snap", (value:Bool) -> charter.setGridSnap(12), () -> return ChartEditor.editorSettings.gridSnap == 12),
                Checkbox("16x Grid Snap", (value:Bool) -> charter.setGridSnap(16), () -> return ChartEditor.editorSettings.gridSnap == 16),
                Checkbox("20x Grid Snap", (value:Bool) -> charter.setGridSnap(20), () -> return ChartEditor.editorSettings.gridSnap == 20),
                Checkbox("24x Grid Snap", (value:Bool) -> charter.setGridSnap(24), () -> return ChartEditor.editorSettings.gridSnap == 24),
                Checkbox("32x Grid Snap", (value:Bool) -> charter.setGridSnap(32), () -> return ChartEditor.editorSettings.gridSnap == 32),
                Checkbox("48x Grid Snap", (value:Bool) -> charter.setGridSnap(48), () -> return ChartEditor.editorSettings.gridSnap == 48),
                Checkbox("64x Grid Snap", (value:Bool) -> charter.setGridSnap(64), () -> return ChartEditor.editorSettings.gridSnap == 64),
                Checkbox("192x Grid Snap", (value:Bool) -> charter.setGridSnap(192), () -> return ChartEditor.editorSettings.gridSnap == 192),
            ]),
            Text('${ChartEditor.editorSettings.gridSnap}x'),
            DropDown("Playback >", [
                Button("Play/Pause", [SPACE], charter.playPause),
                
                Separator,

                Button("Go back a measure", [A], charter.goBackAMeasure),
                Button("Go forward a measure", [D], charter.goForwardAMeasure),
                
                Separator,

                Checkbox("Play opponent hitsounds", (value:Bool) -> ChartEditor.editorSettings.opponentHitsounds = value, () -> return ChartEditor.editorSettings.opponentHitsounds),
                Checkbox("Play player hitsounds", (value:Bool) -> ChartEditor.editorSettings.playerHitsounds = value, () -> return ChartEditor.editorSettings.playerHitsounds),

                Separator,

                Checkbox("Metronome", (value:Bool) -> charter.toggleMetronome(!ChartEditor.editorSettings.metronome), () -> return ChartEditor.editorSettings.metronome),
                Checkbox("Visual metronome", (value:Bool) -> {trace("visual metronome NOT IMPLEMENTED!!");})
            ]),
            Slider(0.25, 3, 0.01, 1, 130, (value:Float) -> {trace("playback slider NOT IMPLEMENTED!!");})
        ];
    }
}