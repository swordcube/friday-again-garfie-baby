package funkin.backend;

import flixel.sound.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;

enum abstract TimeSignature(Array<Int>) from Array<Int> to Array<Int> {
    @:from
    public static function fromString(str:String):TimeSignature {
        var split:Array<String> = str.split("/");

        var numerator:Null<Int> = Std.parseInt(split[0]);
        if(numerator == null)
            numerator = 4;

        var denominator:Null<Int> = Std.parseInt(split[1]);
        if(denominator == null)
            denominator = 4;

        return [numerator, denominator];
    }

    @:to
    public function toString():String {
        return '${getNumerator()}/${getDenominator()}';
    }

    public inline function getNumerator():Int {
        return this[0];
    }

    public inline function setNumerator(value:Int):Void {
        this[0] = value;
    }

    public inline function getDenominator():Int {
        return this[1];
    }

    public inline function setDenominator(value:Int):Void {
        this[1] = value;
    }
}

/**
 * Data for determining BPM/time sig changes, as a class.
 */
@:structInit
class TimingPoint {
    @:alias("t")
    public var time:Float;

    @:jignored
    public var step:Float;

    @:jignored
    public var beat:Float;

    @:jignored
    public var measure:Float;

    @:alias("b")
    public var bpm:Float;

    @:alias("ts")
    public var timeSignature:Array<Int>;

    public inline function getTimeSignature():TimeSignature {
        return cast timeSignature;
    }

    public inline function getStepLength():Float {
        return getBeatLength() / timeSignature[1];
    }

    public inline function getBeatLength():Float {
        return ((60 / bpm) * 1000);
    }

    public inline function getMeasureLength():Float {
        return getBeatLength() * timeSignature[0];
    }
}

interface IBeatReceiver {
    public function stepHit(step:Int):Void;
    public function beatHit(beat:Int):Void;
    public function measureHit(measure:Int):Void;
}

class Conductor extends FlxBasic {
    public static var instance:Conductor;

    public var bpm(get, never):Float;
    public var timeSignature(get, never):TimeSignature;

    public var stepLength(get, never):Float;
    public var beatLength(get, never):Float;
    public var measureLength(get, never):Float;

    public var offset:Float = 0;
    public var rate:Float = 1;

    public var music:FlxSound;

    /**
     * The current time in milliseconds.
     * 
     * Use `playhead` instead of this value if you want
     * a smoother representation of it.
     */
    public var time(get, set):Float;

    /**
     * The current playhead position in milliseconds.
     */
    public var playhead(get, set):Float;

    public var rawTime(default, set):Float = 0;
    public var rawPlayhead(default, null):Float = 0;

    public var curDecStep:Float = 0;
    public var curDecBeat:Float = 0;
    public var curDecMeasure:Float = 0;

    public var curStep:Int = 0;
    public var curBeat:Int = 0;
    public var curMeasure:Int = 0;

    public var hasMetronome:Bool = false;
    public var autoIncrement:Bool = true;

    /**
     * Whether or not to dispatch step, beat, and measure
     * hits to the current state and substates (if applicable).
     * 
     * This is usually only enabled for the primary conductor, but
     * can be enabled for custom ones for specific cases such as
     * chart editor playtesting.
     */
    public var dispatchToStates:Bool = false;
    public var timingPoints:Array<TimingPoint>;

    public var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
    public var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
    public var onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

    public function new() {
        super();
        visible = false;
        reset();
    }

    public function reset(bpm:Float = 100, ?timeSignature:TimeSignature):Void {
        if(timeSignature == null)
            timeSignature = [4, 4];
        
        timingPoints = [
            {
                time: 0,

                step: 0,
                beat: 0,
                measure: 0,

                bpm: bpm,
                timeSignature: timeSignature
            }
        ];
        _latestTimingPoint = timingPoints[0];

        curStep = -1;
        curDecStep = -1;
        
        curBeat = -1;
        curDecBeat = -1;

        curMeasure = -1;
        curDecMeasure = -1;

        rawTime = 0;
        rawPlayhead = 0;
        
        _lastPlayhead = -999999;
    }

    public function setupTimingPoints(timingPoints:Array<TimingPoint>) {
        var timeOffset:Float = 0;
        var stepOffset:Float = 0;
        var beatOffset:Float = 0;
        var measureOffset:Float = 0;

        // the top number in the time signature represents the amount of beats per measure
        var lastTopNumber:Float = timingPoints[0].getTimeSignature().getNumerator();

        // the bottom number in the time signature represents the amount of steps per beat
        var lastBottomNumber:Float = timingPoints[0].getTimeSignature().getDenominator();

        var lastBPM:Float = timingPoints[0].bpm;
        timingPoints.sort((a, b) -> Std.int(a.time - b.time));

        for(i in 1...timingPoints.length) {
            final point:TimingPoint = timingPoints[i];
            final beatDifference:Float = (point.time - timeOffset) / ((60 / lastBPM) * 1000);

            measureOffset += beatDifference / lastTopNumber;
            beatOffset += beatDifference;
            stepOffset += beatDifference * lastBottomNumber;
            
            final newPoint:TimingPoint = {
                time: point.time,
                
                step: stepOffset,
                beat: beatOffset,
                measure: measureOffset,

                bpm: point.bpm,
                timeSignature: point.timeSignature
            };
            this.timingPoints.push(newPoint);
            
            timeOffset = point.time;

            lastTopNumber = point.getTimeSignature().getNumerator();
            lastBottomNumber = point.getTimeSignature().getDenominator();

            lastBPM = point.bpm;
        }
        _latestTimingPoint = this.timingPoints[0];
    }

