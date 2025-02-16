package funkin.utilities;

import haxe.io.Path;

/**
 * @see https://github.com/ShadowMario/FNF-PsychEngine/pull/15536
 */
@:keep
class ALConfig {
	#if desktop
	static function __init__():Void {
		var configPath:String = Path.directory(Path.withoutExtension(#if hl Sys.getCwd() #else Sys.programPath() #end));

		#if windows
		configPath += "/plugins/alsoft.ini";
		#elseif mac
		configPath = Path.directory(configPath) + "/Resources/plugins/alsoft.conf";
		#elseif linux
		configPath += "/plugins/alsoft.conf";
		#end

		Sys.putEnv("ALSOFT_CONF", configPath);
	}
	#end
}
