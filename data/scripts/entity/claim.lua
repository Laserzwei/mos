-- Overwrite vanilla claim()
function claim()
    local ok, msg = interactionPossible(callingPlayer)
    if not ok then

        if msg then
            local player = Player(callingPlayer)
            if player then
                player:sendChatMessage("", 1, msg)
            end
        end

        return
    end

    local faction, ship, player = getInteractingFaction(callingPlayer)
    if not faction then return end

    local entity = Entity()
    entity.factionIndex = faction.index
    entity:addScriptOnce("minefounder.lua")
    entity:addScriptOnce("sellobject.lua")
    entity:addScriptOnce("data/scripts/entity/moveAsteroid.lua")    --mOS
    terminate()
end
