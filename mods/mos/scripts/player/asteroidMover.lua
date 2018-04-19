package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/mos/scripts/lib/?.lua"
require ("utility")
require ("mods/mos/scripts/lib/asteroidSpawningLib")
Placer = require("placer")

MOD = "[mOS]"                               -- do not change
VERSION = "[0.95b] "

MSSN = "isMarkedToMove"   --MoveStatuSaveName, gives the movestatus false,nil for not moving. true for needs to be moved

asteroidsToMove = {}                        --{[id]= factionIndex}

function initialize()
     if onServer() then
        Server():registerCallback("onPlayerLogOff", "onPlayerLogOff")
        onPlayerLogIn(Player().index)
     end
end

function onPlayerLogOff(playerIndex)
    if Player(playerIndex).name ~= Player().name then            --wrong player called
        return
    end
    local unregisterOnSectorLeftValue = Player(playerIndex):unregisterCallback("onSectorLeft", "mos_onSectorLeft")
    local unregisterOnSectorEnteredValue = Player(playerIndex):unregisterCallback("onSectorEntered", "mos_onSectorEntered")

    print(MOD..VERSION.."======mOS unloading Player "..Player(playerIndex).name.."======")
    print(MOD..VERSION.."Event unregisteration: "..tostring(unregisterOnSectorLeftValue).." | "..tostring(unregisterOnSectorEnteredValue))
end

function onPlayerLogIn(playerIndex)
    local player = Player(playerIndex)
    player:registerCallback("onSectorLeft", "mos_onSectorLeft")
    player:registerCallback("onSectorEntered", "mos_onSectorEntered")
end


--[[
Notice: The Table containing the asteroids to move is not saved to the harddrive.
If the server crashes in the time after the "onSectorLeft"-event was fired and before "onSectorEntered"
has been executed, then the asteroids will be lost.
]]
function mos_onSectorEntered(playerIndex, x, y)
    if Player().name ~= Player(playerIndex).name then return end
    if next(asteroidsToMove) == nil then return end
    local sec = appTimeMs()()
    spawnAsteroidsToMove(asteroidsToMove, playerIndex, x, y)
    asteroidsToMove = {}
    --print(MOD..VERSION.."Asteroid spawning needed "..(appTimeMs()()- sec).."ms")
    local sec = appTimeMs()()
    Placer.resolveIntersections()
    --print(MOD..VERSION.."Asteroid resolving needed "..(appTimeMs()()- sec).."ms")
end

function mos_onSectorLeft(playerIndex, x, y)
    asteroidsToMove = getAsteroidsToMove(playerIndex)
    --printTable(asteroidsToMove)
    destroyAsteroids(asteroidsToMove)
end

function getAsteroidsToMove(playerIndex)
    local astroList = {Sector():getEntitiesByScript("mods/mos/scripts/entity/moveAsteroid.lua")}
    local retList = {}
    local numasteroids = 0
    for _, asteroid in pairs(astroList) do
        if asteroid.factionIndex == playerIndex or asteroid.factionIndex == Player(playerIndex).allianceIndex then
            if asteroid:getValue(MSSN) == true then
                retList[asteroid.index] = asteroid.factionIndex
                numasteroids = numasteroids + 1
            end
        end
    end
    if numasteroids > 0 then
        --print(MOD..VERSION.."Spawning "..numasteroids.." Asteroids")
    end
    return retList
end

function destroyAsteroids(asteroidList)
    for id,toBeDestroyed in pairs(asteroidList) do
        Sector():deleteEntityJumped(Entity(id))
    end
end

function spawnAsteroidsToMove(asteroidList, playerIndex, x, y)
    local desc = createAsteroidPlan(x, y)
    local numasteroids = 0
    for id,factionIndex in pairs(asteroidList) do
        if factionIndex then
            spawnClaimedAsteroid(factionIndex, x, y, desc)
            numasteroids = numasteroids + 1
        end
    end
    print(MOD..VERSION.."Spawned "..numasteroids.." Asteroids" , x..":"..y)
end
