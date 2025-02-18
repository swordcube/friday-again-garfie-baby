package funkin.utilities;

import hxjsonast.Json;
import hxjsonast.Json.JObjectField;
import hxjsonast.Tools as JsonTools;

class DataParse {
	public static function dynamicValue(json:Json, name:String):Dynamic {
		return JsonTools.getValue(json);
	}
}
