package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/mos/scripts/entity/?.lua"

MOD = "[mOS]"                           -- do not change
VERSION = "[0.95b] "
SectorGenerator = require("SectorGenerator")
PlanGenerator = require ("plangenerator")
local mOSConfig = require ("mods/mos/config/mos")

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

    local x,y,z = math.random(-mOSConfig.MAXDISPERSION,mOSConfig.MAXDISPERSION),math.random(-mOSConfig.MAXDISPERSION,mOSConfig.MAXDISPERSION),math.random(-mOSConfig.MAXDISPERSION,mOSConfig.MAXDISPERSION)
    local vec = vec3(x,y,z)

    asteroid = Sector():createEntity(desc)
    asteroid:moveBy(vec)
    asteroid.factionIndex = factionIndex
    asteroid:addScriptOnce("minefounder.lua")
    asteroid:addScriptOnce("sellobject.lua")
    asteroid:addScriptOnce("mods/mos/scripts/entity/moveAsteroid.lua")
    --asteroid:invokeFunction("mods/mos/scripts/entity/moveAsteroid.lua", "registerAsteroid")       --activates the asteroid to straight jump again

    --print(MOD..VERSION.."Asteroid created. Owner "..tostring(asteroid.factionIndex))
end
