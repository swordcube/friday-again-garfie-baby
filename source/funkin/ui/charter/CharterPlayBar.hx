package funkin.ui.charter;

import flixel.text.FlxText;
import flixel.util.FlxStringUtil;

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

    public var songTimeText:FlxText;
    public var songLengthText:FlxText;

    public var bpmText:FlxText;
    public var timeSigText:FlxText;

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

        songTimeText = new FlxText(12, 0, 0, "0:00");
        songTimeText.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        songTimeText.y = (bg.height - songTimeText.height) * 0.5;
        add(songTimeText);

        songLengthText = new FlxText(12, 0, 0, ' / ${FlxStringUtil.formatTime(charter.inst.length / 1000)}');
        songLengthText.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
        songLengthText.y = (bg.height - songLengthText.height) * 0.5;
        songLengthText.alpha = 0.45;
        add(songLengthText);

        bpmText = new FlxText(12, 0, 0, '0 BPM');
        bpmText.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
        bpmText.y = (bg.height - bpmText.height) * 0.5;
        add(bpmText);

        timeSigText = new FlxText(12, 0, 0, ' [4/4]');
        timeSigText.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
        timeSigText.y = (bg.height - timeSigText.height) * 0.5;
        timeSigText.alpha = 0.45;
        add(timeSigText);
    }

    override function update(elapsed:Float) {
        songSlider.value = Conductor.instance.time;

        songTimeText.text = FlxStringUtil.formatTime(Conductor.instance.time / 1000);
        songLengthText.x = songTimeText.x + (songTimeText.width - 2);

        timeSigText.text = ' [${Conductor.instance.timeSignature.getNumerator()}/${Conductor.instance.timeSignature.getDenominator()}]';
        timeSigText.x = FlxG.width - (timeSigText.width + 12);

        bpmText.text = '${Conductor.instance.bpm} BPM';
        bpmText.x = timeSigText.x - (bpmText.width - 2);

        super.update(elapsed);
    }
}