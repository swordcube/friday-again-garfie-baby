local Format = require(_CHARTY_PARENT .. ".format") --- @type charty.Format

local json = require(_CHARTY_PARENT .. ".lib.json") --- @type charty.lib.Json
local fs = require(_CHARTY_PARENT .. ".lib.nativefs") --- @type charty.lib.nativefs 

--- @class charty.formats.FNFGarfieBaby : charty.Format
local FNFGarfieBaby, super = Format:subclass("FNFGarfieBaby", ...)

function FNFGarfieBaby:__init__()
    super.__init__(self)

    self.requiresMultipleCharts = false
    self.requiresMetaFile = true
end

function FNFGarfieBaby:fromFile(chartPath, metaPath, _)
    self.chart = json.parse(fs.read("string", chartPath))
    self.meta = json.parse(fs.read("string", metaPath))
    return self
end

function FNFGarfieBaby:fromBasicFormat(basicFormat, _)
    local difficulties = {}
    local timeChanges = {}
    for i = 1, #basicFormat.meta.bpmChanges do
        local bpmChange = basicFormat.meta.bpmChanges[i]
        timeChanges[i] = {
            t = bpmChange.time,
            b = bpmChange.bpm,
            ts = {bpmChange.beatsPerMeasure, bpmChange.stepsPerBeat}
        }
    end
    self.chart = {
        n = {},
        e = {}
    }
    for diff, notes in pairs(basicFormat.chart.diffs) do
        self.chart.n[diff] = {}
        difficulties[#difficulties + 1] = diff
        
        for i = 1, #notes do
            local note = notes[i]
            self.chart.n[diff][i] = {
                t = note.time,
                d = note.lane,
                l = note.length,
                k = note.type
            }
        end
    end
    for i = 1, #basicFormat.chart.events do
        local event = basicFormat.chart.events[i]
        self.chart.e[i] = {
            t = event.time,
            p = type(event.params) == "table" and (event.params[1] ~= nil and {array = event.params} or event.params) or {v = event.params},
            k = event.type
        }
    end
    self.meta = {
        song = {
            title = basicFormat.meta.title,

            mixes = basicFormat.meta.extraData.SONG_MIXES or basicFormat.meta.extraData.SONG_VARIATIONS or {},
            difficulties = difficulties,

            timingPoints = timeChanges,

            artist = basicFormat.meta.extraData.SONG_ARTIST or "Unknown",
            charter = basicFormat.meta.extraData.SONG_CHARTER or "Unknown",

            tracks = {
                opponent = {("vocals-%s"):format(basicFormat.meta.extraData.PLAYER_2)},
                player = {("vocals-%s"):format(basicFormat.meta.extraData.PLAYER_1)},
                spectator = {}
            }
        },
        freeplay = {
            ratings = basicFormat.meta.extraData.SONG_RATINGS or {},
            icon = basicFormat.meta.extraData.SONG_ICON or "face",
            album = basicFormat.meta.extraData.SONG_ALBUM or "vol1"
        },
        game = {
            characters = {
                opponent = basicFormat.meta.extraData.PLAYER_2,
                player = basicFormat.meta.extraData.PLAYER_1,
                spectator = basicFormat.meta.extraData.PLAYER_3 or "gf"
            },
            scrollSpeed = basicFormat.meta.scrollSpeeds,
            
            allowOpponentMode = basicFormat.meta.extraData.allowOpponentMode ~= nil and basicFormat.meta.extraData.allowOpponentMode or true,
            stage = basicFormat.meta.extraData.STAGE or "stage",

            noteSkin = basicFormat.meta.extraData.SONG_NOTE_SKIN or "funkin",
            uiSkin = basicFormat.meta.extraData.SONG_NOTE_SKIN or "funkin",
            hudSkin = basicFormat.meta.extraData.hudSkin
        }
    }
    for _, notes in pairs(self.chart.n) do
        table.sort(notes, function(a, b)
            if a.t ~= b.t then
                return a.t < b.t
            end
            return a.d < b.d
        end)
    end
    table.sort(self.chart.e, function(a, b)
        return a.t < b.t
    end)
end

--- @return {chart: any, meta: any}
function FNFGarfieBaby:toBasicFormat()
    local basic = {
        chart = {
            diffs = {}, --- @type table<string, table[]>
            events = {} --- @type table[]
        },
        meta = {
            title = self.meta.song.title or "Unknown",
            bpmChanges = {}, --- @type table[]
            scrollSpeeds = self.meta.game.scrollSpeed, --- @type table<string, number>
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
    for diff, notes in pairs(self.chart.notes) do
        local basicNotes = {}
        for i = 1, #notes do
            local note = notes[i]
            basicNotes[#basicNotes + 1] = {
                time = note.t,
                lane = note.d,
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
            params = type(event.p) == "table" and (event.p[1] ~= nil and {array = event.p} or event.p) or {v = event.p},
            type = event.e,
        }
    end
    for i = 1, #self.meta.song.timingPoints do
        local tc = self.meta.song.timingPoints[i]
        basic.meta.bpmChanges[i] = {
            time = tc.t,
            bpm = tc.b,
            beatsPerMeasure = tc.ts[1],
            stepsPerBeat = tc.ts[2]
        }
    end
    return basic
end

return FNFGarfieBaby