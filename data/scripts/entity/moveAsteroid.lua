package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/mos/scripts/entity/?.lua"
require ("utility")

MOD = "[mOS]"
VERSION = "[0.95] "

function initialize()
    if onServer() then
        Entity():addScriptOnce("mods/mos/scripts/entity/moveAsteroid.lua")
        Entity():setValue("amMigrationFinished", 1)
    end
end

function update(timestep)
    if Entity():getValue("amMigrationFinished") then
        print(MOD..VERSION.."Migrated Entityscript.")
        Entity():setValue("amMigrationFinished", nil)
        terminate()
    end
end
