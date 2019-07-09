-- claimHook mod () required
local mos_old_beforeEndingTheScript = beforeEndingTheScript
function beforeEndingTheScript(ok, msg, entity)
    mos_old_beforeEndingTheScript(ok, msg, entity)
    entity:addScriptOnce("data/scripts/entity/moveAsteroid.lua")    --mOS
end
