package funkin.utilities;

import flixel.util.FlxDestroyUtil;

class ArrayUtil {
    /**
     * Removes all items from a given array, alongside
     * optionally destroying said items if possible.
     * 
     * @param  arr           The array to clear.
     * @param  destroyItems  Whether or not to destroy the items within the array.
     */
    public static inline function clear<T>(arr:Array<T>, ?destroyItems:Bool = false):Void {
        if(arr == null || arr.length == 0)
            return;

        if(destroyItems) {
            for(i in 0...arr.length) {
                final item:T = arr[i];
                if(item != null && item is IFlxDestroyable) {
                    final destroyableItem:IFlxDestroyable = cast item;
                    destroyableItem.destroy();
                }
            }
        }
        arr.resize(0);
    }

    /**
     * Returns whether or not an array is empty.
     * 
     * @param  arr  The array to check.
     */
    public static inline function isEmpty<T>(arr:Array<T>):Bool {
        return arr == null || arr.length == 0;
    }
}