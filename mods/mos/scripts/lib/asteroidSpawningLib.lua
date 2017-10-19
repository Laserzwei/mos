package.path = package.path .. ";data/scripts/lib/?.lua"
MOD = "[mOS]"                           -- do not change
VERSION = "[0.93] " 
SectorGenerator = require("SectorGenerator")
PlanGenerator = require ("plangenerator")
MAXDISPERSION = 5000            --  +-50km dispersion

--create the Asteroid description
function createAsteroidPlan(x, y)
    local desc = AsteroidDescriptor()
    desc:removeComponent(ComponentType.MineableMaterial)
    desc:addComponents(
       ComponentType.Owner,
       ComponentType.FactionNotifier
       )
    local generator = SectorGenerator(x, y)
    desc.position = generator:getPositionInSector()
    
    desc:setPlan(PlanGenerator.makeBigAsteroidPlan(100, 0, Material(0)))
    
    return desc
end
--create Asteroid and claim it
function spawnClaimedAsteroid(factionIndex, secX, secY, desc)

    local x,y,z = math.random(-MAXDISPERSION,MAXDISPERSION),math.random(-MAXDISPERSION,MAXDISPERSION),math.random(-MAXDISPERSION,MAXDISPERSION)               
    local vec = vec3(x,y,z) 

    asteroid = Sector():createEntity(desc)
    asteroid:moveBy(vec)
    asteroid.factionIndex = factionIndex
    asteroid:addScript("minefounder.lua")
    asteroid:addScript("sellobject.lua")
    asteroid:addScript("moveAsteroid.lua")
    --asteroid:invokeFunction("data/scripts/entity/moveAsteroid.lua", "registerAsteroid")       --activates the asteroid to straight jump again 
    
    --print(MOD..VERSION.."Asteroid created. Owner "..tostring(asteroid.factionIndex))
end
