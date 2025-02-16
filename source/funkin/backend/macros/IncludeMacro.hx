package funkin.backend.macros;

import haxe.macro.*;

class IncludeMacro {
    /**
     * Makes sure a bunch of extra classes get compiled into the
     * executable file, for scripting purposes.
     */
    public static function build() {
        #if macro
        final includes:Array<String> = [
			// FLIXEL
			"flixel.util", "flixel.ui", "flixel.tweens", "flixel.tile", "flixel.text",
			"flixel.system", "flixel.sound", "flixel.path", "flixel.math", "flixel.input",
			"flixel.group", "flixel.graphics", "flixel.effects", "flixel.animation",
			
            // FLIXEL ADDONS
			"flixel.addons.api", "flixel.addons.display", "flixel.addons.effects", "flixel.addons.ui",
			"flixel.addons.plugin", "flixel.addons.text", "flixel.addons.tile", "flixel.addons.transition",
			"flixel.addons.util",

			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern",

            // HAXEUI,
            "haxe.ui",

            // FUNKIN
            "funkin",

			// LET'S GO GAMBLING!
			"sys"
		];
        final ignores:Array<String> = [
            // HAXEUI
            "haxe.ui.macros",

            // FLIXEL
            "flixel.system.macros"
        ];
        for(inc in includes)
			Compiler.include(inc, true, ignores);
        #end
    }
}