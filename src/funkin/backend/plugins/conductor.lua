local Plugin = cometreq("core.plugin") --- @type comet.core.Plugin
local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class funkin.backend.plugins.Conductor : comet.core.Plugin
local Conductor = Plugin:subclass("Conductor", ...)
Conductor.static.instance = nil --- @type funkin.backend.plugins.Conductor

function Conductor:__init__()
    self.offset = 0.0
    self.rate = 1.0

    --- @protected
    self._rawTime = 0.0

    --- @protected
    self._rawPlayhead = 0.0

    self.curDecStep = 0.0
    self.curDecBeat = 0.0
    self.curDecMeasure = 0.0

    self.curStep = 0
    self.curBeat = 0
    self.curMeasure = 0

    self.hasMetronome = false
    self.autoIncrement = true

    self.dispatchToScreens = false
    self.timingPoints = {} --- @type table[]

    self.onStepHit = Signal:new():type("integer", "void") --- @type comet.util.Signal
    self.onBeatHit = Signal:new():type("integer", "void") --- @type comet.util.Signal
    self.onMeasureHit = Signal:new():type("integer", "void") --- @type comet.util.Signal

    self.music = nil --- @type comet.mixer.Sound

    --- @protected
    self._latestTimingPoint = nil

    --- @protected
    self._lastPlayhead = 0.0

    self.metronome = comet.mixer:load("assets/ui/sfx/metronome.ogg", 1, false)
    self.metronome.autoDestroy = false

    self:reset(100)
end

function Conductor:getCurrentBPM()
    return self._latestTimingPoint.bpm
end

function Conductor:getCurrentTimeSignature()
    return self._latestTimingPoint.timeSignature
end

function Conductor:getStepLengthFromTimingPoint(timingPoint)
    return (60000.0 / timingPoint.bpm) / timingPoint.timeSignature[2]
end

function Conductor:getBeatLengthFromTimingPoint(timingPoint)
    return 60000.0 / timingPoint.bpm
end

function Conductor:getMeasureLengthFromTimingPoint(timingPoint)
    return (60000.0 / timingPoint.bpm) * timingPoint.timeSignature[1]
end

function Conductor:getCurrentStepLength()
    return self:getStepLengthFromTimingPoint(self._latestTimingPoint)
end

function Conductor:getCurrentBeatLength()
    return self:getBeatLengthFromTimingPoint(self._latestTimingPoint)
end

function Conductor:getCurrentMeasureLength()
    return self:getMeasureLengthFromTimingPoint(self._latestTimingPoint)
end

function Conductor:getCurrentRawTime()
    return self._rawTime
end

function Conductor:setCurrentRawTime(t)
    local music = self.music
    if music and music:isPlaying() and music:getTime() <= 20 and t < self._rawTime then
        self.curStep = -1
        self.curBeat = -1
        self.curMeasure = -1

        self.curDecStep = -1.0
        self.curDecBeat = -1.0
        self.curDecMeasure = -1.0
    end
    self._rawTime = t
    self._rawPlayhead = t
    self._lastPlayhead = t
    self._latestTimingPoint = self:getTimingPointAtTime(t)
end

function Conductor:getCurrentRawPlayhead()
    return self._rawPlayhead
end

function Conductor:setCurrentRawPlayhead(t)
    self._rawPlayhead = t
end

function Conductor:getCurrentTime()
    return self._rawTime - self.offset
end

function Conductor:setCurrentTime(t)
    self._rawTime = t - self.offset
end

function Conductor:getCurrentPlayhead()
    return self._rawPlayhead - self.offset
end

