package funkin.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;

import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

import funkin.ui.AtlasFont.AtlasFontGlyph;

enum abstract AtlasTextAlignment(String) from String to String {
    final LEFT = "LEFT";
    final CENTER = "CENTER";
    final RIGHT = "RIGHT";
}

class AtlasText extends FlxTypedSpriteGroup<FlxSpriteGroup> {
	public var font(default, set):String;
	public var fontData:AtlasFont;

	public var text(default, set):String;
	public var alignment(default, set):AtlasTextAlignment;

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;

	public function new(x:Float, y:Float, font:String, alignment:AtlasTextAlignment, text:String) {
		super(x, y);

		this.font = font;
		this.text = text;
		this.alignment = alignment;

		directAlpha = true;
	}

	public static function loadFontData(name:String):AtlasFont {
        final parser:JsonParser<AtlasFont> = new JsonParser<AtlasFont>();
        parser.ignoreUnknownVariables = true;
        return parser.fromJson(FlxG.assets.getText(Paths.json('fonts/alphabet/${name}/config')));
	}

	override public function update(elapsed:Float):Void {
		if (isMenuItem) {
			var lerpRatio:Float = elapsed * 9.6;
			x = FlxMath.lerp(x, (targetY * 20) + 90, lerpRatio);
			y = FlxMath.lerp(y, (targetY * 156) + (FlxG.height * 0.45), lerpRatio);
		}
		super.update(elapsed);
	}

    //----------- [ Private API ] -----------//

	private function set_font(font:String):String {
		font = (font != null) ? font : "default";
		if (this.font == font)
			return this.font;

		this.font = font;
		fontData = loadFontData(this.font);

		if (length == 0)
			return this.font;

		_regenGlyphs();
		_updateAlignment(alignment);

        return this.font;
	}

	private function set_text(text:String):String {
		var lastText:String = this.text;
		this.text = text;

		if (this.text == lastText)
			return text;

		_regenGlyphs();
		_updateAlignment(alignment);

        return text;
	}

	private function set_alignment(alignment:AtlasTextAlignment):AtlasTextAlignment {
		var lastAlignment:AtlasTextAlignment = this.alignment;
		this.alignment = alignment;

		if (alignment == lastAlignment)
			return alignment;

		_updateAlignment(alignment);
        return alignment;
	}

	override function set_color(color:FlxColor):FlxColor {
        for (line in members) {
            for (glyph in line.members)
				glyph.color = color;
		}
        return super.set_color(color);
	}

	private function _regenGlyphs():Void {
		while (members.length > 0) {
			var actor:FlxSpriteGroup = members[0];
            actor.destroy();
			remove(actor, true);
		}

		var textLength:Int = text.length;
		if (textLength == 0)
			return;

		var glyphX:Float = 0.0;
		var glyphY:Float = 0.0;

		var line:FlxSpriteGroup = new FlxSpriteGroup();
		line.directAlpha = true;

		for (i in 0...textLength) {
			var char:String = text.charAt(i);
			if (char == "\n") {
				add(line);
				line = new FlxSpriteGroup();

				glyphX = 0.0;
				glyphY += fontData.lineHeight * fontData.scale;
				continue;
			}

			var glyph:Glyph = new Glyph(glyphX, glyphY, this, char);
			glyph.scale.set(fontData.scale, fontData.scale);
            glyph.updateHitbox();
			glyph.updateOffset();
			glyph.color = color;
			glyph.alpha = alpha;
			line.add(glyph);

			var glyphData:AtlasFontGlyph = fontData.glyphs[char];
			if (glyphData != null && glyphData.visible == false)
				glyphX += glyphData.width * fontData.scale;
			else
				glyphX += glyph.width;
		}
		if (!members.contains(line))
			add(line);
	}

	private function _updateAlignment(alignment:AtlasTextAlignment):Void {
		var totalWidth:Float = width;
		for (line in members) {
			switch (alignment) {
				case LEFT:
					line.x = x;

				case CENTER:
					line.x = x + ((totalWidth - line.width) * 0.5);

				case RIGHT:
					line.x = x + (totalWidth - line.width);
			}
		}
	}
}

class Glyph extends FlxSprite {
    public static final allLetters:Array<String> = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    ];

    public var parent:AtlasText; // Reference to the parent AtlasText
    public var character:String; // The character this glyph represents

    public function new(x:Float, y:Float, parent:AtlasText, character:String) {
        super(x, y);

        this.parent = parent;
        this.character = character;

        final fontData:AtlasFont = parent.fontData;

        // Handle uppercase if noLowerCase is true
        if (fontData.noLowerCase)
            character = character.toUpperCase();

        // Load the sparrow atlas for the font
        // TODO: support more than just sparrow
        frames = Paths.getSparrowAtlas('fonts/alphabet/${parent.font}/${fontData.atlas.path}');

        var prefix:String = character + "0";

        // Handle lowercase/capital prefixes if noLowerCase is false
        if (!fontData.noLowerCase && allLetters.contains(character.toUpperCase())) {
            final lowercase:Bool = character.toUpperCase() != character;
            prefix = (lowercase ? character.toLowerCase() + " lowercase" : character.toUpperCase() + " capital") + "0";
        }

        final glyphData:AtlasFontGlyph = fontData.glyphs[character];

        // If glyph is invisible, kill the sprite
        if (glyphData != null && glyphData.visible == false) {
            kill();
            return;
        }

        // Use custom prefix if defined in glyphData
        if (glyphData != null && glyphData.prefix != null)
            prefix = glyphData.prefix;

        // Add and play the animation
        animation.addByPrefix("idle", prefix, fontData.fps);

        if (animation.exists("idle"))
            animation.play("idle");
    }

    public function updateOffset():Void {
        final fontData:AtlasFont = parent.fontData;
        final glyphData:AtlasFontGlyph = fontData.glyphs[character];

        final fx:Float = fontData.offset.x;
        final fy:Float = fontData.offset.y;

        final ox:Float = (glyphData != null && glyphData.offset != null) ? glyphData.offset.x : 0.0;
        final oy:Float = ((glyphData != null && glyphData.offset != null) ? glyphData.offset.y : 0.0) - (110 - frameHeight);

        frameOffset.set(ox - fx, oy - fy);
    }
}