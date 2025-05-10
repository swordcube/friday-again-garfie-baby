package funkin.ui;

import flixel.FlxSprite;
import funkin.ui.AtlasFont;
import funkin.substates.FunkinSubState;

enum ButtonStyle {
	Ok;
	YesNo;
	Custom(yes:String, no:Null<String>); // TODO: more than 2
	None;
}

/**
 * Opens a yes/no dialog box as a substate over the current state.
 */
class Prompt extends FunkinSubState {
	private static inline var MARGIN = 100;

	public var onYes:Void->Void;
	public var onNo:Void->Void;
    public var curSelected:Int = 0;

	public var buttons:FlxTypedGroup<PromptButton>;
	public var field:AtlasText;
	public var back:FlxSprite;

	var style:ButtonStyle;

	public function new(text:String, style:ButtonStyle = Ok) {
		this.style = style;
		super(0x80000000);

		buttons = new FlxTypedGroup<PromptButton>();

		field = new AtlasText(0, 0, "bold", CENTER, text);
		field.scrollFactor.set(0, 0);
	}

	override function create() {
		super.create();

		field.y = MARGIN;
		field.screenCenter(X);
		add(field);

		_createButtons();
		add(buttons);

        changeSelection(0, true);
	}

    override function update(elapsed:Float) {
        super.update(elapsed);
        if(buttons.length > 1) {
            if(controls.justPressed.UI_LEFT)
                changeSelection(-1);
    
            if(controls.justPressed.UI_RIGHT)
                changeSelection(1);

            if(controls.justPressed.BACK) {
                if(onNo != null)
                    onNo();
            }
            if(controls.justPressed.ACCEPT)
                buttons.members[curSelected].callback();
        }
    }

	public function createBG(width:Int, height:Int, color = 0xFF808080) {
		back = new FlxSprite();
		back.makeSolid(width, height, color);
		back.screenCenter(XY);
		add(back);
		members.unshift(members.pop()); // bring to front
	}

	public function createBGFromMargin(margin = MARGIN, color = 0xFF808080) {
		createBG(Std.int(FlxG.width - margin * 2), Std.int(FlxG.height - margin * 2), color);
	}

    public function closePrompt():Void {
        if(_parentState != null) // not in substate
            close();
        else {
            container.remove(this, true);
            destroy();
        }
    }

	public function setButtons(style:ButtonStyle) {
		if (this.style != style) {
			this.style = style;
			_createButtons();
		}
	}

    public function setText(text:String) {
		field.text = text;
		field.screenCenter(X);
	}

    public function changeSelection(by:Int = 0, ?force:Bool = false):Void {
        if(by == 0 && !force)
            return;

        curSelected = (buttons.length < 2) ? buttons.length - 1 : FlxMath.wrap(curSelected + by, 0, buttons.length - 1);
        for(i => button in buttons.members) {
            if(curSelected == i)
                button.alpha = 1;
            else
                button.alpha = 0.6;
        }
        FlxG.sound.play(Paths.sound("menus/sfx/scroll"));
    }

	private function _createButtons():Void {
		// destroy previous buttons
		while(buttons.length > 0) {
            final button = buttons.members.unsafeFirst();
			buttons.remove(button, true);
            button.destroy();
		}
		switch (style) {
			case YesNo:
				_createButtonsHelper("yes", "no");
			case Ok:
				_createButtonsHelper("ok");
			case Custom(yes, no):
				_createButtonsHelper(yes, no);
			case None:
				buttons.exists = false;
		};
	}

	private function _createButtonsHelper(yes:String, ?no:String):Void {
		buttons.exists = true;

		// pass anonymous functions rather than the current callbacks, in case they change later
		var yesButton = new PromptButton(yes, () -> {
            if(onYes != null)
                onYes();
        });
		yesButton.screenCenter(X);
		yesButton.y = FlxG.height - yesButton.height - (MARGIN * 2);
		yesButton.scrollFactor.set(0, 0);
        buttons.add(yesButton);

		if (no != null) {
			yesButton.x = MARGIN * 2;

			var noButton = new PromptButton(no, () -> {
                if(onNo != null)
                    onNo();
            });
			noButton.x = FlxG.width - noButton.width - (MARGIN * 2);
			noButton.y = FlxG.height - noButton.height - (MARGIN * 2);
			noButton.scrollFactor.set(0, 0);
            buttons.add(noButton);
		}
	}
}

class PromptButton extends AtlasText {
    public var callback:Void->Void;

    public function new(text:String, callback:Void->Void) {
        super(0, 0, "bold", CENTER, text);
        this.callback = callback;
    }
}