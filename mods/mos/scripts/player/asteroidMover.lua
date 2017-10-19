package.path = package.path .. ";data/scripts/lib/?.lua"
require ("utility")
require ("asteroidSpawningLib")
Placer = require("placer")

MOD = "[mOS]"                               -- do not change
VERSION = "[0.93] "

MSSN = "isMarkedToMove"   --MoveStatuSaveName, gives the movestatus false,nil for not moving. true for needs to be moved

asteroidsToMove = {}                        --{[id]= bool}

function initialize()
     if onServer() then
        Server():registerCallback("onPlayerLogOff", "onPlayerLogOff")
     else
        invokeServerFunction("onPlayerLogIn", Player().index)
     end
end

function onPlayerLogOff(playerIndex)
    if Player(playerIndex).name ~= Player().name then            --wrong player called
        return
    end     
    local unregisterOnSectorLeftValue = Player(playerIndex):unregisterCallback("onSectorLeft", "onSectorLeft")
    local unregisterOnSectorEnteredValue = Player(playerIndex):unregisterCallback("onSectorEntered", "onSectorEntered")
    
    print(MOD..VERSION.."======mOS unloading Player "..Player(playerIndex).name.."======") 
    print(MOD..VERSION.."Event unregisteration: "..tostring(unregisterOnSectorLeftValue).." | "..tostring(unregisterOnSectorEnteredValue))
end

function onPlayerLogIn(playerIndex)
    local player = Player(playerIndex)
    player:registerCallback("onSectorLeft", "onSectorLeft")
    player:registerCallback("onSectorEntered", "onSectorEntered")
end

function onSectorEntered(playerIndex, x, y)
    if Player().name ~= Player(playerIndex).name then return end
    if next(asteroidsToMove) == nil then return end
    local sec = systemTimeMs()
    spawnAsteroidsToMove(asteroidsToMove, playerIndex, x, y)
    asteroidsToMove = {}
    print(MOD..VERSION.."Asteroid spawning needed "..(systemTimeMs()- sec).."ms")
    local sec = systemTimeMs()
    Placer.resolveIntersections()
    print(MOD..VERSION.."Asteroid resolving needed "..(systemTimeMs()- sec).."ms")
end

function onSectorLeft(playerIndex, x, y)
    asteroidsToMove = getAsteroidsToMove(playerIndex)
    --printTable(asteroidsToMove)
    destroyAsteroids(asteroidsToMove)
end

function getAsteroidsToMove(playerIndex)
    local astroList = {Sector():getEntitiesByScript("data/scripts/entity/moveAsteroid.lua")}
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
        print(MOD..VERSION.."Spawning "..numasteroids.." Asteroids")
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