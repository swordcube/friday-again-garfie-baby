package funkin.utilities;

import haxe.Serializer;
import haxe.Unserializer;

import haxe.io.Bytes;
import thx.semver.Version;

/**
 * Functions dedicated to serializing and deserializing data.
 * NOTE: Use `json2object` wherever possible, it's way more efficient.
 * 
 * @see https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/SerializerUtil.hx
 */
class SerializerUtil {
	public static final INDENT_CHAR = "\t";

	/**
	 * Convert a Haxe object to a JSON string.
     * 
	 * NOTE: Use `json2object.JsonWriter<T>` when possible, Do not use
     * this one unless you absolutely, since it's way slower!!
     * 
	 * You should also be using `haxe.Json.stringify` with the custom replacer!
	 */
	public static function toJSON(input:Dynamic, pretty:Bool = true):String {
		return Json.stringify(input, replacer, pretty ? INDENT_CHAR : null);
	}

	/**
	 * Convert a JSON string to a Haxe object.
	 */
	public static function fromJSON(input:String):Dynamic {
		try {
			return Json.parse(input);
		} catch (e) {
			trace('An error occurred while parsing JSON from string data');
			trace(e);
			return null;
		}
	}

	/**
	 * Convert a JSON byte array to a Haxe object.
	 */
	public static function fromJSONBytes(input:Bytes):Dynamic {
		try {
			return Json.parse(input.toString());
		} catch (e:Dynamic) {
			trace('An error occurred while parsing JSON from byte data');
			trace(e);
			return null;
		}
	}

	/**
	 * Serialize a Haxe object using the built-in Serializer.
	 * @param input The object to serialize
	 * @return The serialized object as a string
	 */
	public static function fromHaxeObject(input:Dynamic):String {
		return Serializer.run(input);
	}

	/**
	 * Convert a serialized Haxe object back into a Haxe object.
	 * @param input The serialized object as a string
	 * @return The deserialized object
	 */
	public static function toHaxeObject(input:String):Dynamic {
		return Unserializer.run(input);
	}

	/**
	 * Customize how certain types are serialized when converting to JSON.
	 */
	static function replacer(key:String, value:Dynamic):Dynamic {
		// Hacky because you can't use `isOfType` on a struct.
		if(key == "version") {
			if(value is String)
				return value;

			// Stringify Version objects.
			return serializeVersion(cast value);
		}
		// Else, return the value as-is.
		return value;
	}

	static inline function serializeVersion(value:Version):String {
		var result:String = '${value.major}.${value.minor}.${value.patch}';
		if(value.hasPre)
			result += '-${value.pre}';
		
		if(value.build.length > 0)
			result += '+${value.build}';

		return result;
	}
}