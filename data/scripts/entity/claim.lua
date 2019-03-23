-- claimHook mod () required
local old_beforeEndingTheScript = beforeEndingTheScript
function beforeEndingTheScript(ok, msg, entity)
    old_beforeEndingTheScript(ok, msg, entity)
    entity:addScriptOnce("data/scripts/entity/moveAsteroid.lua")    --mOS
end