    public function getTimingPointAtTime(time:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];
        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (time < point.time) break;
            output = point;
        }
        return output;
    }

    public function getTimingPointAtStep(step:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];
        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (step < point.step) break;
            output = point;
        }
        return output;
    }

    public function getTimingPointAtBeat(beat:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];
        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (beat < point.beat) break;
            output = point;
        }
        return output;
    }

    public function getTimingPointAtMeasure(measure:Float):TimingPoint {
        var output:TimingPoint = timingPoints[0];
        for (i in 1...timingPoints.length) {
            var point:TimingPoint = timingPoints[i];
            if (measure < point.measure) break;
            output = point;
        }
        return output;
    }

    public function getStepAtTime(time:Float, ?latestTimingPoint:TimingPoint):Float {
        if(latestTimingPoint == null)
            latestTimingPoint = getTimingPointAtTime(time);
        
        return latestTimingPoint.step + (time - latestTimingPoint.time) / latestTimingPoint.getStepLength();
    }

    public function getBeatAtTime(time:Float, ?latestTimingPoint:TimingPoint):Float {
        if(latestTimingPoint == null)
            latestTimingPoint = getTimingPointAtTime(time);
        
        return latestTimingPoint.beat + (time - latestTimingPoint.time) / latestTimingPoint.getBeatLength();
    }

    public function getMeasureAtTime(time:Float, ?latestTimingPoint:TimingPoint):Float {
        if(latestTimingPoint == null)
            latestTimingPoint = getTimingPointAtTime(time);

        return latestTimingPoint.measure + (time - latestTimingPoint.time) / latestTimingPoint.getMeasureLength();
    }

    public function getTimeAtStep(step:Float):Float {
        var curTimingPoint:TimingPoint = getTimingPointAtStep(step);
        return curTimingPoint.time + curTimingPoint.getStepLength() * (step - curTimingPoint.step);
    }

    public function getTimeAtBeat(beat:Float):Float {
        var curTimingPoint:TimingPoint = getTimingPointAtBeat(beat);
        return curTimingPoint.time + curTimingPoint.getBeatLength() * (beat - curTimingPoint.beat);
    }

    public function getTimeAtMeasure(measure:Float):Float {
        var curTimingPoint:TimingPoint = getTimingPointAtMeasure(measure);
        return curTimingPoint.time + curTimingPoint.getMeasureLength() * (measure - curTimingPoint.measure);
    }

    override function update(elapsed:Float) {
        if(music != null && music.playing) {
            if(music.time < rawTime) {
                // we've probably looped the music or something
                // so reset the beats so the first one doesn't get skipped
                curStep = -1;
                curDecStep = -1;
                
                curBeat = -1;
                curDecBeat = -1;

                curMeasure = -1;
                curDecMeasure = -1;
            }
            @:bypassAccessor rawTime = music.time;

            if(_lastPlayhead != rawTime)
                rawPlayhead = _lastPlayhead = rawTime;
            else
                rawPlayhead += elapsed * 1000 * rate;
        }
        else if(autoIncrement) {
            @:bypassAccessor rawTime += elapsed * 1000 * rate;
            rawPlayhead = rawTime;
        }
        var curTimingPoint:TimingPoint = getTimingPointAtTime(time);
        _latestTimingPoint = curTimingPoint;

        final lastStep:Int = curStep;
        final lastBeat:Int = curBeat;
        final lastMeasure:Int = curMeasure;

        curDecStep = getStepAtTime(time, curTimingPoint);
        curStep = Math.floor(curDecStep);

        if(curStep > lastStep) {
            for(i in lastStep...curStep) {
                if(dispatchToStates) {
                    var state:FlxState = FlxG.state;
                    while(state != null) {
                        if(state.persistentUpdate || state.subState == null)
                            recursiveStep(state, i + 1);

                        state = state.subState;
                    }
                }
                onStepHit.dispatch(i + 1);
            }
        }
        curDecBeat = getBeatAtTime(time, curTimingPoint);
        curBeat = Math.floor(curDecBeat);

        if(curBeat > lastBeat) {
            if(hasMetronome) {
                final sound:FlxSound = FlxG.sound.play(Paths.sound('editors/charter/sfx/metronome'));
                sound.pitch = (Math.floor(curDecBeat - curTimingPoint.beat) % curTimingPoint.getTimeSignature().getNumerator() == 0) ? 1.5 : 1.12;
            }
            for(i in lastBeat...curBeat) {
                if(dispatchToStates) {
                    var state:FlxState = FlxG.state;
                    while(state != null) {
                        if(state.persistentUpdate || state.subState == null)
                            recursiveBeat(state, i + 1);
                        
                        state = state.subState;
                    }
                }
                onBeatHit.dispatch(i + 1);
            }
        }
        curDecMeasure = getMeasureAtTime(time, curTimingPoint);
        curMeasure = Math.floor(curDecMeasure);

        if(curMeasure > lastMeasure) {
            for(i in lastMeasure...curMeasure) {
                if(dispatchToStates) {
                    var state:FlxState = FlxG.state;
                    while(state != null) {
                        if(state.persistentUpdate || state.subState == null)
                            recursiveMeasure(state, i + 1);

                        state = state.subState;
                    }
                }
                onMeasureHit.dispatch(i + 1);
            }
        }
    }

    //----------- [ Private API ] -----------//

    private var _lastPlayhead:Float = 0;
    private var _latestTimingPoint:TimingPoint = null;

    @:noCompletion
    private inline function get_bpm():Float {
        return _latestTimingPoint.bpm;
    }

    @:noCompletion
    private inline function get_stepLength():Float {
        return _latestTimingPoint.getStepLength();
    }

    @:noCompletion
    private inline function get_beatLength():Float {
        return _latestTimingPoint.getBeatLength();
    }

    @:noCompletion
    private inline function get_measureLength():Float {
        return _latestTimingPoint.getMeasureLength();
    }

    @:noCompletion
    private inline function get_timeSignature():TimeSignature {
        return _latestTimingPoint.getTimeSignature();
    }

    @:noCompletion
    private inline function get_time():Float {
        return rawTime - offset;
    }

    @:noCompletion
    private inline function set_time(newTime:Float):Float {
        return rawTime = newTime;
    }

    @:noCompletion
    private inline function set_rawTime(newTime:Float):Float {
        if(newTime < rawTime) {
            // we've probably looped the music or something
            // so reset the beats so the first one doesn't get skipped
            curStep = -1;
            curDecStep = -1;
            
            curBeat = -1;
            curDecBeat = -1;

            curMeasure = -1;
            curDecMeasure = -1;
        }
        rawTime = rawPlayhead = _lastPlayhead = newTime;
        _latestTimingPoint = getTimingPointAtTime(time);
        return rawTime;
    }

    @:noCompletion
    private inline function get_playhead():Float {
        return rawPlayhead - offset;
    }

    @:noCompletion
    private inline function set_playhead(newPlayhead:Float):Float {
        return rawPlayhead = newPlayhead;
    }

    @:noCompletion
    private function recursiveStep(state:FlxGroup, step:Int):Void {
        if(state is IBeatReceiver) {
            final beatReceiver:IBeatReceiver = cast state;
            beatReceiver.stepHit(step);
        }
        @:privateAccess
        for(i in 0...state.length) {
            final member:FlxBasic = state.members[i];
            if(member != null && member.exists && member.alive && member.active) {
                if(member.flixelType == SPRITEGROUP) {
                    final sprGroup:FlxSpriteGroup = cast member;
                    recursiveStep(cast sprGroup.group, step);
                }
                else if(member.flixelType == GROUP)
                    recursiveStep(cast member, step);

                else if(member is IBeatReceiver) {
                    final beatReceiver:IBeatReceiver = cast member;
                    beatReceiver.stepHit(step);
                }
            }
        }
    }

    @:noCompletion
    private function recursiveBeat(state:FlxGroup, beat:Int):Void {
        if(state is IBeatReceiver) {
            final beatReceiver:IBeatReceiver = cast state;
            beatReceiver.beatHit(beat);
        }
        @:privateAccess
        for(i in 0...state.length) {
            final member:FlxBasic = state.members[i];
            if(member != null && member.exists && member.alive && member.active) {
                if(member.flixelType == SPRITEGROUP) {
                    final sprGroup:FlxSpriteGroup = cast member;
                    recursiveBeat(cast sprGroup.group, beat);
                }
                else if(member.flixelType == GROUP)
                    recursiveBeat(cast member, beat);

                else if(member is IBeatReceiver) {
                    final beatReceiver:IBeatReceiver = cast member;
                    beatReceiver.beatHit(beat);
                }
            }
        }
    }

    @:noCompletion
    private function recursiveMeasure(state:FlxGroup, measure:Int):Void {
        if(state is IBeatReceiver) {
            final beatReceiver:IBeatReceiver = cast state;
            beatReceiver.measureHit(measure);
        }
        @:privateAccess
        for(i in 0...state.length) {
            final member:FlxBasic = state.members[i];
            if(member != null && member.exists && member.alive && member.active) {
                if(member.flixelType == SPRITEGROUP) {
                    final sprGroup:FlxSpriteGroup = cast member;
                    recursiveMeasure(cast sprGroup.group, measure);
                }
                else if(member.flixelType == GROUP)
                    recursiveMeasure(cast member, measure);

                else if(member is IBeatReceiver) {
                    final beatReceiver:IBeatReceiver = cast member;
                    beatReceiver.measureHit(measure);
                }
            }
        }
    }
}