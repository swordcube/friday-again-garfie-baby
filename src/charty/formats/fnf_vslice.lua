local Format = require(_CHARTY_PARENT .. ".format") --- @type charty.Format

local json = require(_CHARTY_PARENT .. ".lib.json") --- @type charty.lib.Json
local fs = require(_CHARTY_PARENT .. ".lib.nativefs") --- @type charty.lib.nativefs

--- @class charty.formats.FNFVSlice : charty.Format
local FNFVSlice, super = Format:extend("FNFVSlice", ...)

function FNFVSlice:__init__()
    super.__init__(self)

    self.requiresMultipleCharts = false
    self.requiresMetaFile = true
end

function FNFVSlice:fromFile(chartPath, metaPath, _)
    self.chart = json.parse(fs.read("string", chartPath))
    self.meta = json.parse(fs.read("string", metaPath))
    return self
end

function FNFVSlice:fromBasicFormat(basicFormat, _)
    local difficulties = {}
    local timeChanges = {}
    for i = 1, #basicFormat.meta.bpmChanges do
        local bpmChange = basicFormat.meta.bpmChanges[i]
        timeChanges[i] = {
            t = bpmChange.time,
            b = 0, -- TODO: calculate beat
            
            bpm = bpmChange.bpm,
            
            n = bpmChange.beatsPerMeasure,
            d = bpmChange.stepsPerBeat,

            bt = {4, 4, 4, 4} -- TODO: what in the actual fuck does this mean
        }
    end
    self.chart = {
        notes = {},
        events = {}
    }
    for diff, notes in pairs(basicFormat.chart.diffs) do
        self.chart.notes[diff] = {}
        difficulties[#difficulties + 1] = diff
        
        for i = 1, #notes do
            local note = notes[i]
            self.chart.notes[diff][i] = {
                t = note.time,
                d = (note.lane + 4) % 8,
                l = note.length,
                k = note.type
            }
        end
    end
    for i = 1, #basicFormat.chart.events do
        local event = basicFormat.chart.events[i]
        self.chart.events[i] = {
            t = event.time,
            v = event.params[1] and {array = event.params} or event.params,
            e = event.type
        }
    end
    self.meta = {
        songName = basicFormat.meta.title or "Unknown",

        artist = basicFormat.meta.extraData.SONG_ARTIST or "Unknown",
        charter = basicFormat.meta.extraData.SONG_CHARTER or "Unknown",

        playData = {
            album = basicFormat.meta.extraData.SONG_ALBUM or "vol1",
            ratings = basicFormat.meta.extraData.SONG_RATINGS or {},
            stage = basicFormat.meta.extraData.STAGE or "stage",
            difficulties = difficulties,

            characters = {
                player = basicFormat.meta.extraData.PLAYER_1,
                opponent = basicFormat.meta.extraData.PLAYER_2,
                girlfriend = basicFormat.meta.extraData.PLAYER_3 or "gf",
    
                opponentVocals = {basicFormat.meta.extraData.PLAYER_2},
                playerVocals = {basicFormat.meta.extraData.PLAYER_1},
            },
            songVariations = basicFormat.meta.extraData.SONG_VARIATIONS or {},
            noteStyle = basicFormat.meta.extraData.SONG_NOTE_SKIN or "funkin"
        },
        timeFormat = "ms",
        timeChanges = timeChanges
    }
    return self
end

--- @return {chart: any, meta: any}
function FNFVSlice:toBasicFormat()
    local basic = {
        chart = {
            diffs = {}, --- @type table<string, table[]>
            events = {} --- @type table[]
        },
        meta = {
            title = self.meta.songName or "Unknown",
            bpmChanges = {}, --- @type table[]
            scrollSpeeds = self.chart.scrollSpeed, --- @type table<string, number>
            offset = 0.0,
            extraData = {
                PLAYER_1 = self.meta.playData.characters.player or "bf",
                PLAYER_2 = self.meta.playData.characters.opponent or "dad",
                PLAYER_3 = self.meta.playData.characters.girlfriend or "gf",

                STAGE = self.meta.playData.stage or "stage",
                
                SONG_ARTIST = self.meta.artist,
                SONG_CHARTER = self.meta.charter,

                SONG_RATINGS = self.meta.ratings,
                SONG_VARIATIONS = self.meta.playData.songVariations or {},

                SONG_NOTE_SKIN = self.meta.playData.noteStyle or "funkin",
            }, --- @type table<string, any>
        }
    }
    for diff, notes in pairs(self.chart.notes) do
        local basicNotes = {}
        for i = 1, #notes do
            local note = notes[i]
            basicNotes[#basicNotes + 1] = {
                time = note.t,
                lane = (note.d + 4) % 8,
                length = note.l,
                type = note.k
            }
        end
        basic.chart.diffs[diff] = basicNotes
    end
    for i = 1, #self.chart.events do
        local event = self.chart.events[i]
        basic.chart.events[i] = {
            time = event.t,
            params = type(event.v) == "table" and (event.v[1] ~= nil and {array = event.v} or event.v) or {v = event.v},
            type = event.e,
        }
    end
    for i = 1, #self.meta.timeChanges do
        local tc = self.meta.timeChanges[i]
        basic.meta.bpmChanges[i] = {
            time = tc.t,
            bpm = tc.bpm,
            beatsPerMeasure = tc.n,
            stepsPerBeat = tc.d
        }
    end
    return basic
end

return FNFVSlice