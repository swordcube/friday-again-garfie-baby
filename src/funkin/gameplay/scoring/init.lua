--- @class funkin.gameplay.Scoring
local Scoring = {}

Scoring.defaultSystem = srcreq("funkin.gameplay.scoring.pbotsystem") --- @type funkin.gameplay.scoring.PBotSystem
Scoring.currentSystem = Scoring.defaultSystem:new() --- @type funkin.gameplay.scoring.ScoringSystem

function Scoring.resetSystem()
    Scoring.currentSystem = Scoring.defaultSystem:new()
end

function Scoring.judgeNote(noteTimestamp, conductorTimestamp)
    return Scoring.currentSystem:judgeNote(noteTimestamp, conductorTimestamp)
end

function Scoring.scoreNote(noteTimestamp, conductorTimestamp)
    return Scoring.currentSystem:scoreNote(noteTimestamp, conductorTimestamp)
end

function Scoring.hasHoldScoreBonus()
    return Scoring.currentSystem:hasHoldScoreBonus()
end

function Scoring.getHoldScoreBonus()
    return Scoring.currentSystem:getHoldScoreBonus()
end

function Scoring.hasNoteSplash(rating)
    return Scoring.currentSystem:hasNoteSplash(rating)
end

return Scoring