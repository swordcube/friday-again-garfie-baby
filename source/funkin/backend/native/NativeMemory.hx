package funkin.backend.native;

#if cpp
import cpp.SizeT;
/**
 * Memory class to properly get accurate memory counts
 * for the program.
 * @author Leather128 (Haxe) - David Robert Nadeau (Original C Header)
 */
@:buildXml('<include name="../../../vendor/memory/build.xml" />')
@:include("memory.h")
extern class NativeMemory {
	/**
	 * Returns the peak (maximum so far) resident set size (physical
	 * memory use) measured in bytes, or zero if the value cannot be
	 * determined on this OS.
	 */
	@:native("getPeakRSS")
	public static function getPeakUsage():SizeT;

	/**
 	 * Returns the current resident set size (physical memory use) measured
 	 * in bytes, or zero if the value cannot be determined on this OS.
	 */
	@:native("getCurrentRSS")
	public static function getCurrentUsage():SizeT;
}
#else
/**
 * If you are not running on a CPP Platform, the code just will not work properly, sorry!
 * @author Leather128
 */
class NativeMemory {
	/**
	 * (Non cpp platform)
	 * Returns 0.
	 */
	public static function getPeakUsage():Float return 0.0;

	/**
	 * (Non cpp platform)
	 * Returns 0.
	 */
	public static function getCurrentUsage():Float return 0.0;
}
#end