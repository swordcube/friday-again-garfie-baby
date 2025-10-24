--- @class funkin.gameplay.scoring.ScoringSystem : comet.util.Class
local ScoringSystem = Class:extend("ScoringSystem", ...)

function ScoringSystem:__init__() end

function ScoringSystem:judgeNote(noteTimestamp, conductorTimestamp)
    return "n/a"
end

function ScoringSystem:scoreNote(noteTimestamp, conductorTimestamp)
    return 0
end

function ScoringSystem:hasHoldScoreBonus()
    return false
end

function ScoringSystem:getHoldScoreBonus()
    return 0
end

function ScoringSystem:hasNoteSplash(rating)
    return false
end

return ScoringSystem