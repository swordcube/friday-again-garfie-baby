local Format = require(_CHARTY_PARENT .. ".format") --- @type charty.Format

local json = require(_CHARTY_PARENT .. ".lib.json") --- @type charty.lib.Json
local fs = require(_CHARTY_PARENT .. ".lib.nativefs") --- @type charty.lib.nativefs 

--- @class charty.formats.FNFCodename : charty.Format
local FNFCodename, super = Format:subclass("FNFCodename", ...)

function FNFCodename:__init__()
    super.__init__(self)

    self.requiresMultipleCharts = true
    self.requiresMetaFile = true
end

function FNFCodename:fromFile(chartPath, metaPath, diff)
    if diff == nil then
        diff = "unknown"
    end
    self.chart = json.parse(fs.read("string", chartPath))
    self.meta = json.parse(fs.read("string", metaPath))
    return self
end

function FNFCodename:fromBasicFormat(basicFormat, diffs)
    local difficulties = {}
    if type(diffs) == "string" then
        difficulties = {diffs}
    else
        difficulties = diffs
    end
    for diff, speed in pairs(basicFormat.meta.scrollSpeeds) do
        self._scrollSpeeds[diff] = speed
    end
    self.difficulties = difficulties
    self.chart = {
        strumLines = {},
        events = {},
        scrollSpeed = self._scrollSpeeds[difficulties[1]]
    }
    local characters = {
        opponent = basicFormat.meta.extraData.PLAYER_2 or "dad",
        player = basicFormat.meta.extraData.PLAYER_1 or "bf",
        spectator = basicFormat.meta.extraData.PLAYER_3 or "gf"
    }
    local noteTypes = {"Default"}
    for _, notes in pairs(basicFormat.chart.diffs) do
        for i = 1, #notes do
            local note = notes[i]
            if not table.contains(noteTypes, note.type) then
                noteTypes[#noteTypes + 1] = note.type
            end
        end
    end
    self.chart.noteTypes = noteTypes
    
    for diff, notes in pairs(basicFormat.chart.diffs) do
        self.chart.strumLines[diff] = {
            {strumScale = 1, type = 0, position = "dad", notes = {}, characters = {characters.opponent}, strumLinePos = 0.25},
            {strumScale = 1, type = 1, position = "boyfriend", notes = {}, characters = {characters.player}, strumLinePos = 0.75},
            {strumScale = 1, type = 2, position = "girlfriend", notes = {}, characters = {characters.spectator}, strumLinePos = 0.5, visible = false}
        }
        difficulties[#difficulties + 1] = diff
        
        for i = 1, #notes do
            local note = notes[i]
            self.chart.strumLines[diff][note.lane < 4 and 1 or 2].notes[i] = {
                time = note.time,
                id = note.lane,
                sLen = note.length,
                type = table.indexOf(noteTypes, note.type)
            }
        end
    end
    for i = 1, #basicFormat.chart.events do
        local event = basicFormat.chart.events[i]
        local params = {}
        if event.params.array then
            params = event.params.array
        else
            for _, value in pairs(event.params) do
                params[#params + 1] = value
            end
        end
        self.chart.events[i] = {
            time = event.time,
            params = params,
            name = event.type
        }
    end
    local firstBPMChange = basicFormat.meta.bpmChanges[1]
    self.meta = {
        beatsPerMeasure = firstBPMChange.beatsPerMeasure,
        stepsPerBeat = firstBPMChange.stepsPerBeat,

        opponentModeAllowed = basicFormat.meta.extraData.opponentModeAllowed ~= nil and basicFormat.meta.extraData.opponentModeAllowed or true,
        coopAllowed = basicFormat.meta.extraData.coopAllowed ~= nil and basicFormat.meta.extraData.coopAllowed or true,
        needsVoices = basicFormat.meta.extraData.needsVoices ~= nil and basicFormat.meta.extraData.needsVoices or false,

        bpm = firstBPMChange.bpm,
        difficulties = difficulties,

        name = basicFormat.meta.title:replace(" ", "-"):lower(),
        displayName = basicFormat.meta.title,

        icon = basicFormat.meta.extraData.SONG_ICON or "face",
        color = basicFormat.meta.extraData.SONG_COLOR or "#FFFFFF",

        _noteTypes = noteTypes,
        _bpmChanges = basicFormat.meta.bpmChanges, -- i am NOT about to manually extract the bpm changes from the events bro
    }
    for i = 2, #basicFormat.meta.bpmChanges do
        local bpmChange = basicFormat.meta.bpmChanges[i]
        self.chart.events[#self.chart.events + 1] = {
            time = bpmChange.time,
            params = {bpmChange.bpm},
            name = "BPM Change"
        }
        self.chart.events[#self.chart.events + 1] = {
            time = bpmChange.time,
            params = {bpmChange.beatsPerMeasure, bpmChange.stepsPerBeat, true},
            name = "Time Signature Change"
        }
    end
    for _, strumLine in pairs(self.chart.strumLines) do
        table.sort(strumLine.notes, function(a, b)
            if a.time ~= b.time then
                return a.time < b.time
            end
            return a.id < b.id
        end)
    end
    table.sort(self.chart.events, function(a, b)
        return a.time < b.time
    end)
end

--- @return {chart: any, meta: any}
function FNFCodename:toBasicFormat()
    local firstDiff = self.difficulties[1]
    local basic = {
        chart = {
            diffs = {}, --- @type table<string, table[]>
            events = {} --- @type table[]
        },
        meta = {
            title = self.meta.title or "Unknown",
            bpmChanges = self.meta._bpmChanges, --- @type table[]
            scrollSpeeds = {}, --- @type table<string, number>
            offset = 0.0,
            extraData = {
                PLAYER_1 = self.meta.game.characters.player or "bf",
                PLAYER_2 = self.meta.game.characters.opponent or "dad",
                PLAYER_3 = self.meta.game.characters.spectator or "gf",

                STAGE = self.meta.game.stage or "stage",
                
                SONG_ARTIST = self.meta.song.artist,
                SONG_CHARTER = self.meta.song.charter,

                SONG_RATINGS = self.meta.freeplay and (self.meta.freeplay.ratings or {}) or {},
                SONG_VARIATIONS = self.meta.song.mixes or {},

                SONG_NOTE_SKIN = self.meta.game.noteSkin or "funkin",
            }, --- @type table<string, any>
        }
    }
    basic.meta.scrollSpeeds[firstDiff] = self.chart.scrollSpeed

    for diff, strumLines in pairs(self.chart.strumLines) do
        local theLuckyStrumLines = {
            strumLines[1],
            strumLines[2]
        }
        local laneOffset, basicNotes = 0, {}
        for i = 1, #theLuckyStrumLines do
            local notes = theLuckyStrumLines[i].notes
            for j = 1, #notes do
                local note = notes[j]
                basicNotes[#basicNotes + 1] = {
                    time = note.time,
                    lane = (note.id % 4) + laneOffset,
                    length = note.sLen,
                    type = table.indexOf(self.meta._noteTypes, note.type)
                }
            end
            laneOffset = laneOffset + 4
        end
        basic.chart.diffs[diff] = basicNotes
    end
    for i = 1, #self.chart.events do
        local event = self.chart.events[i]
        basic.chart.events[i] = {
            time = event.time,
            params = {array = event.params},
            type = event.name,
        }
    end
    self.meta._noteTypes = nil
    self.meta._bpmChanges = nil
    return basic
end

return FNFCodename