function Conductor:reset(bpm, timeSignature)
    if timeSignature == nil then
        timeSignature = {4, 4}
    end
    self.timingPoints = {
        {
            time = 0.0,

            step = 0.0,
            beat = 0.0,
            measure = 0.0,
            
            bpm = bpm,
            timeSignature = timeSignature
        }
    }
    self._latestTimingPoint = self.timingPoints[1]

    self.curStep = -1
    self.curBeat = -1
    self.curMeasure = -1

    self.curDecStep = -1.0
    self.curDecBeat = -1.0
    self.curDecMeasure = -1.0

    self._rawTime = 0.0
    self._rawPlayhead = 0.0

    self._lastPlayhead = -999999999.0
end

function Conductor:setupTimingPoints(timingPoints)
    table.sort(timingPoints, function(a, b)
        return a.time < b.time
    end)
    local timeOffset = 0.0
    local stepOffset = 0.0
    local beatOffset = 0.0
    local measureOffset = 0.0

    local lastTopNumber = timingPoints[1].timeSignature[1]
    local lastBottomNumber = timingPoints[1].timeSignature[2]

    local lastBPM = timingPoints[1].bpm
    for i = 2, #timingPoints do
        local point = timingPoints[i]
        local beatDifference = (point.time - timeOffset) / (60000.0 / lastBPM)

        measureOffset = measureOffset + (beatDifference / lastTopNumber)
        beatOffset = beatOffset + beatDifference
        stepOffset = stepOffset + (beatDifference * lastBottomNumber)

        local newPoint = {
            time = point.time,

            step = stepOffset,
            beat = beatOffset,
            measure = measureOffset,
            
            bpm = point.bpm,
            timeSignature = point.timeSignature
        }
        table.insert(self.timingPoints, newPoint)

        timeOffset = point.time

        lastTopNumber = point.timeSignature[1]
        lastBottomNumber = point.timeSignature[2]

        lastBPM = point.bpm
    end
    self._latestTimingPoint = self.timingPoints[1]
end

function Conductor:getTimingPointAtTime(time)
    local output = self.timingPoints[1]
    for i = 2, #self.timingPoints do
        local point = self.timingPoints[i]
        if time < point.time then break end
        output = point
    end
    return output
end

function Conductor:getTimingPointAtStep(step)
    local output = self.timingPoints[1]
    for i = 2, #self.timingPoints do
        local point = self.timingPoints[i]
        if step < point.step then break end
        output = point
    end
    return output
end

function Conductor:getTimingPointAtBeat(beat)
    local output = self.timingPoints[1]
    for i = 2, #self.timingPoints do
        local point = self.timingPoints[i]
        if beat < point.beat then break end
        output = point
    end
    return output
end

function Conductor:getTimingPointAtMeasure(measure)
    local output = self.timingPoints[1]
    for i = 2, #self.timingPoints do
        local point = self.timingPoints[i]
        if measure < point.measure then break end
        output = point
    end
    return output
end

function Conductor:getStepAtTime(time, latestTimingPoint)
    if not latestTimingPoint then
        latestTimingPoint = self:getTimingPointAtTime(time)
    end
    return latestTimingPoint.step + (time - latestTimingPoint.time) / self:getStepLengthFromTimingPoint(latestTimingPoint)
end

function Conductor:getBeatAtTime(time, latestTimingPoint)
    if not latestTimingPoint then
        latestTimingPoint = self:getTimingPointAtTime(time)
    end
    return latestTimingPoint.beat + (time - latestTimingPoint.time) / self:getBeatLengthFromTimingPoint(latestTimingPoint)
end

function Conductor:getMeasureAtTime(time, latestTimingPoint)
    if not latestTimingPoint then
        latestTimingPoint = self:getTimingPointAtTime(time)
    end
    return latestTimingPoint.measure + (time - latestTimingPoint.time) / self:getMeasureLengthFromTimingPoint(latestTimingPoint)
end

function Conductor:getTimeAtStep(step)
    local curTimingPoint = self:getTimingPointAtStep(step)
    return curTimingPoint.time + self:getStepLengthFromTimingPoint(curTimingPoint) * (step - curTimingPoint.step)
end

