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
            icon = "face",
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
end

return FNFGarfieBaby