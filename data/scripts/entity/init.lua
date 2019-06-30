
if onServer() then

    local entity = Entity()
    if entity.isAsteroid then
        if entity:hasComponent(ComponentType.Owner) then
            if entity:hasScript("minefounder.lua") and entity:hasScript("sellobject.lua") then
                entity:addScriptOnce("entity/moveAsteroid.lua")
            end
        end
    end
end