function Conductor:getTimeAtBeat(beat)
    local curTimingPoint = self:getTimingPointAtBeat(beat)
    return curTimingPoint.time + self:getBeatLengthFromTimingPoint(curTimingPoint) * (beat - curTimingPoint.beat)
end

function Conductor:getTimeAtMeasure(measure)
    local curTimingPoint = self:getTimingPointAtMeasure(measure)
    return curTimingPoint.time + self:getMeasureLengthFromTimingPoint(curTimingPoint) * (measure - curTimingPoint.measure)
end

local function recursiveStep(object, step)
    local children = object.children
    for i = 1, #children do
        local child = children[i]
        recursiveStep(child, step)
    end
    if object.stepHit then
        object:stepHit(step)
    end
end

local function recursiveBeat(object, beat)
    local children = object.children
    for i = 1, #children do
        local child = children[i]
        recursiveBeat(child, beat)
    end
    if object.beatHit then
        object:beatHit(beat)
    end
end

local function recursiveMeasure(object, measure)
    local children = object.children
    for i = 1, #children do
        local child = children[i]
        recursiveMeasure(child, measure)
    end
    if object.measureHit then
        object:measureHit(measure)
    end
end

function Conductor:update(dt)
    local music = self.music
    if music and music:isPlaying() then
        local mt = music:getTime()
        if mt < self._rawTime and mt <= 20 then
            self.curStep = -1
            self.curBeat = -1
            self.curMeasure = -1

            self.curDecStep = -1.0
            self.curDecBeat = -1.0
            self.curDecMeasure = -1.0
        end
        self._rawTime = mt

        if self._lastPlayhead ~= mt then
            self._rawPlayhead = mt
            self._lastPlayhead = mt
        else
            self._rawPlayhead = self._rawPlayhead + (dt * 1000.0 * self.rate)
        end
    elseif self.autoIncrement then
        self._rawTime = self._rawTime + (dt * 1000.0 * self.rate)
        self._rawPlayhead = self._rawTime
    end
    local curTimingPoint = self:getTimingPointAtTime(self:getCurrentTime())
    self._latestTimingPoint = curTimingPoint

    local lastStep = self.curStep
    local lastBeat = self.curBeat
    local lastMeasure = self.curMeasure

    local t = self:getCurrentTime()
    self.curDecStep = self:getStepAtTime(t, curTimingPoint)
    self.curStep = math.floor(self.curDecStep)

    if self.curStep > lastStep then
        for i = lastStep, self.curStep do
            if self.dispatchToScreens then
                recursiveStep(ScreenManager.instance.current, i + 1)
            end
            self.onStepHit:emit(i + 1)
        end
    end
    self.curDecBeat = self:getBeatAtTime(t, curTimingPoint)
    self.curBeat = math.floor(self.curDecBeat)
    
    if self.curBeat > lastBeat then
        if self.hasMetronome then
            self.metronome:setPitch(math.floor(self.curDecBeat - curTimingPoint.beat) % curTimingPoint.timeSignature[1] == 0 and 1.5 or 1.12)
            self.metronome:seek(0.0)
            self.metronome:play()
        end
        for i = lastBeat, self.curBeat do
            if self.dispatchToScreens then
                recursiveBeat(ScreenManager.instance.current, i + 1)
            end
            self.onBeatHit:emit(i + 1)
        end
    end
    self.curDecMeasure = self:getMeasureAtTime(t, curTimingPoint)
    self.curMeasure = math.floor(self.curDecMeasure)

    if self.curMeasure > lastMeasure then
        for i = lastMeasure, self.curMeasure do
            if self.dispatchToScreens then
                recursiveMeasure(ScreenManager.instance.current, i + 1)
            end
            self.onMeasureHit:emit(i + 1)
        end
    end
end

function Conductor:destroy()
    if self.metronome then
        self.metronome:destroy()
        self.metronome = nil
    end
end

return Conductor