package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

require ("utility")
require ("stringutility")
require ("faction")
local mOSConfig = require ("mods/mos/config/mos")

--test

MOD = "[mOS]"
VERSION = "[0.95] "
MSSN = "isMarkedToMove"   --MoveStatuSaveName, gives the movestatus false,nil for not moving. true for needs to be moved
local window
local payButton
local transferToAllianceButton
local permissions = {AlliancePrivilege.ManageStations, AlliancePrivilege.FoundStations, AlliancePrivilege.ModifyCrafts, AlliancePrivilege.SpendResources}
local uiInitialized

--is the player that tries to interact also the owner? Are we close enough? then return true.
function interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    local this = Entity()
    if checkEntityInteractionPermissions(this, permissions) then
        if this:getValue(MSSN) == nil then
            unregisterAsteroid()
        end

        local craft = player.craft
        if craft == nil then return false end

        local dist = craft:getNearestDistance(this)

        if dist < mOSConfig.CALLDISTANCE then
            prepUI()
            return true
        end
    end
    return false
end

function initUI()
    --print(MOD..VERSION.."UI start")
    local res = getResolution()
    local size = vec2(500, 300)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    if Entity():getValue(MSSN) then
        window.caption = "Configure Movement of " --.. Entity().index.value
    else
        window.caption = "Move Asteroid " --.. Entity().index.value
    end
    window.showCloseButton = 1
    window.moveable = 1
    window.closeableWithEscape = true

    window:createLabel(vec2(50, 10), "You will need "..createMonetaryString(mOSConfig.MONEY_PER_JUMP).."Cr to jump this Asteroid.", 15)
    --botton pay
    payButton = window:createButton(Rect(50, 200, 200, 30 + 200 ), "  Pay  ", "onPayPressed")
    if Entity():getValue(MSSN) then
        payButton.active = false
    end
    payButton.maxTextSize = 15

    --button abort
    local cancelBbutton = window:createButton(Rect(300, 200, 450, 30 + 200 ), " cancel Movement ", "onCancelPressed")
    cancelBbutton.maxTextSize = 15


    transferToAllianceButton = window:createButton(Rect(165, 150, 360, 30 + 150 ), " Transfer to Alliance ", "ontTransferPressed")
    transferToAllianceButton.maxTextSize = 15

    if Player().allianceIndex then
        if Player().index == Entity().factionIndex then
            transferToAllianceButton.caption = " Transfer to Alliance "
        elseif Player().allianceIndex == Entity().factionIndex then
            transferToAllianceButton.caption = " Transfer to You "
        end
        transferToAllianceButton.active = true
        transferToAllianceButton.visible = true
    else
        transferToAllianceButton.active = false
        transferToAllianceButton.visible = false
    end

    menu:registerWindow(window, "Move Asteroid")
    uiInitialized = true
end

function prepUI()
    if not uiInitialized then return end
    if Player().allianceIndex then
        transferToAllianceButton.active = true
        transferToAllianceButton.visible = true
    else
        transferToAllianceButton.active = false
        transferToAllianceButton.visible = false
    end
    if Entity():getValue(MSSN) == true then
        window.caption = "Configure Asteroid Movement " --.. Entity().index.value
        payButton.active = false
        payButton.tooltip = "Already payed"
    else
        window.caption = "Move Asteroid " --.. Entity().index.value
        payButton.active = true
        payButton.tooltip = "No refunds!"
    end
end

--playerIndex only available on Server
function onCancelPressed(playerIndex)
    if (onClient())then
        invokeServerFunction("onCancelPressed",Player().index)
        --print(MOD..VERSION.."Cancel Pressed ")
        window.visible = false
        return
    end
    unregisterAsteroid()

    --print(MOD..VERSION.."active Asteroid Movement cancelled on: ", Entity().index.value)
end

function onPayPressed()
    if (onClient())then
        invokeServerFunction("server_onPayPressed",Player().index)
        --print(MOD..VERSION.."Pay Pressed ")
        window.visible = false
        return
    else
        --print(MOD..VERSION.."Pay Pressed on Server")
    end

end

function server_onPayPressed(playerIndex)
    local player = Player(playerIndex)
    local owner = checkEntityInteractionPermissions(Entity(), permissions)
    if owner then
        local isMarkedToMove = Entity():getValue(MSSN)
        local canPay, msg, args = owner:canPay(mOSConfig.MONEY_PER_JUMP)

        if canPay and (isMarkedToMove == false or isMarkedToMove == nil) then
            owner:pay("",mOSConfig.MONEY_PER_JUMP)
            registerAsteroid()
            --print(MOD..VERSION..tostring(owner.name).." payed for Asteroid moving")
        else
            player:sendChatMessage("Asteroid", 1, msg,unpack(args))
            return
        end
    else
        --print(MOD..VERSION.."Pay pressed server answer by wrong player:".. Player().name .. " | from: " ..Player(playerIndex).name )
        return
    end
end

function ontTransferPressed()
    invokeServerFunction("server_ontTransferPressed", Player().index)
    if Player().index == Entity().factionIndex then
        transferToAllianceButton.caption = " Transfer to You "
    elseif Player().allianceIndex == Entity().factionIndex then
        transferToAllianceButton.caption = " Transfer to Alliance "
    end
    window.visible = false
end

function server_ontTransferPressed(playerIndex)
    if callingPlayer == playerIndex then
        if Player(callingPlayer).allianceIndex == Entity().factionIndex then
            print("transferred Asteroid ".. Entity().index.value .. " to Player" ..Player(callingPlayer).name)
            Entity().factionIndex = callingPlayer
        else
            print("transferred Asteroid ".. Entity().index.value .. " to Alliance " ..Alliance(Player(callingPlayer).allianceIndex).name)
            Entity().factionIndex = Player(callingPlayer).allianceIndex
        end
    end
end

function registerAsteroid()
    if onServer() then
        local scripts = Entity():getScripts()
        local minefounderRunning = false
        local sellobjectRunning = false
        for _,script in pairs(scripts) do
            if script == "data/scripts/entity/minefounder.lua" then
                minefounderRunning = true
            end
            if script == "data/scripts/entity/sellobject.lua" then
                sellobjectRunning = true
            end
        end
        if minefounderRunning == true then
            Entity():removeScript("data/scripts/entity/minefounder.lua")
        end
        if sellobjectRunning == true then
            Entity():removeScript("data/scripts/entity/sellobject.lua")
        end
        Entity():setValue(MSSN,true)
    end
end

function unregisterAsteroid()
    if onServer() then
        Entity():addScriptOnce("data/scripts/entity/minefounder.lua")
        Entity():addScriptOnce("data/scripts/entity/sellobject.lua")
        Entity():setValue(MSSN,false)
    end
end
