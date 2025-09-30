local json = cometreq("lib.json") --- @type comet.lib.Json

--- @class funkin.gameplay.notes.NoteSkin
local NoteSkin = {}

--- @type table<string, funkin.gameplay.notes.NoteSkin.NoteSkinData>
NoteSkin._cache = {} --- @protected

function NoteSkin.clearCache()
    
end

function NoteSkin.get(name)
    if not NoteSkin._cache[name] then
        local success, result = pcall(CoolUtil.parseJson, Paths.json(("game/notes/%s/config"):format(name)))
        if success then
            NoteSkin._cache[name] = result
        else
            FLog.warn(("Failed to load note skin config for %s: %s"):format(name, result))

            -- i would store the default skin in a cleaner way but i'm lazy
            -- so go my hardcoded json string!!
            NoteSkin._cache[name] = json.parse([[{"hold":{"scale":0.7,"animation":{"hold":{"right":{"fps":24,"offset":[0,0],"prefix":"right hold","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"up hold","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"down hold","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"left hold","looped":false}},"tail":{"right":{"fps":24,"offset":[0,0],"prefix":"right tail","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"up tail","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"down tail","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"left tail","looped":false}}},"atlas":{"path":"images/notes","type":"sparrow"}},"strum":{"scale":0.7,"animation":{"confirm":{"right":{"fps":24,"offset":[0,0],"prefix":"right confirm","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"up confirm","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"down confirm","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"left confirm","looped":false}},"static":{"right":{"fps":24,"offset":[0,0],"prefix":"right static","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"up static","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"down static","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"left static","looped":false}},"press":{"right":{"fps":24,"offset":[0,0],"prefix":"right press","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"up press","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"down press","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"left press","looped":false}}},"atlas":{"path":"images/notes","type":"sparrow"}},"holdCovers":{"scale":1,"offset":[12,-45],"animation":{"hold":{"right":{"fps":24,"offset":[0,0],"prefix":"right","looped":true},"up":{"fps":24,"offset":[0,0],"prefix":"up","looped":true},"down":{"fps":24,"offset":[0,0],"prefix":"down","looped":true},"left":{"fps":24,"offset":[0,0],"prefix":"left","looped":true}},"start":{"right":{"fps":24,"offset":[0,0],"prefix":"start right","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"start up","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"start down","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"start left","looped":false}},"end":{"right":{"fps":24,"offset":[0,0],"prefix":"end right","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"end up","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"end down","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"end left","looped":false}}},"atlas":{"path":"images/hold_covers","type":"sparrow"}},"splash":{"scale":1,"animation":{"splash1":{"right":{"fps":24,"offset":[0,0],"prefix":"note splash 1 right","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"note splash 1 up","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"note splash 1 down","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"note splash 1 left","looped":false}},"splash2":{"right":{"fps":24,"offset":[0,0],"prefix":"note splash 2 right","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"note splash 2 up","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"note splash 2 down","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"note splash 2 left","looped":false}}},"alpha":0.8,"atlas":{"path":"images/splashes","type":"sparrow"}},"holdGradients":{"scale":0.7825,"animation":{"gradient":{"right":{"fps":24,"offset":[0,0],"prefix":"gradient right","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"gradient up","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"gradient down","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"gradient left","looped":false}}},"atlas":{"path":"images/hold_covers","type":"sparrow"}},"note":{"scale":0.7,"animation":{"scroll":{"right":{"fps":24,"offset":[0,0],"prefix":"right scroll","looped":false},"up":{"fps":24,"offset":[0,0],"prefix":"up scroll","looped":false},"down":{"fps":24,"offset":[0,0],"prefix":"down scroll","looped":false},"left":{"fps":24,"offset":[0,0],"prefix":"left scroll","looped":false}}},"atlas":{"path":"images/notes","type":"sparrow"}}}]])
        end
    end
    return NoteSkin._cache[name]
end

return NoteSkin