package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"
package.path = package.path .. ";data/config/?.lua"

include ("utility")
include ("stringutility")
include ("faction")
include ("callable")

local config = include("data/config/mos")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace mOS
mOS = {}

local selectedSector = {}


local window
local selectSectorButton
local payButton
local transferToAllianceButton
local permissions = {AlliancePrivilege.ManageStations, AlliancePrivilege.FoundStations, AlliancePrivilege.ModifyCrafts, AlliancePrivilege.SpendResources}
local uiInitialized

local stateMessageMap = {
    [0] = "",
    [-1] = "No sector selected!",
    [-2] = "Can't transfer to sector \\s(%i:%i)",
    [-3] = "Can't transfer to sector \\s(%i:%i)",
    [-4] = "Asteroid is already in sector \\s(%i:%i) !"}

function mOS.initialize()
    Entity():registerCallback("onSectorEntered", "onSectorEntered")
end

function mOS.onShowWindow()
    Player():registerCallback("onSelectMapCoordinates", "onSelectMapCoordinates")
end

function mOS.onCloseWindow()
    Player():unregisterCallback("onSelectMapCoordinates", "onSelectMapCoordinates")
end

--is the player that tries to interact also the owner? Are we close enough? then return true.
function mOS.interactionPossible(playerIndex)
    local player = Player(playerIndex)
    local astro = Entity()
    local craft = player.craft
    if craft == nil then return false end
    local dist = craft:getNearestDistance(astro)
    if dist < config.CALLDISTANCE then
        if checkEntityInteractionPermissions(astro, permissions) then
            return true
        end
    end
    return false
end

function mOS.initUI()
    local res = getResolution()
    local size = vec2(500, 300)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.showCloseButton = 1
    window.moveable = 1
    window.closeableWithEscape = true
    window:createLabel(vec2(50, 10), string.format("You will need %sCr to jump this Asteroid."%_t, createMonetaryString(config.MONEY_PER_JUMP)), 15)
    --botton pay
    payButton = window:createButton(Rect(300, 200, 450, 30 + 200 ), "Pay & Move"%_t, "onPayPressed")
    payButton.maxTextSize = 15

    --button abort
    selectSectorButton = window:createButton(Rect(50, 200, 200, 30 + 200 ), "Select Sector"%_t, "onSectorSelectionPressed")
    selectSectorButton.maxTextSize = 15


    transferToAllianceButton = window:createButton(Rect(165, 150, 360, 30 + 150 ), "Transfer to Alliance "%_t, "onTransferOwnershipPressed")
    transferToAllianceButton.maxTextSize = 15

    if Player().allianceIndex then
        if Player().index == Entity().factionIndex then
            transferToAllianceButton.caption = "Transfer to Alliance "%_t
        elseif Player().allianceIndex == Entity().factionIndex then
            transferToAllianceButton.caption = "Transfer Ownership to You "%_t
        end
        transferToAllianceButton.active = true
        transferToAllianceButton.visible = true
    else
        transferToAllianceButton.active = false
        transferToAllianceButton.visible = false
    end

    menu:registerWindow(window, "Move Asteroid"%_t)
    uiInitialized = true
end

function mOS.onSelectMapCoordinates(x, y)
    if uiInitialized then
        local state = mOS.validTransferCoordinates(x, y)
        if state == 0 then
            selectedSector.x, selectedSector.y = x, y
            selectSectorButton.tooltip = string.format("Selected Sector: (%i:%i)"%_t, selectedSector.x, selectedSector.y)
        elseif state > -4 then
            displayChatMessage(string.format(stateMessageMap[state]%_t, x, y), "Asteroid", 0)
            displayChatMessage(string.format(stateMessageMap[state]%_t, x, y), "Asteroid", 1)
        elseif state == -4 then
            selectedSector.x, selectedSector.y = x, y -- the later serverside check, needs this to display the error
        end
    end
end

