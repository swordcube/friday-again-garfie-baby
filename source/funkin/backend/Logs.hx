package funkin.backend;

import haxe.Log;
import haxe.PosInfos;

import flixel.system.debug.log.LogStyle;
import flixel.system.frontEnds.LogFrontEnd;

import funkin.backend.native.NativeAPI;

/**
 * A class for displaying content to the console in a pretty fashion.
 */
class Logs {
	public static function init():Void {
		Log.trace = function(v:Dynamic, ?infos:Null<haxe.PosInfos>) {
			final data = [
				{
					fgColor: CYAN,
					text: '${infos.fileName}:${infos.lineNumber}: '
				},
				{
					text: Std.string(v)
				}
			];
			if(infos.customParams != null) {
				for (i in infos.customParams) {
					data.push({
						text: ", " + Std.string(i)
					});
				}
			}
			printChunks(prepareColoredTrace(data, TRACE));
		};
		LogStyle.NORMAL.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.NORMAL, d, pos));
		LogStyle.WARNING.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.WARNING, d, pos));
		LogStyle.ERROR.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.ERROR, d, pos));
		LogStyle.NOTICE.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.NOTICE, d, pos));
		LogStyle.CONSOLE.onLog.add((d:Any, ?pos:PosInfos) -> onLog(LogStyle.CONSOLE, d, pos));
	}

	public static function trace(text:String):Void {
		traceColored([{text: text}], TRACE);
	}

	public static function warn(text:String):Void {
		traceColored([
			{
				text: text,
				fgColor: YELLOW
			}
		], WARNING);
	}

	public static function error(text:String):Void {
		traceColored([
			{
				text: text,
				fgColor: RED
			}
		], ERROR);
	}

	public static function success(text:String):Void {
		traceColored([
			{
				text: text,
				fgColor: GREEN
			}
		], SUCCESS);
	}

	public static function verbose(text:String):Void {
		traceColored([{text: text}], VERBOSE);
	}

	public static function traceColored(chunks:Array<LogChunk>, ?level:LogLevel = TRACE):Void {
		printChunks(prepareColoredTrace(chunks, level));
	}

	public static function prepareColoredTrace(chunks:Array<LogChunk>, ?level:LogLevel = TRACE):Array<LogChunk> {
		final time:Date = Date.now();

		var hour:Int = time.getHours() % 12;
		if(hour == 0)
			hour = 12;

		final newChunks:Array<LogChunk> = [
			{
				text: "[ "
			},
			{fgColor: DARKMAGENTA,
				text: Std.string(hour).lpad("0", 2)
				+ ":"
				+ Std.string(time.getMinutes()).lpad("0", 2)
				+ ":"
				+ Std.string(time.getSeconds()).lpad("0", 2)},
			{
				text: " | "
			},
			switch (level) {
				case WARNING:
					{
						fgColor: YELLOW,
						text: "WARNING"
					}

				case ERROR:
					{
						fgColor: RED,
						text: " ERROR "
					}

				case SUCCESS:
					{
						fgColor: GREEN,
						text: "SUCCESS"
					}

				case VERBOSE:
					{
						fgColor: MAGENTA,
						text: "VERBOSE"
					}

				default:
					{
						fgColor: CYAN,
						text: " TRACE "
					}
			},
			{
				text: " ] "
			},
		];
		for (i in 0...newChunks.length) {
			final newChunk:LogChunk = newChunks[i];
			chunks.insert(i, newChunk);
		}
		return chunks;
	}

	public static function printChunks(chunks:Array<LogChunk>):Void {
		while (_showing)
			Sys.sleep(0.05);

		_showing = true;
		for (i in 0...chunks.length) {
			final chunk:LogChunk = chunks[i];
			NativeAPI.setConsoleColors(chunk.fgColor, chunk.bgColor);
			Sys.print(chunk.text);
		}
		NativeAPI.setConsoleColors();
		Sys.print("\r\n");
		_showing = false;
	}

	//----------- [ Private API ] -----------//

	private static var _showing:Bool = false;

	private static function onLog(Style:LogStyle, Data:Any, ?Pos:PosInfos):Void {
		var prefix:String = "[ FLIXEL ]";
		var level:LogLevel = TRACE;

		if(Style == LogStyle.CONSOLE) {
			prefix = "";
			level = TRACE;
		}
		if(Style == LogStyle.ERROR) {
			prefix = "[ FLIXEL ]";
			level = ERROR;
		}
		if(Style == LogStyle.NORMAL) {
			prefix = "[ FLIXEL ]";
			level = TRACE;
		}
		if(Style == LogStyle.NOTICE) {
			prefix = "[ FLIXEL ]";
			level = WARNING;
		}
		if(Style == LogStyle.WARNING) {
			prefix = "[ FLIXEL ]";
			level = WARNING;
		}

		var d:Dynamic = Data;
		if(!(d is Array))
			d = [d];

		var a:Array<Dynamic> = d;
		var strs = [for (e in a) Std.string(e)];
		for (e in strs) {
			Logs.traceColored([
				{
					text: '${prefix} ',
					fgColor: CYAN
				},
				{
					text: e
				}
			], level);
		}
	}
}

typedef LogChunk = {
	var ?bgColor:ConsoleColor;
	var ?fgColor:ConsoleColor;
	var text:String;
}

enum abstract LogLevel(Int) from Int to Int {
	var TRACE = 0;
	var WARNING = 1;
	var ERROR = 2;
	var SUCCESS = 3;
	var VERBOSE = 4;
}
