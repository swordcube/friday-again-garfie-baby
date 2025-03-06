package funkin.ui.charter;

import funkin.ui.slider.HorizontalSlider;

import funkin.states.editors.ChartEditor;

class CharterPlayBar extends UIComponent {
    public var charter(default, null):ChartEditor;

    public var bg:FlxSprite;
    public var songSlider:HorizontalSlider;

    public var buttons:FlxSpriteContainer;

    public var goBackToStartButton:Button;
    public var goBackAMeasureButton:Button;

    public var playPauseButton:Button;

    public var goForwardAMeasureButton:Button;
    public var goToEndButton:Button;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        charter = cast FlxG.state;

        bg = new FlxSprite(0, 0).loadGraphic(Paths.image("ui/images/bottom_bar_big"));
        bg.setGraphicSize(FlxG.width, bg.frameHeight);
        bg.updateHitbox();
        add(bg);

        songSlider = new HorizontalSlider(0, 0, FlxG.width);
        songSlider.y = bg.y - songSlider.middle.height;
        songSlider.max = charter.inst.length;
        songSlider.callback = (value:Float) -> {
            charter.seekToTime(value);
        };
        add(songSlider);

        buttons = new FlxSpriteContainer();
        add(buttons);

        goBackToStartButton = new Button(0, 0, null, 34, 26);
        goBackToStartButton.icon = Paths.image("editors/charter/images/playbar/start");
        goBackToStartButton.y = bg.y + ((bg.height - goBackToStartButton.height) * 0.5);
        goBackToStartButton.callback = () -> charter.goBackToStart();
        buttons.add(goBackToStartButton);
        
        goBackAMeasureButton = new Button(0, 0, null, 34, 26);
        goBackAMeasureButton.icon = Paths.image("editors/charter/images/playbar/backward");
        goBackAMeasureButton.y = bg.y + ((bg.height - goBackAMeasureButton.height) * 0.5);
        goBackAMeasureButton.callback = () -> charter.goBackAMeasure();
        buttons.add(goBackAMeasureButton);

        playPauseButton = new Button(0, 0, null, 34, 26);
        playPauseButton.icon = Paths.image("editors/charter/images/playbar/play");
        playPauseButton.y = bg.y + ((bg.height - playPauseButton.height) * 0.5);
        playPauseButton.callback = () -> charter.playPause();
        buttons.add(playPauseButton);

        goForwardAMeasureButton = new Button(0, 0, null, 34, 26);
        goForwardAMeasureButton.icon = Paths.image("editors/charter/images/playbar/forward");
        goForwardAMeasureButton.y = bg.y + ((bg.height - goForwardAMeasureButton.height) * 0.5);
        goForwardAMeasureButton.callback = () -> charter.goForwardAMeasure();
        buttons.add(goForwardAMeasureButton);

        goToEndButton = new Button(0, 0, null, 34, 26);
        goToEndButton.icon = Paths.image("editors/charter/images/playbar/end");
        goToEndButton.y = bg.y + ((bg.height - goToEndButton.height) * 0.5);
        goToEndButton.callback = () -> charter.goToEnd();
        buttons.add(goToEndButton);

        for(i in 0...buttons.length) {
            if(i == 0)
                buttons.members[i].x = 0;
            else
                buttons.members[i].x = buttons.members[i - 1].x + buttons.members[i - 1].width + 10;
        }
        buttons.screenCenter(X);
    }

    override function update(elapsed:Float) {
        songSlider.value = charter.inst.time;
        super.update(elapsed);
    }
}