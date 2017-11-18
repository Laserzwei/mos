package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/mos/scripts/player/?.lua"
require ("utility")

MOD = "[mOS]"
VERSION = "[0.95b] "

function initialize()
    if onServer() then
        Player():addScriptOnce("mods/mos/scripts/player/asteroidMover.lua")
        print(MOD..VERSION.."Migrated Playerscript.")
    end
    terminate()
end
