package funkin.utilities;

import funkin.utilities.SerializerUtil;

class DataWrite {
	public static function dynamicValue(value:Dynamic):String {
		// Is this cheating? Yes. Do I care? No.
        // amazing comment EliteMasterEric 10/10
		return SerializerUtil.toJSON(value);
	}
}