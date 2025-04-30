package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"funkin",
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"flixel",
		"openfl",

		"haxe.xml",
		"haxe.CallStack",
        
		"funkin",
	];

	// Runs support for using in specific classes. 
	public static final ALLOWED_USING = [

	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [

	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"funkin.gameplay.character.Character.AnimationContext"
	];

	public static final DISALLOW_USING = [

	];
}