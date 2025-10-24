local ScoringSystem = srcreq("funkin.gameplay.scoring.scoringsystem") --- @type funkin.gameplay.scoring.ScoringSystem

--- @class funkin.gameplay.scoring.PBotSystem : funkin.gameplay.scoring.ScoringSystem
local PBotSystem = ScoringSystem:extend("PBotSystem", ...)

local math = math

PBotSystem.PERFECT_THRESHOLD = 5.0
PBotSystem.MISS_THRESHOLD = 160.0
PBotSystem.MISS_SCORE = 0

PBotSystem.MIN_SCORE = 9
PBotSystem.MAX_SCORE = 500

PBotSystem.SCORING_OFFSET = 54.99
PBotSystem.SCORING_SLOPE = 0.08

function PBotSystem:judgeNote(noteTimestamp, conductorTimestamp)
    local diff = math.abs(noteTimestamp - conductorTimestamp)
    if diff <= 22.5 then
        return "killer"
    elseif diff <= 45.0 then
        return "sick"
    elseif diff <= 90.0 then
        return "good"
    elseif diff <= 135.0 then
        return "bad"
    end
    return "shit"
end

function PBotSystem:scoreNote(noteTimestamp, conductorTimestamp)
    local diff = math.abs(noteTimestamp - conductorTimestamp)
    if diff >= PBotSystem.MISS_THRESHOLD then
        return PBotSystem.MISS_SCORE
    end
    if diff <= PBotSystem.PERFECT_THRESHOLD then
        return PBotSystem.MAX_SCORE
    end
    local factor = 1.0 - (1.0 / (1.0 + math.exp(-PBotSystem.SCORING_SLOPE * (diff - PBotSystem.SCORING_OFFSET))))
    return math.floor(PBotSystem.MAX_SCORE * factor + PBotSystem.MIN_SCORE)
end

function PBotSystem:hasHoldScoreBonus()
    return true
end

function PBotSystem:getHoldScoreBonus()
    return 145
end

function PBotSystem:hasNoteSplash(rating)
    return rating == "killer" or rating == "sick"
end

return PBotSystem