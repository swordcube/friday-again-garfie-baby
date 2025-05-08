package funkin.utilities;

import flixel.math.FlxPoint;
import flixel.util.helpers.FlxBounds;

import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

class CustomEmitter extends FlxEmitter {
	/**
	 * Minimum and maximum bounds for scroll factors
	 */
	public var scrollFactor(default, null):FlxBounds<FlxPoint> = new FlxBounds(new FlxPoint(1, 1), new FlxPoint(1, 1));

	/**
	 * Signal that gets dispatched when a particle is emitted
	 */
	public var onEmit(default, null):FlxTypedSignal<FlxParticle->Void> = new FlxTypedSignal<FlxParticle->Void>();

	override function emitParticle():FlxParticle {
		final _particle:FlxParticle = super.emitParticle();
		_particle.scrollFactor.set();

		if(scrollFactor.active) {
			final scrollX = FlxG.random.float(scrollFactor.min.x, scrollFactor.min.y);
			final scrollY = FlxG.random.float(scrollFactor.max.x, scrollFactor.max.y);
			_particle.scrollFactor.set(scrollX, scrollY);
		}
		onEmit.dispatch(_particle);
		return _particle;
	}

	override function destroy():Void {
        if(onEmit != null) {
            onEmit.removeAll();
            onEmit.destroy();
            onEmit = null;
        }
		scrollFactor.min = FlxDestroyUtil.put(scrollFactor.min);
		scrollFactor.max = FlxDestroyUtil.put(scrollFactor.max);
		super.destroy();
	}
}