-- changing position in target sector
function mOS.onSectorEntered()
    local x,y,z = math.random(-config.MAXDISPERSION, config.MAXDISPERSION), math.random(-config.MAXDISPERSION, config.MAXDISPERSION), math.random(-config.MAXDISPERSION, config.MAXDISPERSION)
    Entity().translation = dvec3(x,y,z)
end

function mOS.onSectorSelectionPressed()
    if onClient()then
        if selectedSector.x and selectedSector.y then
            GalaxyMap():show(selectedSector.x, selectedSector.y)
        else
            GalaxyMap():show(Sector():getCoordinates())
        end
    end
end

function mOS.onPayPressed()
    if onClient()then
        if selectedSector.x and selectedSector.y then
            invokeServerFunction("server_onPayPressed",selectedSector)
            window.visible = false
        else
            displayChatMessage("No sector selected!"%_t, "Asteroid", 1)
        end
    end
end

function mOS.server_onPayPressed(pSelectedSector)
    if not pSelectedSector then print("[mOS] invalid sectordata send") return end
    selectedSector = pSelectedSector
    local player = Player(callingPlayer)
    local owner = checkEntityInteractionPermissions(Entity(), permissions)
    if owner then
        local canPay, msg, args = owner:canPay(config.MONEY_PER_JUMP)
        if canPay then
            local state = mOS.validTransferCoordinates(selectedSector.x, selectedSector.y)
            if state == 0 then
                if player.craft.hyperspaceJumpReach >= distance(vec2(Sector():getCoordinates()), vec2(selectedSector.x, selectedSector.y)) then
                    owner:pay("",config.MONEY_PER_JUMP)
                    player.craft.hyperspaceCooldown = player.craft.hyperspaceCooldown + 30
                    Galaxy():transferEntity(Entity(), selectedSector.x, selectedSector.y, 1)
                    player:sendChatMessage("Asteroid", 0, "Asteroid has been transferred to sector \\s(%i:%i) !"%_t, selectedSector.x, selectedSector.y)
                else
                    player:sendChatMessage("Asteroid", ChatMessageType.Error, "Target Sector too far away!"%_t)
                end
            else
                local message = string.format(stateMessageMap[state]%_t, selectedSector.x, selectedSector.y)
                player:sendChatMessage("Asteroid", ChatMessageType.Error, message)
                player:sendChatMessage("Asteroid", ChatMessageType.Normal, message)
            end
        else
            player:sendChatMessage("Asteroid", 1, msg,unpack(args))
            return
        end
    else
        return
    end
end
callable(mOS, "server_onPayPressed")

function mOS.onTransferOwnershipPressed()
    invokeServerFunction("server_onTransferOwnershipPressed")
    if Player().index == Entity().factionIndex then
        transferToAllianceButton.caption = "Transfer Ownership to You "%_t
    elseif Player().allianceIndex == Entity().factionIndex then
        transferToAllianceButton.caption = "Transfer to Alliance "%_t
    end
    window.visible = false
end

function mOS.server_onTransferOwnershipPressed()
    if Player(callingPlayer).allianceIndex == Entity().factionIndex then
        printlog("transferred Asteroid ".. Entity().index.value .. " to Player" ..Player(callingPlayer).name)
        Entity().factionIndex = callingPlayer
    else
        printlog("transferred Asteroid ".. Entity().index.value .. " to Alliance " ..Alliance(Player(callingPlayer).allianceIndex).name)
        Entity().factionIndex = Player(callingPlayer).allianceIndex
    end
end
callable(mOS, "server_onTransferOwnershipPressed")

-- Checks for ill-logic sectors. Does not check for range restrictions
-- 0 is valid
-- <0 is invalid
function mOS.validTransferCoordinates(x, y)
    local sX, sY = Sector():getCoordinates()
    if not x or not y then
        return -1
    end
    if x > 500 or x < -500 or y > 500 or y < -500 then
        return -2
    end
    if (x == 0 and y == 0) then
        return -3
    end
    if (x == sX and y == sY) then
        return -4
    end
    return 0
end
