package funkin.utilities;

class MathUtil {
	/**
	 * Get the base-2 exponent of a value.
	 * @param x value
	 * @return `2^x`
	 */
	public static function exp2(x:Float):Float {
		return Math.pow(2, x);
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpPrecision(base, target, deltaTime, halfLife, 0.5)`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param halfLife Time in seconds to reach halfway to `target`.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpDecay(base:Float, target:Float, deltaTime:Float, halfLife:Float):Float {
		if (deltaTime == 0)
			return base;

		if (base == target)
			return target;

		return FlxMath.lerp(target, base, exp2(-deltaTime / halfLife));
	}

	/**
	 * Exponential decay interpolation.
	 *
	 * Framerate-independent because the rate-of-change is proportional to the difference, so you can
	 * use the time elapsed since the last frame as `deltaTime` and the function will be consistent.
	 *
	 * Equivalent to `smoothLerpDecay(base, target, deltaTime, -duration / logBase(2, precision))`.
	 *
	 * @param base The starting or current value.
	 * @param target The value this function approaches.
	 * @param deltaTime The change in time along the function in seconds.
	 * @param duration Time in seconds to reach `target` within `precision`, relative to the original distance.
	 * @param precision Relative target precision of the interpolation. Defaults to 1% distance remaining.
	 *
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return The interpolated value.
	 */
	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float {
		if (deltaTime == 0)
			return base;

		if (base == target)
			return target;

		return FlxMath.lerp(target, base, Math.pow(precision, deltaTime / duration));
	}

	/**
	 * Snap a value to another if it's within a certain distance (inclusive).
	 *
	 * Helpful when using functions like `smoothLerpPrecision` to ensure the value actually reaches the target.
	 *
	 * @param base The base value to conditionally snap.
	 * @param target The target value to snap to.
	 * @param threshold Maximum distance between the two for snapping to occur.
	 *
	 * @return `target` if `base` is within `threshold` of it, otherwise `base`.
	 */
	public static function snap(base:Float, target:Float, threshold:Float):Float {
		return Math.abs(base - target) <= threshold ? target : base;
	}

	/**
	 * GCD stands for Greatest Common Divisor
	 * It's used in FullScreenScaleMode to prevent weird window resolutions from being counted as wide screen since those were causing issues positioning the game
	 * It returns the greatest common divisor between m and n
	 *
	 * @param m
	 * @param n
	 * @return Int the common divisor between m and n
	 */
	public static function gcd(m:Int, n:Int):Int {
		m = Math.floor(Math.abs(m));
		n = Math.floor(Math.abs(n));
		var t;
		do {
			if (n == 0) return m;
			t = m;
			m = n;
			n = t % m;
		}
		while (true);
	}
}
