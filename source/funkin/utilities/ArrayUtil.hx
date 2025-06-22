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

    /**
     * Returns the value at the given index
     * from the given array.
     * 
     * @param  arr  The array to get the value from.
     */
    public static inline function unsafeGet<T>(arr:Array<T>, index:Int):T {
        #if cpp
        return cpp.NativeArray.unsafeGet(arr, index);
        #else
        return arr[index];
        #end
    }

    /**
     * Sets the value at the given index
     * on the given array to a given value.
     * 
     * @param  arr    The array to get the value from.
     * @param  index  The index to set the value at.
     * @param  value  The value to set.
     */
    public static inline function unsafeSet<T>(arr:Array<T>, index:Int, value:T):T {
        #if cpp
        return cpp.NativeArray.unsafeSet(arr, index, value);
        #else
        return arr[index] = value;
        #end
    }

    /**
     * Returns the first value of an array if it exists.
     * If the array is empty, `null` will be returned.
     * 
     * @param  arr  The array to get the first value from.
     */
    public static inline function first<T>(arr:Array<T>):T {
        return arr[0];
    }

    /**
     * Returns the first value of an array (unsafely).
     * If the array is empty, the game may crash.
     * 
     * @param  arr  The array to get the first value from.
     */
    public static inline function unsafeFirst<T>(arr:Array<T>):T {
        return unsafeGet(arr, 0);
    }

    /**
     * Returns the last value of an array if it exists.
     * If the array is empty, `null` will be returned.
     * 
     * @param  arr  The array to get the last value from.
     */
    public static inline function last<T>(arr:Array<T>):T {
        return arr[arr.length - 1];
    }

    /**
     * Returns the last value of an array (unsafely).
     * If the array is empty, the game may crash.
     * 
     * @param  arr  The array to get the last value from.
     */
    public static inline function unsafeLast<T>(arr:Array<T>):T {
        return unsafeGet(arr, arr.length - 1);
    }

    /**
     * Returns a random item from a given array.
     * 
     * Returns `null` if unsuccessful.
     * 
     * @param  array  The array to pick an item from.
     */
    public static function pickRandom<T>(array:Array<T>):T {
        return (array.length != 0) ? array.unsafeGet(FlxG.random.int(0, array.length - 1)) : null;
    }

    public static function removeDuplicates<T>(array:Array<T>):Array<T> {
        final l:Array<T> = [];
        for(v in array) {
         	if(!l.contains(v))
            	l.push(v);
        }
        return l;
    }
}
